import MapboxMaps
import SwiftUI

struct OutlyMapView: View {
    @Environment(OutlyTheme.self) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let venues: [Venue]
    let selectedVenueID: Venue.ID?
    let onSelectVenue: (Venue.ID) -> Void
    let onTapBackground: () -> Void

    private let initialViewport = Viewport.camera(
        center: CLLocationCoordinate2D(latitude: 43.6490, longitude: -79.4095),
        zoom: 12.2,
        bearing: 0,
        pitch: 40
    )

    private let westTorontoBounds = CameraBoundsOptions(
        bounds: CoordinateBounds(
            southwest: CLLocationCoordinate2D(latitude: 43.6255, longitude: -79.4480),
            northeast: CLLocationCoordinate2D(latitude: 43.6750, longitude: -79.3720)
        ),
        maxZoom: 17.4,
        minZoom: 12.0,
        maxPitch: 58,
        minPitch: 30
    )

    private var previewOverlayHeight: CGFloat {
        selectedVenueID == nil ? 0 : 238
    }

    private var ornamentBottomMargin: CGFloat {
        previewOverlayHeight + (dynamicTypeSize.isAccessibilitySize ? 118 : 2)
    }

    var body: some View {
        Map(initialViewport: initialViewport) {
            ForEvery(venues, id: \.id) { venue in
                let markerAnchor = VenueMarkerAnchor.forVenue(venue.id)
                MapViewAnnotation(coordinate: venue.coordinate) {
                    VenueMarker(
                        venue: venue,
                        selected: selectedVenueID == venue.id,
                        coordinateAnchor: markerAnchor,
                        action: { onSelectVenue(venue.id) }
                    )
                    .environment(theme)
                }
                .allowOverlap(true)
                .variableAnchors([ViewAnnotationAnchorConfig(anchor: markerAnchor.mapboxAnchor)])
                .priority(selectedVenueID == venue.id ? 10 : 0)
            }

            TapInteraction { _ in
                onTapBackground()
                return true
            }
        }
        .mapStyle(
            .standard(
                theme: .default,
                lightPreset: .night,
                showPointOfInterestLabels: false,
                showTransitLabels: false,
                showPlaceLabels: false,
                showRoadLabels: true,
                showPedestrianRoads: false,
                show3dObjects: true,
                colorBuildings: StyleColor(UIColor(red: 0.14, green: 0.16, blue: 0.31, alpha: 1)),
                colorGreenspace: StyleColor(UIColor(red: 0.07, green: 0.20, blue: 0.17, alpha: 1)),
                colorLand: StyleColor(UIColor(red: 0.045, green: 0.065, blue: 0.15, alpha: 1)),
                colorMotorways: StyleColor(UIColor(red: 0.35, green: 0.29, blue: 0.57, alpha: 1)),
                colorRoadLabels: StyleColor(UIColor(white: 0.78, alpha: 1)),
                colorRoads: StyleColor(UIColor(red: 0.23, green: 0.24, blue: 0.43, alpha: 1)),
                colorTrunks: StyleColor(UIColor(red: 0.38, green: 0.30, blue: 0.59, alpha: 1)),
                colorWater: StyleColor(UIColor(red: 0.025, green: 0.055, blue: 0.12, alpha: 1)),
                roadsBrightness: 0.44,
                show3dBuildings: true,
                show3dLandmarks: true,
                show3dTrees: false,
                showAdminBoundaries: false,
                showIndoor: false,
                showIndoorLabels: false,
                showLandmarkIconLabels: false,
                showLandmarkIcons: false
            )
        )
        .cameraBounds(westTorontoBounds)
        .ornamentOptions(.init(
            scaleBar: .init(visibility: .hidden),
            compass: .init(visibility: .hidden),
            logo: .init(
                position: .bottomLeading,
                margins: CGPoint(x: 6, y: ornamentBottomMargin)
            ),
            attributionButton: .init(
                position: .bottomTrailing,
                margins: CGPoint(x: 10, y: ornamentBottomMargin),
                tintColor: UIColor(white: 0.86, alpha: 0.62)
            )
        ))
        .accessibilityLabel("Map of nightlife venues in west Toronto")
    }
}

private extension VenueMarkerAnchor {
    var mapboxAnchor: ViewAnnotationAnchor {
        switch self {
        case .bottomLeft: .bottomLeft
        case .bottomRight: .bottomRight
        case .topRight: .topRight
        case .center: .center
        }
    }
}
