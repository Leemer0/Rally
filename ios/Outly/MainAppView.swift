import SwiftUI

struct MainAppView: View {
    @Environment(DemoStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(OutlyTheme.self) private var theme

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            tab(.explore) { ExploreView() }
            tab(.list) { VenueListView() }
            tab(.profile) { ProfileView() }
        }
        .onChange(of: router.selectedTab) { _, _ in
            HapticManager.shared.selected(enabled: store.state.hapticsEnabled)
        }
        .sheet(item: $router.presentedSheet) { destination in
            switch destination {
            case .venueSearch:
                VenueSearchSheet()
            case .venueFilters:
                VenueFilterSheet()
            case .settings:
                SettingsSheet()
            case let .info(page):
                InfoSheet(page: page)
            }
        }
        .outlyScreenBackground()
    }

    private func tab<Content: View>(_ tab: AppTab, @ViewBuilder content: () -> Content) -> some View {
        NavigationStack(path: router.binding(for: tab)) {
            content()
                .navigationDestination(for: AppRoute.self, destination: routeDestination)
        }
        .tabItem { Label(tab.title, systemImage: tab.systemImage) }
        .tag(tab)
    }

    @ViewBuilder
    private func routeDestination(_ route: AppRoute) -> some View {
        Group {
            switch route {
            case let .venueDetail(id):
                if store.hasVenue(id: id) { VenueDetailView(venueID: id) }
                else { UnavailableVenueRouteView(venueID: id) }
            case let .rsvpReview(id):
                if store.hasVenue(id: id) { RSVPReviewView(venueID: id) }
                else { UnavailableVenueRouteView(venueID: id) }
            case let .rsvpSuccess(id):
                if store.hasVenue(id: id) { RSVPSuccessView(venueID: id) }
                else { UnavailableVenueRouteView(venueID: id) }
            case let .checkInIntro(id):
                if store.hasVenue(id: id) { CheckInIntroView(venueID: id) }
                else { UnavailableVenueRouteView(venueID: id) }
            case let .offer(id):
                if store.hasVenue(id: id) { OfferView(venueID: id) }
                else { UnavailableVenueRouteView(venueID: id) }
            }
        }
        .environment(theme)
        .toolbar(.hidden, for: .tabBar)
    }
}

private struct UnavailableVenueRouteView: View {
    @Environment(AppRouter.self) private var router
    @Environment(OutlyTheme.self) private var theme
    let venueID: String

    var body: some View {
        ContentUnavailableView {
            Label("Venue unavailable", systemImage: "mappin.slash")
        } description: {
            Text("This venue is no longer available tonight.")
        } actions: {
            Button("Back to Explore") { router.returnToExplore() }
                .buttonStyle(.borderedProminent)
        }
        .foregroundStyle(theme.primaryText)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
        .accessibilityIdentifier("venue-unavailable")
        .accessibilityValue(venueID)
    }
}

