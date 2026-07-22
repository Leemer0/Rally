import CoreLocation
import Foundation

enum LocationVerificationError: LocalizedError, Equatable {
    case servicesDisabled
    case permissionDenied
    case locationUnavailable
    case staleLocation
    case insufficientAccuracy
    case requestInProgress

    var errorDescription: String? {
        switch self {
        case .servicesDisabled:
            "Location Services are turned off. Turn them on and try again."
        case .permissionDenied:
            "Location access is off. Allow access in Settings, then try again."
        case .locationUnavailable:
            "We couldn’t get your current location. Move near an open area and try again."
        case .staleLocation:
            "Your location is out of date. Wait a moment and try again."
        case .insufficientAccuracy:
            "Your location isn’t accurate enough yet. Wait a moment and try again."
        case .requestInProgress:
            "A location check is already in progress."
        }
    }
}

struct VenueLocationEvidence: Codable, Hashable, Sendable {
    let latitude: Double
    let longitude: Double
    let horizontalAccuracyMetres: Double
    let capturedAt: Date
    let accuracyAuthorization: String
    let locationAuthorization: String
}

enum VenueGeofence {
    /// A small arrival radius that tolerates indoor GPS drift without covering a full neighbourhood.
    static let radius: CLLocationDistance = 75
    static let maximumAcceptedAccuracy: CLLocationAccuracy = 75
    static let maximumLocationAge: TimeInterval = 30

    /// Prevents an effectively tied coordinate from being accepted for either nearby venue.
    private static let nearestVenueTieTolerance: CLLocationDistance = 1

    static func contains(_ location: CLLocation, venue: Venue) -> Bool {
        contains(location, venue: venue, among: VenueCatalog.venues)
    }

    static func contains(_ location: CLLocation, venue: Venue, among venues: [Venue]) -> Bool {
        let venueLocation = CLLocation(latitude: venue.latitude, longitude: venue.longitude)
        let requestedVenueDistance = location.distance(from: venueLocation)

        guard requestedVenueDistance <= radius else { return false }

        let nearestCompetingDistance = venues.lazy
            .filter { $0.id != venue.id }
            .map { candidate in
                location.distance(from: CLLocation(
                    latitude: candidate.latitude,
                    longitude: candidate.longitude
                ))
            }
            .min()

        guard let nearestCompetingDistance else { return true }
        return requestedVenueDistance + nearestVenueTieTolerance < nearestCompetingDistance
    }

    static func isFresh(_ location: CLLocation, now: Date = Date()) -> Bool {
        let age = now.timeIntervalSince(location.timestamp)
        return age >= 0 && age <= maximumLocationAge
    }
}

@MainActor
final class VenueLocationVerifier: NSObject, @preconcurrency CLLocationManagerDelegate {
    static let shared = VenueLocationVerifier()

    private let manager: CLLocationManager
    private var continuation: CheckedContinuation<CLLocation, Error>?

    private override init() {
        manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .other
    }

    func verify(_ venue: Venue) async throws -> Bool {
        let location = try await validatedCurrentLocation()

        return VenueGeofence.contains(location, venue: venue)
    }

    /// Captures precise, fresh evidence for the server. The device never decides
    /// whether a check-in is valid in production; PostGIS and the venue's current
    /// geofence remain authoritative.
    func captureEvidence() async throws -> VenueLocationEvidence {
        let location = try await validatedCurrentLocation()

        return VenueLocationEvidence(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            horizontalAccuracyMetres: location.horizontalAccuracy,
            capturedAt: location.timestamp,
            accuracyAuthorization: accuracyAuthorizationValue,
            locationAuthorization: locationAuthorizationValue
        )
    }

    private func validatedCurrentLocation() async throws -> CLLocation {
        let location = try await requestCurrentLocation()

        guard VenueGeofence.isFresh(location) else {
            throw LocationVerificationError.staleLocation
        }

        guard manager.accuracyAuthorization == .fullAccuracy else {
            throw LocationVerificationError.insufficientAccuracy
        }

        guard location.horizontalAccuracy >= 0,
              location.horizontalAccuracy <= VenueGeofence.maximumAcceptedAccuracy
        else {
            throw LocationVerificationError.insufficientAccuracy
        }

        return location
    }

    private var accuracyAuthorizationValue: String {
        switch manager.accuracyAuthorization {
        case .fullAccuracy: "full"
        case .reducedAccuracy: "reduced"
        @unknown default: "unknown"
        }
    }

    private var locationAuthorizationValue: String {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse: "when_in_use"
        case .authorizedAlways: "always"
        case .denied: "denied"
        case .restricted: "restricted"
        case .notDetermined: "not_determined"
        @unknown default: "unknown"
        }
    }

    private func requestCurrentLocation() async throws -> CLLocation {
        guard CLLocationManager.locationServicesEnabled() else {
            throw LocationVerificationError.servicesDisabled
        }

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                guard !Task.isCancelled else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                guard self.continuation == nil else {
                    continuation.resume(throwing: LocationVerificationError.requestInProgress)
                    return
                }

                self.continuation = continuation

                switch manager.authorizationStatus {
                case .authorizedAlways, .authorizedWhenInUse:
                    manager.requestLocation()
                case .notDetermined:
                    manager.requestWhenInUseAuthorization()
                case .denied, .restricted:
                    finish(with: .failure(LocationVerificationError.permissionDenied))
                @unknown default:
                    finish(with: .failure(LocationVerificationError.locationUnavailable))
                }
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                self?.finish(with: .failure(CancellationError()))
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard continuation != nil else { return }

        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            finish(with: .failure(LocationVerificationError.permissionDenied))
        case .notDetermined:
            break
        @unknown default:
            finish(with: .failure(LocationVerificationError.locationUnavailable))
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            finish(with: .failure(LocationVerificationError.locationUnavailable))
            return
        }

        finish(with: .success(location))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(with: .failure(LocationVerificationError.locationUnavailable))
    }

    private func finish(with result: Result<CLLocation, Error>) {
        guard let continuation else { return }
        self.continuation = nil
        continuation.resume(with: result)
    }
}
