import SwiftUI

struct ExploreView: View {
    @Environment(DemoStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(OutlyTheme.self) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVenuePreviewPresented = true

    private var filteredVenues: [Venue] {
        store.venues.filter(router.filters.includes)
    }

    private var selectedVenue: Venue? {
        guard isVenuePreviewPresented else { return nil }
        return filteredVenues.first(where: { $0.id == store.state.selectedVenueID })
            ?? filteredVenues.first
    }

    var body: some View {
        ZStack {
            OutlyMapView(
                venues: filteredVenues,
                selectedVenueID: selectedVenue?.id,
                onSelectVenue: selectVenue,
                onTapBackground: dismissVenuePreview
            )
            .ignoresSafeArea(edges: .top)
            .accessibilityIdentifier("toronto-map")

            VStack(spacing: 12) {
                ExploreHeader()
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    if let checkedInVenue = store.activeCheckedInVenue(at: context.date) {
                        ActiveCheckInMapCard(venue: checkedInVenue)
                    }
                }
                Spacer()
                if filteredVenues.isEmpty {
                    EmptyMapCard()
                } else if let selectedVenue {
                    if dynamicTypeSize.isAccessibilitySize {
                        VenuePreviewCard(venue: selectedVenue)
                            .frame(maxHeight: 430)
                            .transition(previewTransition)
                    } else {
                        VenuePreviewCard(venue: selectedVenue)
                            .transition(previewTransition)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 12)
        }
        .background(theme.background)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var previewTransition: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }

    private func selectVenue(_ venueID: Venue.ID) {
        store.selectVenue(venueID)
        setVenuePreviewPresented(true)
    }

    private func dismissVenuePreview() {
        setVenuePreviewPresented(false)
    }

    private func setVenuePreviewPresented(_ isPresented: Bool) {
        guard isVenuePreviewPresented != isPresented else { return }

        if reduceMotion {
            isVenuePreviewPresented = isPresented
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                isVenuePreviewPresented = isPresented
            }
        }
    }
}

private struct ExploreHeader: View {
    @Environment(AppRouter.self) private var router
    @Environment(OutlyTheme.self) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        WingedOMarkView(compact: true)
                        Spacer(minLength: 8)
                        controls
                    }
                    location
                }
            } else {
                HStack(alignment: .center, spacing: 10) {
                    WingedOMarkView(compact: true)
                    location
                    Spacer(minLength: 8)
                    controls
                }
            }
        }
    }

    private var location: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                Text("Toronto · Tonight")
                    .font(.headline.weight(.semibold))
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Toronto")
                        .font(.title2.weight(.semibold))
                    Text("Tonight")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.accent)
                }
            }
        }
        .foregroundStyle(theme.primaryText)
        .fixedSize(horizontal: false, vertical: true)
        .shadow(color: .black.opacity(0.62), radius: 12, y: 3)
    }

    private var controls: some View {
        HStack(spacing: 8) {
            Button { router.presentedSheet = .venueSearch } label: {
                Image(systemName: "magnifyingglass")
            }
            .buttonStyle(MapOverlayButtonStyle())
            .accessibilityLabel("Search venues")
            .accessibilityIdentifier("search-venues")

            Button { router.presentedSheet = .venueFilters } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "slider.horizontal.3")
                    if router.filters != VenueFilters() {
                        Circle()
                            .fill(theme.accent)
                            .frame(width: 7, height: 7)
                            .offset(x: 4, y: -4)
                            .accessibilityHidden(true)
                    }
                }
            }
            .buttonStyle(MapOverlayButtonStyle())
            .accessibilityLabel(router.filters == VenueFilters() ? "Filter venues" : "Filter venues, filters active")
            .accessibilityIdentifier("filter-venues")
        }
    }
}

private struct MapOverlayButtonStyle: ButtonStyle {
    @Environment(OutlyTheme.self) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .frame(width: 44, height: 44)
            .foregroundStyle(theme.primaryText)
            .background(
                theme.sunkenSurface.opacity(configuration.isPressed ? 0.88 : 0.78),
                in: Circle()
            )
            .overlay { Circle().stroke(theme.primaryText.opacity(0.13), lineWidth: 0.75) }
            .shadow(color: .black.opacity(0.34), radius: 9, y: 3)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}

enum VenueMarkerAnchor {
    case bottomLeft
    case bottomRight
    case topRight
    case center

