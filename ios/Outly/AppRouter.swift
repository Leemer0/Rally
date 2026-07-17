import Observation
import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case explore
    case list
    case profile

    var id: Self { self }

    var title: String {
        switch self {
        case .explore: "Explore"
        case .list: "Venues"
        case .profile: "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .explore: "safari"
        case .list: "list.bullet.rectangle"
        case .profile: "person.crop.circle"
        }
    }
}

enum AppRoute: Hashable {
    case venueDetail(String)
    case rsvpReview(String)
    case rsvpSuccess(String)
    case checkInIntro(String)
    case offer(String)
}

enum InfoPage: String, Identifiable {
    case privacy
    case support
    case about

    var id: Self { self }

    var title: String {
        switch self {
        case .privacy: "Privacy"
        case .support: "Help"
        case .about: "About"
        }
    }
}

enum SheetDestination: Identifiable {
    case venueSearch
    case venueFilters
    case settings
    case info(InfoPage)

    var id: String {
        switch self {
        case .venueSearch: "venue-search"
        case .venueFilters: "venue-filters"
        case .settings: "settings"
        case let .info(page): "info-\(page.rawValue)"
        }
    }
}

struct VenueFilters: Equatable {
    var neighbourhood: String?
    var hasOffer = false

    func includes(_ venue: Venue) -> Bool {
        if let neighbourhood, venue.neighbourhood != neighbourhood { return false }
        if hasOffer, venue.offer == nil { return false }
        return true
    }
}

@MainActor
@Observable
final class AppRouter {
    var selectedTab: AppTab = .explore
    var explorePath: [AppRoute] = []
    var listPath: [AppRoute] = []
    var profilePath: [AppRoute] = []
    var presentedSheet: SheetDestination?
    var filters = VenueFilters()

    func binding(for tab: AppTab) -> Binding<[AppRoute]> {
        Binding(
            get: { self.path(for: tab) },
            set: { self.setPath($0, for: tab) }
        )
    }

    func navigate(to route: AppRoute) {
        switch selectedTab {
        case .explore: explorePath.append(route)
        case .list: listPath.append(route)
        case .profile: profilePath.append(route)
        }
    }

    func replaceCurrent(with route: AppRoute) {
        switch selectedTab {
        case .explore where !explorePath.isEmpty: explorePath[explorePath.count - 1] = route
        case .list where !listPath.isEmpty: listPath[listPath.count - 1] = route
        case .profile where !profilePath.isEmpty: profilePath[profilePath.count - 1] = route
        default: navigate(to: route)
        }
    }

    func pop() {
        switch selectedTab {
        case .explore where !explorePath.isEmpty: explorePath.removeLast()
        case .list where !listPath.isEmpty: listPath.removeLast()
        case .profile where !profilePath.isEmpty: profilePath.removeLast()
        default: break
        }
    }

    func showVenue(_ venueID: String, on tab: AppTab? = nil) {
        if let tab { selectedTab = tab }
        setPath([.venueDetail(venueID)], for: selectedTab)
    }

    func returnToExplore() {
        explorePath = []
        listPath = []
        profilePath = []
        selectedTab = .explore
    }

    func reset() {
        selectedTab = .explore
        explorePath = []
        listPath = []
        profilePath = []
        presentedSheet = nil
        filters = VenueFilters()
    }

    private func path(for tab: AppTab) -> [AppRoute] {
        switch tab {
        case .explore: explorePath
        case .list: listPath
        case .profile: profilePath
        }
    }

    private func setPath(_ path: [AppRoute], for tab: AppTab) {
        switch tab {
        case .explore: explorePath = path
        case .list: listPath = path
        case .profile: profilePath = path
        }
    }
}
