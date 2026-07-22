import MapboxMaps
import SwiftUI

@main
@MainActor
struct OutlyApp: App {
    @State private var store: DemoStore
    @State private var router: AppRouter
    @State private var theme = OutlyTheme()
    private let services: AppServices

    init() {
        if let tokenURL = Bundle.main.url(forResource: "MapboxAccessToken", withExtension: "txt"),
           let token = try? String(contentsOf: tokenURL, encoding: .utf8),
           token.hasPrefix("pk.")
        {
            MapboxOptions.accessToken = token
        }

        let arguments = ProcessInfo.processInfo.arguments
        let reset = arguments.contains("--reset-demo")
        if reset {
            Task { await CheckInLiveActivityManager.shared.endAll() }
        }
        let initialRouter = AppRouter()
        var screenshotState: DemoState?
        var screenshotAuthIntent: AuthIntent?
#if DEBUG
        services = arguments.contains("--use-demo-services") ? .demo : .live
#else
        services = .live
#endif
#if DEBUG
        if let screenArgument = arguments.first(where: { $0.hasPrefix("--screen=") }) {
            let screen = String(screenArgument.dropFirst("--screen=".count))
            var state = DemoState(onboardingStage: .main)
            state.profile.firstName = "Liam"

            let plan = NightPlan(
                venueID: "track-field",
                dateLabel: "Tonight"
            )
            let now = Date()
            let activeOffer = TimedOfferWindow(unlockedAt: now)
            let activePartnerOffer = TimedOfferWindow(unlockedAt: now, duration: 30 * 60)
            let activeOpenOffer = TimedOfferWindow(unlockedAt: now, duration: nil)
            let expiredOffer = TimedOfferWindow(unlockedAt: now.addingTimeInterval(-TimedOfferWindow.duration - 1))

            switch screen {
            case "welcome": state.onboardingStage = .welcome
            case "auth": state.onboardingStage = .auth
            case "auth-login":
                state.onboardingStage = .auth
                screenshotAuthIntent = .logIn
            case "onboarding-name":
                state.onboardingStage = .name
                state.profile.firstName = ""
            case "onboarding-age": state.onboardingStage = .age
            case "onboarding-complete": state.onboardingStage = .complete
            case "explore": break
            case "explore-partner":
                state.selectedVenueID = "lavelle"
            case "explore-offer":
                state.plan = plan
                state.checkedInVenueID = "track-field"
                state.offerWindows["track-field"] = activeOffer
                state.claimedOffers["track-field"] = VenueCatalog.venue(id: "track-field").offer
            case "venues": initialRouter.selectedTab = .list
            case "profile":
                initialRouter.selectedTab = .profile
                state.plan = plan
                state.checkedInVenueID = "track-field"
                state.offerWindows["track-field"] = activeOffer
                state.claimedOffers["track-field"] = VenueCatalog.venue(id: "track-field").offer
            case "venue-detail": initialRouter.explorePath = [.venueDetail("track-field")]
            case "venue-detail-partner": initialRouter.explorePath = [.venueDetail("lavelle")]
            case "venue-detail-checked-in":
                state.plan = plan
                state.checkedInVenueID = "track-field"
                state.offerWindows["track-field"] = activeOffer
                state.claimedOffers["track-field"] = VenueCatalog.venue(id: "track-field").offer
                initialRouter.explorePath = [.venueDetail("track-field")]
            case "rsvp-review": initialRouter.explorePath = [.rsvpReview("track-field")]
            case "rsvp-success":
                state.plan = plan
                initialRouter.explorePath = [.rsvpSuccess("track-field")]
            case "checkin-intro", "checkin-verifying", "checkin-confirmed", "checkin-failed":
                initialRouter.explorePath = [.checkInIntro("track-field")]
            case "offer":
                state.checkedInVenueID = "track-field"
                state.offerWindows["track-field"] = activeOffer
                state.claimedOffers["track-field"] = VenueCatalog.venue(id: "track-field").offer
                initialRouter.explorePath = [.offer("track-field")]
            case "offer-partner":
                state.selectedVenueID = "lavelle"
                state.checkedInVenueID = "lavelle"
                state.offerWindows["lavelle"] = activePartnerOffer
                state.claimedOffers["lavelle"] = VenueCatalog.venue(id: "lavelle").offer
                initialRouter.explorePath = [.offer("lavelle")]
            case "offer-open":
                state.selectedVenueID = "paris-texas"
                state.checkedInVenueID = "paris-texas"
                state.offerWindows["paris-texas"] = activeOpenOffer
                state.claimedOffers["paris-texas"] = VenueCatalog.venue(id: "paris-texas").offer
                initialRouter.explorePath = [.offer("paris-texas")]
            case "offer-expired":
                state.checkedInVenueID = "track-field"
                state.offerWindows["track-field"] = expiredOffer
                initialRouter.explorePath = [.offer("track-field")]
            case "search": initialRouter.presentedSheet = .venueSearch
            case "filters": initialRouter.presentedSheet = .venueFilters
            case "settings": initialRouter.presentedSheet = .settings
            case "privacy": initialRouter.presentedSheet = .info(.privacy)
            case "support": initialRouter.presentedSheet = .info(.support)
            case "about": initialRouter.presentedSheet = .info(.about)
            default: break
            }

            if state.checkedInVenueID != nil, state.checkedInAt == nil {
                state.checkedInAt = now
            }

            screenshotState = state
        }

        if arguments.contains("--tab-venues") { initialRouter.selectedTab = .list }
        if arguments.contains("--tab-profile") { initialRouter.selectedTab = .profile }
        if arguments.contains("--auto-partner-checkin") {
            screenshotState = DemoState(onboardingStage: .main)
            initialRouter.explorePath = [.checkInIntro("lavelle")]
        }
        if arguments.contains("--route-venue") {
            initialRouter.explorePath = [.venueDetail("track-field")]
        }
        if arguments.contains("--route-checkin") {
            initialRouter.explorePath = [.checkInIntro("track-field")]
        }
        if arguments.contains("--route-partner-checkin") {
            initialRouter.explorePath = [.checkInIntro("lavelle")]
        }
#endif
#if DEBUG
        if let screenshotState {
            let previewStore = DemoStore(previewState: screenshotState)
            if let screenshotAuthIntent {
                previewStore.authIntent = screenshotAuthIntent
            }
            _store = State(initialValue: previewStore)
        } else if arguments.contains("--main-demo") {
            var demoState = DemoState(onboardingStage: .main)
            demoState.profile.firstName = "Liam"
            _store = State(initialValue: DemoStore(previewState: demoState))
        } else {
            _store = State(initialValue: DemoStore(
                resetOnLaunch: reset,
                allowsFixtures: services.isDemo
            ))
        }
#else
        _store = State(initialValue: DemoStore(
            resetOnLaunch: reset,
            allowsFixtures: false
        ))
#endif
        _router = State(initialValue: initialRouter)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(router)
                .environment(theme)
                .environment(\.appServices, services)
                .tint(theme.accent)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @Environment(DemoStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(OutlyTheme.self) private var theme
    @Environment(\.appServices) private var services
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isRestoringSession = true
    @State private var restoreGeneration = 0
    @State private var startupError: String?

    var body: some View {
        Group {
            if !services.isDemo, isRestoringSession {
                ZStack {
                    theme.background.ignoresSafeArea()
                    ProgressView()
                        .tint(theme.primaryText)
                        .accessibilityLabel("Loading Outly")
                }
            } else if !services.isDemo, let startupError {
                ContentUnavailableView {
                    Label("Couldn’t load Outly", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(startupError)
                } actions: {
                    Button("Try again") {
                        restoreGeneration += 1
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Log out") {
                        Task { await signOutAfterStartupFailure() }
                    }
                    .buttonStyle(.bordered)
                }
                .foregroundStyle(theme.primaryText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(theme.background)
            } else if store.state.onboardingStage == .main {
                MainAppView()
            } else {
                OnboardingFlowView()
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.28), value: store.state.onboardingStage)
        .task(id: restoreGeneration) {
            await restoreSessionIfNeeded()
        }
        .onOpenURL { url in
            guard !services.isDemo else { return }
            Task {
                do {
                    try await services.handleAuthCallback(url)
                    restoreGeneration += 1
                } catch {
                    startupError = Self.message(for: error)
                    isRestoringSession = false
                }
            }
        }
    }

    @MainActor
    private func restoreSessionIfNeeded() async {
        guard !services.isDemo else {
            isRestoringSession = false
            return
        }

        isRestoringSession = true
        startupError = nil

        guard await services.currentUserID() != nil else {
            store.signOutLocally()
            router.reset()
            isRestoringSession = false
            return
        }

        do {
            store.applyConsumerBootstrap(try await services.loadConsumerBootstrap())
        } catch let error as SupabaseBackendError {
            if case let .server(code, _, _) = error, code == "ONBOARDING_REQUIRED" {
                // A new authenticated user has no consumer profile until the
                // protected DOB/gender onboarding RPC succeeds.
                store.go(to: .name)
            } else {
                startupError = Self.message(for: error)
            }
        } catch {
            startupError = Self.message(for: error)
        }

        isRestoringSession = false
    }

    @MainActor
    private func signOutAfterStartupFailure() async {
        try? await services.signOut()
        store.signOutLocally()
        router.reset()
        startupError = nil
        isRestoringSession = false
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription
            ?? "Check your connection and try again."
    }
}

#Preview("First launch") {
    RootView()
        .environment(DemoStore(previewState: DemoState()))
        .environment(AppRouter())
        .environment(OutlyTheme())
        .environment(\.appServices, .demo)
        .preferredColorScheme(.dark)
}
