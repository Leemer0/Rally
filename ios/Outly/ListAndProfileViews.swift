import SwiftUI

struct VenueListView: View {
    @Environment(DemoStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(OutlyTheme.self) private var theme

    private var venues: [Venue] {
        store.venues.filter(router.filters.includes)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    WingedOMarkView(compact: true)
                    Spacer()
                    Button { router.presentedSheet = .venueFilters } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "slider.horizontal.3")
                            if router.filters != VenueFilters() {
                                Circle()
                                    .fill(theme.accent)
                                    .frame(width: 6, height: 6)
                                    .offset(x: 3, y: -3)
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                    .buttonStyle(IconCircleButtonStyle())
                    .accessibilityLabel(router.filters == VenueFilters() ? "Open filters" : "Open filters, filters active")
                    .accessibilityIdentifier("open-filters")
                }

                Text("Tonight in Toronto")
                    .font(.title.weight(.semibold))
                    .padding(.top, 14)
                    .padding(.bottom, 8)

                HStack {
                    SectionEyebrow(text: "\(venues.count) venues")
                        .accessibilityIdentifier("venue-list-title")
                    Spacer()
                    if router.filters != VenueFilters() {
                        Button("Clear filters") { router.filters = VenueFilters() }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(theme.secondaryText)
                            .frame(minHeight: OutlyMetrics.minimumTouchTarget)
                    }
                }
                .padding(.bottom, 2)

                if venues.isEmpty {
                    ContentUnavailableView(
                        "No venues match",
                        systemImage: "slider.horizontal.3",
                        description: Text("Try clearing one of the filters.")
                    )
                    .foregroundStyle(theme.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else {
                    ForEach(Array(venues.enumerated()), id: \.element.id) { index, venue in
                        VenueListCard(venue: venue)
                        if index < venues.count - 1 {
                            Divider().overlay(theme.border)
                        }
                    }
                }
            }
            .padding(.horizontal, OutlyMetrics.edge)
            .padding(.top, 8)
            .padding(.bottom, OutlyMetrics.spacing24)
        }
        .toolbar(.hidden, for: .navigationBar)
        .outlyScreenBackground()
    }
}

struct ProfileView: View {
    @Environment(DemoStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(OutlyTheme.self) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    WingedOMarkView(compact: true)
                    Spacer()
                    Button { router.presentedSheet = .settings } label: {
                        Image(systemName: "gearshape")
                    }
                    .buttonStyle(IconCircleButtonStyle())
                    .accessibilityLabel("Settings")
                }

                Text(store.profile.firstName.isEmpty ? "Profile" : store.profile.firstName)
                    .font(.title.weight(.semibold))
                    .padding(.top, 14)

                SectionEyebrow(text: "Tonight")
                    .padding(.top, 16)
                if let plan = store.plan {
                    ActivePlanCard(plan: plan).padding(.top, 8)
                } else {
                    Button {
                        router.returnToExplore()
                    } label: {
                        HStack {
                            Text("Explore venues")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(theme.primaryText)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(theme.mutedText)
                        }
                        .frame(minHeight: OutlyMetrics.minimumTouchTarget)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                }

                SectionEyebrow(text: "Account").padding(.top, 22)
                VStack(spacing: 0) {
                    profileRow("Age requirement", "19+ confirmed")
                    Divider().overlay(theme.border)
                    menuRow("Privacy") { router.presentedSheet = .info(.privacy) }
                    Divider().overlay(theme.border)
                    menuRow("Help & support") { router.presentedSheet = .info(.support) }
                }
                .padding(.top, 2)

                if let checkedIn = store.lastCheckedInVenue {
                    SectionEyebrow(text: "Latest check-in").padding(.top, 22)
                    TimelineView(.periodic(from: .now, by: 60)) { context in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3).foregroundStyle(theme.accent)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(checkedIn.name).font(.subheadline.weight(.semibold))
                                Text(store.checkInStatusText(at: context.date) ?? "Checked in")
                                    .font(.caption)
                                    .foregroundStyle(theme.mutedText)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("latest-check-in")
                    }
                    .padding(.top, 10)
                }
            }
            .padding(.horizontal, OutlyMetrics.edge)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .toolbar(.hidden, for: .navigationBar)
        .outlyScreenBackground()
    }

    private func profileRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(theme.secondaryText)
            Spacer()
            Text(value).font(.subheadline.weight(.semibold))
        }
        .frame(minHeight: 46)
    }

    private func menuRow(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).foregroundStyle(theme.secondaryText)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(theme.mutedText)
            }
            .font(.subheadline)
            .frame(minHeight: 46)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct ActivePlanCard: View {
    @Environment(DemoStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(OutlyTheme.self) private var theme
    @Environment(\.appServices) private var services
    let plan: NightPlan
    @State private var isCancelling = false

    private var venue: Venue { store.venue(id: plan.venueID) }
    private var isCheckedIn: Bool { store.isCheckedIn(to: venue.id) }

    var body: some View {
        OutlyCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(venue.name).font(.headline)
                        Text(plan.dateLabel)
                            .font(.subheadline).foregroundStyle(theme.secondaryText)
                    }
                    Spacer()
                    StatusPill(text: isCheckedIn ? "Checked in" : "Plan", tone: isCheckedIn ? .accent : .neutral)
                }
                ExpiryAwareView(expiration: store.offerPresentationEndsAt(venue.id)) { now in
                    HStack(spacing: 10) {
                        if store.isOfferActive(at: venue.id, now: now) {
                            Button("View offer") { router.navigate(to: .offer(venue.id)) }
                                .buttonStyle(MetalSilverActionButtonStyle())
                        } else if store.isCheckedIn(to: venue.id, at: now) {
                            Label("Checked in", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                                .foregroundStyle(theme.accent)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: OutlyMetrics.controlHeight)
                        } else {
                            Button("Check in") { router.navigate(to: .checkInIntro(venue.id)) }
                                .buttonStyle(MetalSilverActionButtonStyle())
                        }

                        Menu {
                            Button("View venue") { router.navigate(to: .venueDetail(venue.id)) }
                            Button("Change plan") {
                                store.preparePlan(for: venue.id)
                                router.navigate(to: .rsvpReview(venue.id))
                            }
                            Button("Cancel plan", role: .destructive) {
                                Task { await cancelPlan() }
                            }
                            .disabled(isCancelling)
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                        .buttonStyle(IconCircleButtonStyle())
                        .accessibilityLabel("More plan options")
                    }
                }
            }
        }
    }

    @MainActor
    private func cancelPlan() async {
        guard !isCancelling else { return }
        isCancelling = true
        defer { isCancelling = false }

        do {
            if let planID = plan.id {
                try await services.cancelNightPlan(planID)
            } else if !services.isDemo {
                return
            }
            store.cancelPlan()
        } catch {
            HapticManager.shared.error(enabled: store.state.hapticsEnabled)
        }
    }
}