    static func forVenue(_ venueID: Venue.ID) -> Self {
        #if DEBUG
        switch venueID {
        case "track-field": .bottomLeft
        case "lavelle", "baro": .bottomRight
        case "paris-texas": .topRight
        default: .center
        }
        #else
        .center
        #endif
    }

    var unitPoint: UnitPoint {
        switch self {
        case .bottomLeft: .bottomLeading
        case .bottomRight: .bottomTrailing
        case .topRight: .topTrailing
        case .center: .center
        }
    }
}

struct VenueMarker: View {
    @Environment(OutlyTheme.self) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let venue: Venue
    let selected: Bool
    let coordinateAnchor: VenueMarkerAnchor
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                markerConnector

                markerArtwork
                    .frame(width: selected ? 84 : 72, height: selected ? 84 : 72)
                    .overlay(alignment: .topTrailing) {
                        if let offer = venue.offer,
                           offer.discoveryTreatment != .none
                        {
                            OfferDiscoveryIcon(offer: offer, size: selected ? 29 : 25)
                                .offset(x: selected ? 4 : 2, y: selected ? -2 : 0)
                        }
                    }
                    .scaleEffect(selected ? 1.08 : 1)
                    .shadow(color: .black.opacity(0.52), radius: selected ? 9 : 6, y: 4)
                    .shadow(color: selected ? theme.accent.opacity(0.82) : .clear, radius: 10)
                    .offset(x: markerHorizontalOffset)
                    .accessibilityHidden(true)

                if selected, !dynamicTypeSize.isAccessibilitySize {
                    HStack(spacing: 5) {
                        Circle().fill(theme.accent).frame(width: 5, height: 5)
                        Text(venue.name)
                            .lineLimit(1)
                    }
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(theme.primaryText)
                    .padding(.horizontal, 10)
                    .frame(height: 26)
                    .background(.thinMaterial, in: Capsule())
                    .overlay { Capsule().stroke(.white.opacity(0.14), lineWidth: 0.75) }
                    .fixedSize()
                    .offset(x: markerHorizontalOffset, y: 55)
                    .environment(\.colorScheme, .dark)
                }
            }
            .frame(width: 96, height: 84)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: selected)
        .accessibilityLabel(venue.name)
        .accessibilityValue(
            ["\(venue.goingCount) going tonight", venue.offer?.accessibilitySummary]
                .compactMap { $0 }
                .joined(separator: ", ")
        )
        .accessibilityHint("Shows this venue")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("venue-marker-\(venue.id)")
    }

    @ViewBuilder
    private var markerArtwork: some View {
        if let markerURL = venue.markerURL {
            AsyncImage(url: markerURL) { phase in
                if case let .success(image) = phase {
                    image
                        .resizable()
                        .scaledToFit()
                } else {
                    genericMarkerArtwork
                }
            }
        } else if let assetName = venue.mapMarkerAssetName {
            Image(assetName)
                .resizable()
                .scaledToFit()
        } else {
            genericMarkerArtwork
        }
    }

    private var genericMarkerArtwork: some View {
        Image(systemName: "mappin.and.ellipse")
            .resizable()
            .scaledToFit()
            .padding(16)
            .foregroundStyle(theme.accent)
    }

    private var markerConnector: some View {
        GeometryReader { geometry in
            let coordinate = CGPoint(
                x: geometry.size.width * coordinateAnchor.unitPoint.x,
                y: geometry.size.height * coordinateAnchor.unitPoint.y
            )
            let artCenter = CGPoint(
                x: (geometry.size.width / 2) + markerHorizontalOffset,
                y: geometry.size.height / 2
            )

            Path { path in
                path.move(to: artCenter)
                path.addLine(to: coordinate)
            }
            .stroke(
                selected ? theme.accent.opacity(0.9) : theme.primaryText.opacity(0.5),
                style: StrokeStyle(lineWidth: selected ? 2 : 1.25, lineCap: .round)
            )

            Circle()
                .fill(selected ? theme.accent : theme.primaryText.opacity(0.82))
                .frame(width: selected ? 7 : 5, height: selected ? 7 : 5)
                .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
                .position(coordinate)
        }
        .accessibilityHidden(true)
    }

    private var markerHorizontalOffset: CGFloat {
        #if DEBUG
        venue.id == "baro" ? 10 : 0
        #else
        0
        #endif
    }
}

