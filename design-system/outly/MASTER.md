# Outly iOS Design System

## Product character

Outly is a private, map-first nightlife utility for deciding where to go, making a plan, and checking in. It should feel cinematic at first glance and quiet during use. The product promise is social momentum without dating-app framing: “Say you met at a bar, not a dating app.”

## Design principles

1. The map is the primary canvas. Chrome stays subordinate to venue activity and the selected venue.
2. Lime communicates selection and live verified state. Chrome communicates commitment actions. Neither is ambient decoration.
3. Use one elevated surface at a time. Cards are reserved for bounded objects such as a selected venue, active plan, or review summary. The live offer is a full-screen proof state, not a card.
4. Prefer native navigation, sheets, tab bars, controls, SF Symbols, Dynamic Type, VoiceOver semantics, and system gestures.
5. Liquid Glass is contextual: map controls and the selected venue preview only. Standard screens use opaque semantic surfaces.
6. Use concise language, sentence case, and one clear primary action per screen.

## Color

| Role | Value | Use |
|---|---:|---|
| Background | `#080B10` | Primary canvas |
| Secondary background | `#10141B` | System chrome and grouped regions |
| Surface | `#151A21` | Bounded content objects |
| Elevated surface | `#202630` | Disabled controls and secondary depth |
| Primary text | `#F5F7F8` | Titles and essential information |
| Secondary text | `#B1B8C2` | Body and supporting labels |
| Muted text | `#7E8793` | Metadata only |
| Accent | `#C7FF3D` | Selection, map focus, live verification |
| Chrome | semantic silver ramp | Rare, high-intent actions and live-pass proof |
| Crowd cool | `#5C9DFF` | Men in the crowd estimate |
| Crowd warm | `#FF76B8` | Women in the crowd estimate |
| Success | `#63E681` | Completed and active status |
| Warning | `#F2B84B` | Irreversible or replacement warning |
| Error | `#FF6767` | Inline failures and destructive state |

Never rely on color alone for status. Pair it with text, a checkmark, or an accessibility value.

## Typography

Use San Francisco through SwiftUI semantic text styles. Do not ship fixed point sizes for user-facing copy.

- Marketing statement: `.largeTitle.bold()` with natural wrapping.
- Screen title: native navigation title or `.largeTitle.bold()`.
- Section title: `.title2.bold()` or `.headline` based on hierarchy.
- Body: `.body`.
- Supporting copy: `.subheadline`.
- Metadata: `.caption`; reserve `.caption2` for truly secondary compact labels.
- Eyebrows: `.footnote.semibold()`, uppercase, tracking `0.75`.

## Layout tokens

- Standard edge inset: `20 pt`
- Compact/map inset: `16 pt`
- Spacing scale: `4, 8, 12, 16, 24, 32 pt`
- Minimum touch target: `44 × 44 pt`
- Primary control height: `54 pt`
- Button radius: `12 pt`
- Content surface radius: `14 pt`
- Map preview radius: `24 pt`

Use leading alignment for decision screens. Center alignment is reserved for finite success states and location confirmation.

## Components and interaction

- Brand mark: use the supplied winged-O asset alone. Never typeset an Outly wordmark, synthesize an arrow, or substitute an SF Symbol.
- Standard action: a flat elevated dark control for routine continuation such as onboarding steps, filters, and review. It must not imitate metal.
- Metal action: a real MetalKit-rendered polished chrome surface reserved for high-intent moments: Sign Up, Make a plan, Confirm, Check in, View offer, and Verify my location. It uses a smooth convex reflection, white specular core, and subtle cool/warm optical edge; never brushed noise, rough texture, rainbow dispersion, or multiple competing metal buttons.
- Secondary button: transparent dark surface with a subtle border; do not visually compete with the primary action.
- Tertiary action: text-only, minimum 44 pt target.
- Selection rows: full-width, divided rows with a trailing radio/check state. Avoid a stack of floating cards.
- Status: dot plus short text. Capsules are reserved for filter controls.
- Map markers: venue-specific isometric 3D miniatures with bold silhouettes and a quiet leader/dot tether to the exact coordinate; lime glow means selected. Attendance stays in the preview and accessibility value instead of appearing as a numbered bubble.
- Venue preview: the only large Liquid Glass content surface on the map. It contains identity, momentum, compact crowd intelligence, offer, and one action. Keep generated venue artwork confined to map markers.
- Crowd intelligence: a compact age histogram with a written average age, followed by one labelled blue/pink gender-distribution line. Always expose percentages as text and an accessibility value; never rely on color alone.
- Planning: plans are individual only. Arrival time goes directly to review, with no party-size or group choice.
- Check-in: one location check with no QR step. A verified venue-area check unlocks a clearly timed offer for 10 minutes; once expired, the offer details disappear.
- Check-in transition: successful location verification opens the offer directly. Do not insert a confirmation screen that repeats what the active offer already proves.
- Active offer: an uninterrupted pure-black proof canvas containing only venue, offer, countdown, one labelled lime validity signal, and the dimensional winged O. Do not enclose it in a card. Lead with a compact `VALID AT` eyebrow and a prominent venue name so a server can verify the location immediately. A thin open Metal-rendered optical-glass orbit uses a dark transparent core, crisp neutral-silver edge rails, a receding live segment, and a small embedded lime endpoint marking exact progress. The countdown itself is flat native SF with tabular digits in primary off-white—no metallic fill, extrusion, glow, or decorative typography. The orbit remains the sole signature material and motion; the winged O stays opaque and stable. Provide a static Reduce Motion state.
- Navigation: native `NavigationStack` back affordance and edge-swipe on pushed screens. Custom navigation is limited to immersive onboarding and the map root.
- Sheets: native detents, drag indicator, inline title, and Done only when dismissal is not already obvious.

Use selection haptics for reversible changes and success haptics for completed plans and check-ins. Respect Reduce Motion and never make motion necessary to understand state.

Every Metal surface runs at no more than 30 fps, drops to 15 fps in Low Power Mode, freezes decorative lighting under Reduce Motion, and retains a non-Metal fallback.

## First-run identity

- The first screen mirrors the website’s editorial composition: original dark nightlife photography, animated winged O in the compact header, white/lime split headline, and concise real-world value copy.
- Do not include “Coming soon,” ticker chrome, a synthetic wordmark, or a full-screen logo animation.
- Offer exactly two entry choices: polished Metal Sign Up and quiet Log In. They lead to distinct authentication intents; login bypasses profile creation for an existing user.
- The supplied winged O is also the app icon on a near-black field.

## Accessibility and responsiveness

- Support Dynamic Type without truncating primary text or clipping controls.
- At accessibility sizes, collapse dense horizontal compositions and remove nonessential artwork before reducing text.
- Keep foreground contrast at WCAG AA-equivalent levels for body content.
- Add explicit labels to icon-only buttons and concise combined labels to map markers and charts.
- Loading controls remain labelled and disabled; errors appear beside the affected action.
- Preserve safe areas and keyboard avoidance. Inputs use content types and submit labels.

## Anti-patterns

Do not add decorative gradients, neon glows, glass cards on standard pages, repeated pill badges, icon-in-circle hero stacks, fake brand marks, thick closed fitness-style countdown rings, generated venue artwork outside the approved map-marker system, duplicated status copy, party-size controls, or oversized numeric displays outside the live-offer proof moment. Do not turn profile/settings content into a dashboard.
