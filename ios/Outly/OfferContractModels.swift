import Foundation

/// Sanitized payload returned by `list_eligible_offers` and embedded in
/// `unlock_offer_for_check_in`. Commercial campaign data never enters this
/// client contract.
struct OfferContractPayload: Decodable, Sendable {
    let offerID: UUID
    let offerVersionID: UUID
    let kind: String
    let title: String
    let explanation: String?
    let ctaLabel: String
    let redemptionMode: String
    let destinationURL: String?
    let staffDisplayTitle: String?
    let staffInstruction: String?
    let claimDurationSeconds: Int?
    let presentationKind: String
    let sponsorDisplayName: String?
    let sponsorLogoStoragePath: String?
    let sponsorDisclosure: String?
    let discoveryTreatment: String
    let discoveryBadgeLabel: String?
    let discoveryIconKey: String?

    private enum CodingKeys: String, CodingKey {
        case offerID = "offer_id"
        case offerVersionID = "offer_version_id"
        case kind
        case title
        case explanation
        case ctaLabel = "cta_label"
        case redemptionMode = "redemption_mode"
        case destinationURL = "destination_url"
        case staffDisplayTitle = "staff_display_title"
        case staffInstruction = "staff_instruction"
        case claimDurationSeconds = "claim_duration_seconds"
        case presentationKind = "presentation_kind"
        case sponsorDisplayName = "sponsor_display_name"
        case sponsorLogoStoragePath = "sponsor_logo_storage_path"
        case sponsorDisclosure = "sponsor_disclosure"
        case discoveryTreatment = "discovery_treatment"
        case discoveryBadgeLabel = "discovery_badge_label"
        case discoveryIconKey = "discovery_icon_key"
    }

    func venueOffer(sponsorLogoURL: URL? = nil) throws -> VenueOffer {
        guard let offerKind = OfferKind(rawValue: kind), presentationKind == kind else {
            throw OfferContractError.invalidPresentationKind
        }

        let resolvedRedemptionMode: OfferRedemptionMode
        switch redemptionMode {
        case "staff_display": resolvedRedemptionMode = .staffDisplay
        case "external_link": resolvedRedemptionMode = .externalLink
        default: throw OfferContractError.invalidRedemptionMode
        }

        let resolvedDiscoveryTreatment: OfferDiscoveryTreatment
        switch discoveryTreatment {
        case "none": resolvedDiscoveryTreatment = .none
        case "outly_exclusive": resolvedDiscoveryTreatment = .outlyExclusive
        case "partner_featured": resolvedDiscoveryTreatment = .partnerFeatured
        default: throw OfferContractError.invalidDiscoveryTreatment
        }

        let resolvedDestinationURL: URL?
        if let destinationURL {
            guard let url = URL(string: destinationURL), url.scheme == "https" else {
                throw OfferContractError.invalidDestinationURL
            }
            resolvedDestinationURL = url
        } else {
            resolvedDestinationURL = nil
        }

        let sponsor: OfferSponsor?
        if offerKind == .partner {
            guard let sponsorDisplayName, let sponsorDisclosure else {
                throw OfferContractError.missingPartnerSnapshot
            }
            sponsor = OfferSponsor(
                displayName: sponsorDisplayName,
                disclosure: sponsorDisclosure,
                logoAssetName: nil,
                logoURL: sponsorLogoURL
            )
        } else {
            sponsor = nil
        }

        return VenueOffer(
            id: offerID.uuidString.lowercased(),
            versionID: offerVersionID.uuidString.lowercased(),
            kind: offerKind,
            title: title,
            explanation: explanation,
            ctaLabel: ctaLabel,
            redemptionMode: resolvedRedemptionMode,
            destinationURL: resolvedDestinationURL,
            staffDisplayTitle: staffDisplayTitle,
            staffInstruction: staffInstruction,
            claimDurationSeconds: claimDurationSeconds,
            sponsor: sponsor,
            discoveryTreatment: resolvedDiscoveryTreatment,
            discoveryBadgeLabel: discoveryBadgeLabel
        )
    }
}

struct UnlockedOfferClaimResponse: Decodable, Sendable {
    let claimID: UUID
    let unlockedAt: Date
    let expiresAt: Date?
    let effectiveStatus: String
    let staffReference: String
    let offerPayload: OfferContractPayload

    private enum CodingKeys: String, CodingKey {
        case claimID = "claim_id"
        case unlockedAt = "unlocked_at"
        case expiresAt = "expires_at"
        case effectiveStatus = "effective_status"
        case staffReference = "staff_reference"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        claimID = try container.decode(UUID.self, forKey: .claimID)
        unlockedAt = try container.decode(Date.self, forKey: .unlockedAt)
        expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
        effectiveStatus = try container.decode(String.self, forKey: .effectiveStatus)
        staffReference = try container.decode(String.self, forKey: .staffReference)
        offerPayload = try OfferContractPayload(from: decoder)
    }
}

enum OfferContractError: Error, Equatable {
    case invalidPresentationKind
    case invalidRedemptionMode
    case invalidDiscoveryTreatment
    case invalidDestinationURL
    case missingPartnerSnapshot
}