extension Venue {
    var mapMarkerAssetName: String? {
        #if DEBUG
        switch id {
        case "track-field": "VenuePinTrackField"
        case "lavelle": "VenuePinLavelle"
        case "baro": "VenuePinBaro"
        case "paris-texas": "VenuePinParisTexas"
        default: nil
        }
        #else
        nil
        #endif
    }
}

struct VenueArtworkIcon: View {
    @Environment(OutlyTheme.self) private var theme
    let venue: Venue

    var body: some View {
        Group {
            if let markerURL = venue.markerURL {
                AsyncImage(url: markerURL) { phase in
                    if case let .success(image) = phase {
                        image
                            .resizable()
                            .scaledToFit()
                    } else {
                        genericArtwork
                    }
                }
            } else if let assetName = venue.mapMarkerAssetName {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
            } else {
                genericArtwork
            }
        }
        .frame(width: 52, height: 52)
        .overlay(alignment: .topTrailing) {
            if let offer = venue.offer,
               offer.discoveryTreatment != .none
            {
                OfferDiscoveryIcon(offer: offer, size: 20)
                    .offset(x: 3, y: -2)
            }
        }
        .accessibilityHidden(true)
    }

    private var genericArtwork: some View {
        Image(systemName: "mappin.and.ellipse")
            .resizable()
            .scaledToFit()
            .padding(10)
            .foregroundStyle(theme.accent)
    }
}

