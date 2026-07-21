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
            case let .venueDetail(id): VenueDetailView(venueID: id)
            case let .rsvpReview(id): RSVPReviewView(venueID: id)
            case let .rsvpSuccess(id): RSVPSuccessView(venueID: id)
            case let .checkInIntro(id): CheckInIntroView(venueID: id)
            case let .offer(id): OfferView(venueID: id)
            }
        }
        .environment(theme)
        .toolbar(.hidden, for: .tabBar)
    }
}

private struct VenueSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DemoStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(OutlyTheme.self) private var theme
    @State private var query = ""

    private var results: [Venue] {
        guard !query.isEmpty else { return VenueCatalog.venues }
        return VenueCatalog.venues.filter {
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
    @Environment(AppRouter.self) private var router
    @Environment(OutlyTheme.self) private var theme

    private var resultCount: Int {
        VenueCatalog.venues.filter(router.filters.includes).count
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
            }
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .presentationDetents([.medium])
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
                        Label("On-device only", systemImage: "lock.shield")
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
            "Your location is checked only when you choose Check in. It is never stored."
        case .support:
            "Choose a venue, then check in when you arrive. Any offer you unlock stays valid for 10 minutes."
        case .about:
            "A map-first way to decide where to go tonight."
        }
    }
}
