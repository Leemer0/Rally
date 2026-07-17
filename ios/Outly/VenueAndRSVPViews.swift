import SwiftUI

struct VenueDetailView: View {
    @Environment(DemoStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(OutlyTheme.self) private var theme
    let venueID: String

    private var venue: Venue { VenueCatalog.venue(id: venueID) }
    private var isActivePlan: Bool { store.plan?.venueID == venueID }
    private var isCheckedIn: Bool { store.isCheckedIn(to: venueID) }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VenueDetailHeader(venue: venue, isCheckedIn: isCheckedIn)

                    CrowdInsightsSurface(venue: venue, goingCount: attendanceCount)
                        .padding(.top, 20)

                    if let offer = venue.offer {
                        VStack(alignment: .leading, spacing: 7) {
                            Label(offer, systemImage: "ticket.fill")
                                .font(.headline)
                                .foregroundStyle(theme.primaryText)
                                .symbolRenderingMode(.monochrome)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 16)
                        .overlay(alignment: .top) { Divider().overlay(theme.border) }
                        .overlay(alignment: .bottom) { Divider().overlay(theme.border) }
                        .padding(.top, 22)
                    }
                }
                .padding(OutlyMetrics.edge)
            }

            BottomActionBar {
                ExpiryAwareView(expiration: store.offerWindow(at: venueID)?.expiresAt) { now in
                    if store.isOfferActive(at: venueID, now: now) {
                        Button("View offer") {
                            router.navigate(to: .offer(venue.id))
                        }
                        .buttonStyle(MetalSilverActionButtonStyle())
                    } else if store.isCheckedIn(to: venueID, at: now) {
                        Label("Checked in", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(theme.accent)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: OutlyMetrics.controlHeight)
                            .background(theme.surface, in: RoundedRectangle(cornerRadius: OutlyMetrics.buttonRadius, style: .continuous))
                    } else {
                        VStack(spacing: 4) {
                            if isActivePlan {
                                Button("Check in") {
                                    router.navigate(to: .checkInIntro(venue.id))
                                }
                                .buttonStyle(MetalSilverActionButtonStyle())
                            } else {
                                Button("Make a plan") {
                                    store.preparePlan(for: venue.id)
                                    router.navigate(to: .rsvpReview(venue.id))
                                }
                                .buttonStyle(MetalSilverActionButtonStyle())
                            }

                            Button(isActivePlan ? "Change plan" : "I’m already here") {
                                if isActivePlan {
                                    store.preparePlan(for: venue.id)
                                    router.navigate(to: .rsvpReview(venue.id))
                                } else {
                                    router.navigate(to: .checkInIntro(venue.id))
                                }
                            }
                            .buttonStyle(GhostButtonStyle())
                        }
                    }
                }
            }
        }
        .outlyNavigationTitle("")
        .outlyScreenBackground()
    }

    private var attendanceCount: Int {
        venue.goingCount + (isActivePlan ? 1 : 0)
    }
}

struct RSVPReviewView: View {
    @Environment(DemoStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(OutlyTheme.self) private var theme
    let venueID: String

    private var venue: Venue { VenueCatalog.venue(id: venueID) }

    var body: some View {
        FlowScreen(title: "Review your plan") {
            VStack(spacing: 16) {
                OutlyCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(venue.name).font(.title2.weight(.bold))
                        Text(venue.neighbourhood)
                            .font(.subheadline).foregroundStyle(theme.secondaryText)
                        Text(venue.hours)
                            .font(.caption).foregroundStyle(theme.mutedText)
                        Divider().overlay(theme.border)
                        ReviewRow(label: "Date", value: tonightLabel)
                    }
                }

                if let plan = store.plan, plan.venueID != venueID {
                    Label(
                        "This replaces your plan at \(VenueCatalog.venue(id: plan.venueID).name).",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                        .font(.subheadline)
                        .foregroundStyle(theme.warning)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        } footer: {
            Button("Confirm plan") {
                store.confirmPlan(for: venueID)
                router.navigate(to: .rsvpSuccess(venueID))
            }
            .buttonStyle(MetalSilverActionButtonStyle())
            .accessibilityIdentifier("confirm-plan")
        }
    }

    private var tonightLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_CA")
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: Date())
    }
}

struct RSVPSuccessView: View {
    @Environment(AppRouter.self) private var router
    let venueID: String

    private var venue: Venue { VenueCatalog.venue(id: venueID) }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            SuccessSymbol()
            Text("You’re going to \(venue.name).")
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
                .padding(.top, 24)
                .accessibilityIdentifier("plan-confirmed")
            Spacer()

            VStack(spacing: 9) {
                Button("Check in") { router.navigate(to: .checkInIntro(venueID)) }
                    .buttonStyle(MetalSilverActionButtonStyle())
                    .accessibilityIdentifier("at-venue")
                Button("Back to Explore") { router.returnToExplore() }
                    .buttonStyle(GhostButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .toolbar(.hidden, for: .navigationBar)
        .outlyScreenBackground()
    }
}

private struct VenueDetailHeader: View {
    @Environment(OutlyTheme.self) private var theme
    let venue: Venue
    let isCheckedIn: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isCheckedIn {
                StatusPill(text: "Checked in", tone: .accent)
                    .padding(.bottom, 12)
            }

            Text(venue.name)
                .font(.largeTitle.weight(.bold))

            Text(venue.neighbourhood)
                .font(.subheadline)
                .foregroundStyle(theme.secondaryText)
                .padding(.top, 3)

            Text(venue.hours)
                .font(.caption)
                .foregroundStyle(theme.mutedText)
                .padding(.top, 5)

            Link(destination: venue.appleMapsURL) {
                HStack(spacing: 10) {
                    Image(systemName: "mappin")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.accent)
                        .accessibilityHidden(true)

                    Text(venue.address)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(theme.primaryText)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 12)

                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.secondaryText)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, minHeight: OutlyMetrics.minimumTouchTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(venue.address), open in Maps")
            .accessibilityHint("Opens Apple Maps")
            .accessibilityIdentifier("venue-address")
            .padding(.top, 8)
        }
    }
}

private struct FlowScreen<Content: View, Footer: View>: View {
    @Environment(OutlyTheme.self) private var theme
    var eyebrow: String?
    let title: String
    var description: String?
    let content: Content
    let footer: Footer

    init(
        eyebrow: String? = nil,
        title: String,
        description: String? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.description = description
        self.content = content()
        self.footer = footer()
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let eyebrow { SectionEyebrow(text: eyebrow).foregroundStyle(theme.accent) }
                    Text(title)
                        .font(.largeTitle.weight(.bold))
                        .padding(.top, eyebrow == nil ? 0 : 8)
                    if let description {
                        Text(description).font(.subheadline).foregroundStyle(theme.secondaryText).lineSpacing(4).padding(.top, 12)
                    }
                    content.padding(.top, 28)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, OutlyMetrics.edge)
                .padding(.vertical, OutlyMetrics.edge)
            }
            BottomActionBar { footer }
        }
        .outlyNavigationTitle("Make a plan")
        .outlyScreenBackground()
    }
}

private struct ReviewRow: View {
    @Environment(OutlyTheme.self) private var theme
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(theme.mutedText)
            Spacer()
            Text(value).font(.subheadline.weight(.semibold)).multilineTextAlignment(.trailing)
        }
    }
}