struct VenuePreviewCard: View {
    @Environment(DemoStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(OutlyTheme.self) private var theme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let venue: Venue

    var body: some View {
        MapGlassSurface {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 12) {
                        ScrollView {
                            detailsButton
                        }
                        .scrollIndicators(.visible)
                        .frame(maxHeight: 276)

                        primaryAction
                    }
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        detailsButton
                        primaryAction
                    }
                }
            }
            .padding(16)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("venue-preview-card")
    }

    private var detailsButton: some View {
        Button { router.navigate(to: .venueDetail(venue.id)) } label: {
            venueDetails
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var primaryAction: some View {
        ExpiryAwareView(expiration: store.offerPresentationEndsAt(venue.id)) { now in
            primaryActionButton(title: primaryActionTitle(now: now), now: now)
                .buttonStyle(MetalSilverActionButtonStyle())
        }
    }

    private var venueDetails: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(venue.name)
                            .font(.title3.weight(.bold))
                            .fixedSize(horizontal: false, vertical: true)
                        if isCheckedIn || isCurrentPlan {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(theme.accent)
                                .accessibilityLabel(isCheckedIn ? "Checked in" : "Your plan")
                        }
                    }

                    Text(venue.neighbourhood)
                        .font(.subheadline)
                        .foregroundStyle(theme.secondaryText)
                    Text(venue.hours)
                        .font(.caption)
                        .foregroundStyle(theme.mutedText)
                        .padding(.top, 2)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.mutedText)
                    .padding(.top, 5)
            }
            .foregroundStyle(theme.primaryText)

            CrowdInsightsSurface(
                venue: venue,
                goingCount: attendanceCount,
                compact: true,
                showsContainer: false
            )

            if let offer = venue.offer {
                OfferDiscoveryRow(offer: offer, compact: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var isCurrentPlan: Bool {
        store.plan?.venueID == venue.id
    }

    private var isCheckedIn: Bool {
        store.checkedInVenue?.id == venue.id
    }

    private var attendanceCount: Int {
        venue.goingCount + (isCurrentPlan ? 1 : 0)
    }

    private func primaryActionButton(title: String, now: Date) -> some View {
        Button {
            performPrimaryAction(now: now)
        } label: {
            Text(title)
        }
        .accessibilityIdentifier("im-going")
    }

    private func primaryActionTitle(now: Date) -> String {
        if store.isOfferActive(at: venue.id, now: now) { return "View offer" }
        if isCheckedIn { return "View venue" }
        if store.plan?.venueID == venue.id { return "Check in" }
        return "Make a plan"
    }

    private func performPrimaryAction(now: Date) {
        if store.isOfferActive(at: venue.id, now: now) {
            router.navigate(to: .offer(venue.id))
        } else if isCheckedIn {
            router.navigate(to: .venueDetail(venue.id))
        } else if store.plan?.venueID == venue.id {
            router.navigate(to: .checkInIntro(venue.id))
        } else {
            store.preparePlan(for: venue.id)
            router.navigate(to: .rsvpReview(venue.id))
        }
    }
}

private struct ActiveCheckInMapCard: View {
    @Environment(DemoStore.self) private var store
    @Environment(AppRouter.self) private var router
    @Environment(OutlyTheme.self) private var theme
    let venue: Venue

    var body: some View {
        ExpiryAwareView(expiration: store.offerPresentationEndsAt(venue.id)) { now in
            let offerIsActive = store.isOfferActive(at: venue.id, now: now)

            MapGlassSurface(cornerRadius: 18) {
                Button {
                    store.selectVenue(venue.id)
                    router.navigate(to: offerIsActive ? .offer(venue.id) : .venueDetail(venue.id))
                } label: {
                    HStack(spacing: 10) {
                        VenueArtworkIcon(venue: venue)
                            .frame(width: 44, height: 44)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(venue.name)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(theme.primaryText)
                                .lineLimit(1)
                            Label("Checked in", systemImage: "checkmark.circle.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(theme.accent)
                        }

                        Spacer(minLength: 8)

                        if offerIsActive,
                           let window = store.offerPresentationWindow(at: venue.id),
                           window.hasCountdown
                        {
                            TimelineView(.periodic(from: .now, by: 1)) { context in
                                Text(countdown(window.remainingSeconds(at: context.date)))
                                    .font(.subheadline.weight(.bold))
                                    .monospacedDigit()
                                    .foregroundStyle(theme.primaryText)
                                    .contentTransition(.numericText(countsDown: true))
                                    .accessibilityLabel("Offer expires in \(spokenCountdown(window.remainingSeconds(at: context.date)))")
                                    .accessibilityIdentifier("map-offer-countdown")
                            }
                        } else if offerIsActive {
                            Text("Offer active")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(theme.accent)
                        } else {
                            Text("On map")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(theme.secondaryText)
                        }

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(theme.mutedText)
                    }
                    .padding(.horizontal, 12)
                    .frame(minHeight: 64)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint(offerIsActive ? "Opens your offer" : "Opens the venue")
                .accessibilityIdentifier("map-active-checkin")
            }
        }
    }

    private func countdown(_ seconds: Int) -> String {
        if seconds >= 3600 {
            return String(
                format: "%02d:%02d:%02d",
                seconds / 3600,
                (seconds % 3600) / 60,
                seconds % 60
            )
        }
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private func spokenCountdown(_ seconds: Int) -> String {
        if seconds >= 3600 {
            return "\(seconds / 3600) hours, \((seconds % 3600) / 60) minutes, \(seconds % 60) seconds"
        }
        return "\(seconds / 60) minutes, \(seconds % 60) seconds"
    }
}

private struct EmptyMapCard: View {
    @Environment(AppRouter.self) private var router
    @Environment(OutlyTheme.self) private var theme

    var body: some View {
        HStack(spacing: 14) {
            Text("No venues match")
                .font(.headline)
                .foregroundStyle(theme.primaryText)
            Spacer()
            Button("Clear") { router.filters = VenueFilters() }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(theme.primaryText)
                .frame(minWidth: 54, minHeight: 44)
        }
        .padding(16)
        .background(
            theme.sunkenSurface.opacity(0.92),
            in: RoundedRectangle(cornerRadius: OutlyMetrics.surfaceRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: OutlyMetrics.surfaceRadius, style: .continuous)
                .stroke(theme.border, lineWidth: 0.75)
        }
    }
}

struct VenueListCard: View {
    @Environment(AppRouter.self) private var router
    @Environment(OutlyTheme.self) private var theme
    let venue: Venue

    var body: some View {
        Button { router.navigate(to: .venueDetail(venue.id)) } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 11) {
                    VenueArtworkIcon(venue: venue)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(venue.name).font(.headline).foregroundStyle(theme.primaryText)
                        Text(venue.neighbourhood)
                            .font(.caption).foregroundStyle(theme.secondaryText)
                        Text(venue.hours)
                            .font(.caption2).foregroundStyle(theme.mutedText)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(theme.mutedText)
                }

                if let offer = venue.offer {
                    OfferDiscoveryRow(offer: offer, compact: true)
                        .padding(.leading, 63)
                }
            }
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            [venue.name, venue.neighbourhood, venue.hours, venue.offer?.accessibilitySummary]
                .compactMap { $0 }
                .joined(separator: ", ")
        )
    }
}

#Preview("Explore") {
    MainAppView()
        .environment(DemoStore(previewState: DemoState(onboardingStage: .main)))
        .environment(AppRouter())
        .environment(OutlyTheme())
        .environment(\.appServices, .demo)
        .preferredColorScheme(.dark)
}
