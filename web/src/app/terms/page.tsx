import type { Metadata } from "next";
import { LegalPage, LegalSection } from "@/components/site/legal-page";

export const metadata: Metadata = {
  title: "Terms of Service",
  description:
    "The terms that govern use of the Outly nightlife app and venue platform.",
  alternates: { canonical: "/terms" },
};

export default function TermsPage() {
  return (
    <LegalPage
      title="Terms of Service"
      updated="July 22, 2026"
      summary="These terms govern your use of the Outly consumer app, website, and venue dashboard. By creating an account or using Outly, you agree to them."
    >
      <LegalSection title="1. Who may use Outly">
        <p>
          Consumer accounts are limited to people aged 19 or older. The date of
          birth you provide must be accurate. Outly does not verify identity or age
          documents, and a verified check-in is not proof of legal age for alcohol
          service or entry.
        </p>
        <p>
          A person creating a venue account must be authorized to act for that
          business and must provide accurate registration and contact information.
          Venue access remains subject to Outly’s review and approval.
        </p>
      </LegalSection>

      <LegalSection title="2. Accounts">
        <p>
          You are responsible for your account, your credentials, and activity under
          your account. Tell us promptly if you suspect unauthorized access. You may
          not transfer an account, impersonate someone else, or create an account
          with false or misleading information.
        </p>
      </LegalSection>

      <LegalSection title="3. Plans, check-ins, and offers">
        <ul>
          <li>
            A consumer may have one active venue plan for each Outly nightlife date.
          </li>
          <li>
            Check-in requires a recent, precise location sample inside the
            server-defined venue boundary. Attempts may be limited or rejected when
            location is inaccurate, stale, outside the boundary, or appears abusive.
          </li>
          <li>
            Offers may be provided by a venue, Outly, or a campaign partner. Each
            offer is subject to its displayed eligibility, hours, availability,
            redemption period, and other conditions. Some expire on a timer; others
            remain open for the stated period.
          </li>
          <li>
            Claims are personal, have no cash value, and may not be sold,
            transferred, duplicated, or obtained by spoofing location or otherwise
            bypassing the service.
          </li>
        </ul>
        <p>
          A venue remains responsible for admission, lawful service, capacity, and
          honouring an approved offer. If an offer cannot be honoured, contact Outly
          support. Crowd counts, demographics, hours, and availability are estimates
          or venue-supplied information and may change.
        </p>
      </LegalSection>

      <LegalSection title="4. Venue responsibilities">
        <p>Venues must:</p>
        <ul>
          <li>keep their profile, hours, contact details, and offers accurate;</li>
          <li>honour published offers and train staff on the redemption screen;</li>
          <li>
            comply with liquor, accessibility, consumer protection, advertising,
            privacy, employment, and other applicable laws;
          </li>
          <li>
            not use Outly data or offers to discriminate, identify individuals from
            aggregate reports, or contact consumers outside the service; and
          </li>
          <li>
            obtain permission for content, logos, photos, and claims submitted to
            Outly.
          </li>
        </ul>
        <p>
          Outly may review, reject, pause, or remove a venue listing or offer to
          protect users, meet partner requirements, or maintain service quality.
        </p>
      </LegalSection>

      <LegalSection title="5. Venue subscriptions">
        <p>
          Venue plans may include Free and paid Pro options. Features, limits, fees,
          taxes, and billing intervals are shown before purchase and may change
          prospectively with notice.
        </p>
        <p>
          Paid subscriptions are processed by Stripe and renew automatically for the
          selected billing period until cancelled. An authorized venue user can
          manage or cancel a subscription through dashboard billing settings. Unless
          stated otherwise, cancellation takes effect at the end of the current paid
          period and partial-period refunds are not provided, except where required
          by law. Failed or reversed payment may result in reduced or suspended paid
          access.
        </p>
      </LegalSection>

      <LegalSection title="6. Acceptable use">
        <p>You may not:</p>
        <ul>
          <li>break the law, threaten, harass, or endanger another person;</li>
          <li>
            manipulate plans, check-ins, claims, analytics, eligibility, or billing;
          </li>
          <li>
            scrape, resell, reverse engineer, overload, probe, or interfere with the
            service or its security;
          </li>
          <li>use automated accounts or access another person’s account; or</li>
          <li>
            copy, use, or distribute Outly content except as the service permits.
          </li>
        </ul>
      </LegalSection>

      <LegalSection title="7. Safety and third parties">
        <p>
          Outly helps people choose venues; it is not a dating service, venue
          operator, transportation provider, emergency service, or personal safety
          service. We do not screen venue guests or guarantee that you will meet
          anyone. Use your judgment, follow venue rules, drink responsibly, and plan
          safe transportation.
        </p>
        <p>
          Maps, payment pages, sign-in providers, partner apps, venue websites, and
          other third-party services have their own terms and policies. Outly is not
          responsible for third-party services or conduct outside its control.
        </p>
      </LegalSection>

      <LegalSection title="8. Content and intellectual property">
        <p>
          Outly and its licensors own the service, software, design, trademarks, and
          other Outly content. We grant you a limited, revocable, non-transferable
          right to use the service for its intended purpose.
        </p>
        <p>
          You keep ownership of content you submit. You grant Outly a worldwide,
          non-exclusive, royalty-free licence to host, reproduce, adapt, display,
          and distribute it only as needed to operate, market, and improve the
          service. This licence ends when the content is removed, except for copies
          reasonably retained in backups, legal records, or materials already
          produced with permission.
        </p>
      </LegalSection>

      <LegalSection title="9. Suspension and deletion">
        <p>
          You may stop using Outly and request account deletion through the app or
          dashboard. A venue must cancel any active paid subscription before its
          account can be deleted. We may restrict, suspend, or terminate access for a
          breach of these terms, fraud, safety or legal risk, non-payment, or misuse.
          Where appropriate, we will provide notice and a chance to contact support.
        </p>
      </LegalSection>

      <LegalSection title="10. Service availability and disclaimers">
        <p>
          Outly is provided “as is” and “as available.” To the extent permitted by
          law, we disclaim implied warranties, including merchantability, fitness for
          a particular purpose, and non-infringement. We do not promise uninterrupted
          service or guarantee crowd estimates, venue information, check-in results,
          offers, attendance, partner benefits, or commercial results.
        </p>
        <p>
          Nothing in these terms limits a warranty or consumer right that cannot
          lawfully be excluded.
        </p>
      </LegalSection>

      <LegalSection title="11. Limitation of liability">
        <p>
          To the maximum extent permitted by law, Outly Labs Inc. and its directors,
          officers, employees, and agents will not be liable for indirect,
          incidental, special, consequential, exemplary, or punitive damages, or for
          lost profits, data, goodwill, or opportunities arising from the service.
        </p>
        <p>
          Our total liability for claims relating to the service will not exceed the
          greater of CAD $100 and the amount you paid Outly in the 12 months before
          the event giving rise to the claim. These limits do not apply where the law
          does not permit them.
        </p>
      </LegalSection>

      <LegalSection title="12. Responsibility for misuse">
        <p>
          If you use Outly on behalf of a business, that business will defend and
          indemnify Outly against third-party claims, losses, and reasonable costs
          arising from its submitted content, offers, legal violations, or breach of
          these terms. This does not apply to the extent a claim was caused by
          Outly’s own conduct.
        </p>
      </LegalSection>

      <LegalSection title="13. Governing law and changes">
        <p>
          These terms are governed by the laws of Ontario and the federal laws of
          Canada applicable there. Courts located in Toronto, Ontario will have
          jurisdiction, subject to any rights that applicable consumer law does not
          allow you to waive.
        </p>
        <p>
          We may update these terms as the service changes. We will post the revised
          date and give additional notice for material changes. Continued use after
          the effective date means you accept the updated terms.
        </p>
      </LegalSection>

      <LegalSection title="14. Contact">
        <p>
          Questions about these terms can be sent to{" "}
          <a href="mailto:admin@getoutly.app">admin@getoutly.app</a>. Outly Labs Inc.
          is based in Toronto, Ontario, Canada.
        </p>
      </LegalSection>
    </LegalPage>
  );
}