private struct VenueSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DemoStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(OutlyTheme.self) private var theme
    @State private var query = ""

    private var results: [Venue] {
        guard !query.isEmpty else { return store.venues }
        return store.venues.filter {
            $0.name.localizedCaseInsensitiveContains(query)
                || $0.neighbourhood.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List(results) { venue in
                Button {
                    store.selectVenue(venue.id)
                    dismiss()
                    router.showVenue(venue.id, on: .explore)
                } label: {
                    HStack(spacing: 12) {
                        VenueArtworkIcon(venue: venue)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(venue.name).font(.headline).foregroundStyle(theme.primaryText)
                            Text(venue.neighbourhood)
                                .font(.subheadline)
                                .foregroundStyle(theme.secondaryText)
                            Text(venue.hours)
                                .font(.caption)
                                .foregroundStyle(theme.mutedText)

                            if let offer = venue.offer {
                                Text(offer.accessibilitySummary)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(offer.kind == .partner ? theme.partnerAccent : theme.accent)
                                    .lineLimit(2)
                                    .padding(.top, 2)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(theme.mutedText)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
            }
            .overlay {
                if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                        .foregroundStyle(theme.secondaryText)
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Venue or neighbourhood")
            .navigationTitle("Search venues")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
            .background(theme.background)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

private struct VenueFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DemoStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(OutlyTheme.self) private var theme

    private var resultCount: Int {
        store.venues.filter(router.filters.includes).count
    }

    var body: some View {
        @Bindable var router = router

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: OutlyMetrics.spacing32) {
                    VStack(alignment: .leading, spacing: 4) {
                        SectionEyebrow(text: "Neighbourhood")

                        filterRow("All", selected: router.filters.neighbourhood == nil) {
                            router.filters.neighbourhood = nil
                        }
                        filterRow("King West", selected: router.filters.neighbourhood == "King West") {
                            router.filters.neighbourhood = "King West"
                        }
                        filterRow("Ossington", selected: router.filters.neighbourhood == "Ossington") {
                            router.filters.neighbourhood = "Ossington"
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        SectionEyebrow(text: "Tonight")

                        filterRow("Has offer", selected: router.filters.hasOffer) {
                            router.filters.hasOffer.toggle()
                        }
                    }

                    VStack(spacing: 4) {
                        Button("Show \(resultCount) venues") { dismiss() }
                            .buttonStyle(StandardActionButtonStyle())
                            .accessibilityIdentifier("show-filtered-venues")

                        Button("Reset filters") {
                            router.filters = VenueFilters()
                        }
                        .buttonStyle(GhostButtonStyle())
                    }
                }
                .padding(OutlyMetrics.edge)
            }
            .background(theme.background)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func filterRow(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(theme.primaryText)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(theme.accent)
                }
            }
            .frame(minHeight: 48)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                Rectangle().fill(theme.border).frame(height: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DemoStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(OutlyTheme.self) private var theme
    @Environment(\.appServices) private var services
    @State private var isSigningOut = false
    @State private var isDeletingAccount = false
    @State private var showsDeleteConfirmation = false
    @State private var accountError: String?
    @State private var deletionIdempotencyKey = UUID()

    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Toggle("Haptic feedback", isOn: Binding(
                        get: { store.state.hapticsEnabled },
                        set: store.setHapticsEnabled
                    ))
                }

                Section("App") {
                    Button("About") {
                        dismiss()
                        router.presentedSheet = .info(.about)
                    }
                }

                Section("Account") {
                    Button {
                        Task { await signOut() }
                    } label: {
                        HStack {
                            Text("Log out")
                            Spacer()
                            if isSigningOut { ProgressView() }
                        }
                    }
                    .disabled(isSigningOut || isDeletingAccount)

                    Button("Delete account", role: .destructive) {
                        showsDeleteConfirmation = true
                    }
                    .disabled(isSigningOut || isDeletingAccount)
                }

                if let accountError {
                    Section {
                        Text(accountError)
                            .font(.footnote)
                            .foregroundStyle(theme.error)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .presentationDetents([.medium, .large])
        .confirmationDialog(
            "Delete your Outly account?",
            isPresented: $showsDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete account", role: .destructive) {
                Task { await deleteAccount() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes your account and ends your current plan and offer access.")
        }
    }

    @MainActor
    private func signOut() async {
        guard !isSigningOut else { return }
        isSigningOut = true
        accountError = nil
        defer { isSigningOut = false }

        do {
            try await services.signOut()
            await CheckInLiveActivityManager.shared.endAll()
            finishAccountExit()
        } catch {
            accountError = Self.message(for: error, fallback: "Couldn’t log out. Try again.")
        }
    }

    @MainActor
    private func deleteAccount() async {
        guard !isDeletingAccount else { return }
        isDeletingAccount = true
        accountError = nil
        defer { isDeletingAccount = false }

        do {
            try await services.deleteConsumerAccount(deletionIdempotencyKey)
            try? await services.signOut()
            await CheckInLiveActivityManager.shared.endAll()
            finishAccountExit()
        } catch {
            accountError = Self.message(for: error, fallback: "Couldn’t delete your account. Try again.")
        }
    }

    private func finishAccountExit() {
        store.signOutLocally()
        dismiss()
        router.reset()
    }

    private static func message(for error: Error, fallback: String) -> String {
        (error as? LocalizedError)?.errorDescription ?? fallback
    }
}

private struct InfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(OutlyTheme.self) private var theme
    let page: InfoPage

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: OutlyMetrics.spacing16) {
                    if page != .support {
                        WingedOMarkView(compact: true)
                            .padding(.bottom, 12)
                    }

                    Text(copy)
                        .font(.body)
                        .foregroundStyle(theme.secondaryText)
                        .lineSpacing(5)

                    if page == .privacy {
                        Label("Not shared with venues", systemImage: "lock.shield")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(theme.primaryText)
                            .padding(.top, 8)
                    } else if page == .about {
                        Text("Version 1.0")
                            .font(.caption)
                            .foregroundStyle(theme.mutedText)
                            .padding(.top, 8)
                    }
                }
                .padding(OutlyMetrics.edge)
            }
            .background(theme.background)
            .navigationTitle(page.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .presentationDetents([.height(260), .medium])
    }

    private var copy: String {
        switch page {
        case .privacy:
            "Your precise location is sent securely only when you choose Check in. Outly uses it to verify that you’re at the venue, keeps the verification result, and does not share your coordinates with venues or other users."
        case .support:
            "Choose a venue, then check in when you arrive. If there’s an offer, its screen shows exactly how long it remains available."
        case .about:
            "A map-first way to decide where to go tonight."
        }
    }
}
