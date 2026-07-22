import type { Metadata } from "next";
import { LegalPage, LegalSection } from "@/components/site/legal-page";

export const metadata: Metadata = {
  title: "Privacy Policy",
  description:
    "How Outly collects, uses, shares, and protects information across its nightlife app and venue platform.",
  alternates: { canonical: "/privacy" },
};

export default function PrivacyPage() {
  return (
    <LegalPage
      title="Privacy Policy"
      updated="July 22, 2026"
      summary="This policy explains how Outly Labs Inc. collects, uses, and shares personal information when you use the Outly app, website, or venue dashboard."
    >
      <LegalSection title="1. Information we collect">
        <p>We collect information that is needed to operate Outly:</p>
        <ul>
          <li>
            <strong>Consumer accounts:</strong> email address, first name, sign-in
            provider, self-reported date of birth, gender, and the server-calculated
            result of our 19+ eligibility check.
          </li>
          <li>
            <strong>Plans and activity:</strong> venues you view, your selected
            nightly plan, check-in attempts, verified check-ins, offers you open or
            claim, and related dates and times.
          </li>
          <li>
            <strong>Check-in location:</strong> when you choose to check in, the app
            sends a precise location sample to our server to compare it with the
            venue boundary. We do not store the raw latitude and longitude from that
            sample. We retain the result and supporting measurements, such as
            distance from the venue, accuracy, permission state, and time of the
            attempt, to operate and protect the check-in system.
          </li>
          <li>
            <strong>Venue accounts:</strong> business and representative contact
            details, legal business information, venue profile content, location,
            hours, offers, account approval records, and subscription status.
          </li>
          <li>
            <strong>Technical information:</strong> authentication cookies, IP
            address and server logs, browser or device information, app version,
            push-notification token, and website or app usage events.
          </li>
        </ul>
        <p>
          Payment details are collected and processed by Stripe. Outly does not
          store full payment card numbers. If you sign in through another provider,
          that provider handles your password and sends us the account information
          you authorize it to share.
        </p>
      </LegalSection>

      <LegalSection title="2. How we use information">
        <p>We use personal information to:</p>
        <ul>
          <li>create and secure accounts and confirm 19+ eligibility;</li>
          <li>show venues, crowd context, plans, and available offers;</li>
          <li>verify arrival at a venue and prevent location or offer abuse;</li>
          <li>provide aggregated attendance and campaign analytics to venues;</li>
          <li>operate venue approvals, subscriptions, support, and billing;</li>
          <li>send service messages and, with the required consent, marketing;</li>
          <li>debug, secure, measure, and improve the service; and</li>
          <li>meet legal, tax, accounting, and regulatory obligations.</li>
        </ul>
      </LegalSection>

      <LegalSection title="3. Location and crowd insights">
        <p>
          Precise location is requested when you start a check-in. If you decline
          location access or provide reduced accuracy, you can still browse Outly,
          but you cannot complete a verified check-in or unlock a check-in offer.
          You can change location access in iOS Settings.
        </p>
        <p>
          Venues receive aggregated information such as plan counts, verified
          check-ins, repeat visits, check-in times, and age or gender distributions
          only when group-size safeguards are met. They do not receive a consumer’s
          name, email, date of birth, individual gender, live location, or location
          history through the dashboard.
        </p>
      </LegalSection>

      <LegalSection title="4. When we share information">
        <p>We may share limited information with:</p>
        <ul>
          <li>
            <strong>Service providers</strong> that support hosting,
            authentication, maps, email, analytics, payments, and security,
            including Supabase, Mapbox, Vercel, Resend, Stripe, and enabled sign-in
            providers.
          </li>
          <li>
            <strong>Venues</strong> through the aggregated reporting described
            above.
          </li>
          <li>
            <strong>Campaign partners</strong> through aggregated or de-identified
            performance reporting. We do not give partners consumer names, email
            addresses, or precise location unless we clearly disclose that use and
            obtain any consent required by law.
          </li>
          <li>
            <strong>Authorities or transaction parties</strong> where required by
            law, needed to protect rights and safety, or connected with a financing,
            merger, acquisition, or sale of the business under appropriate
            safeguards.
          </li>
        </ul>
        <p>
          A partner offer may open an external app or website. Information collected
          there is governed by that partner’s privacy policy. Outly does not sell
          personal information.
        </p>
      </LegalSection>

      <LegalSection title="5. Your choices and rights">
        <ul>
          <li>
            You can manage device permissions and opt out of promotional emails at
            any time. We may still send account, security, billing, or offer-service
            messages.
          </li>
          <li>
            You may request access to or correction of your personal information.
            Date of birth is not editable in the app because it controls eligibility;
            contact us if it is incorrect.
          </li>
          <li>
            Consumers can delete their account in the app. Venue accounts can
            request deletion from dashboard settings after cancelling any active
            paid subscription.
          </li>
        </ul>
        <p>
          When a consumer account is deleted, we remove the Auth account, analytics
          tied to it, and push tokens. We detach the user identifier from historical
          plans, check-ins, and claims so non-identifying attendance records can
          remain. We may retain limited records where reasonably required for fraud
          prevention, legal compliance, disputes, or financial reporting.
        </p>
      </LegalSection>

      <LegalSection title="6. Retention and security">
        <p>
          We keep personal information only for as long as needed for the purposes
          in this policy, then delete or anonymize it. Retention depends on the type
          of record, account status, fraud and safety needs, and legal requirements.
        </p>
        <p>
          We use administrative, technical, and organizational safeguards designed
          for the sensitivity of the information. No online service can promise
          absolute security, so please use a unique password and protect your
          account credentials.
        </p>
      </LegalSection>

      <LegalSection title="7. Age requirement">
        <p>
          Outly consumer accounts are for people aged 19 or older. We use a
          self-reported date of birth to calculate eligibility; this is not identity
          or age-document verification. If we learn that an ineligible person
          created an account, we may suspend and delete it.
        </p>
      </LegalSection>

      <LegalSection title="8. Processing outside Canada">
        <p>
          Some service providers process information outside Canada, including in
          the United States. Information in another country may be subject to that
          country’s laws and lawful access by its authorities. Outly remains
          responsible for personal information transferred to providers for
          processing and uses contractual and other safeguards appropriate to the
          service.
        </p>
      </LegalSection>

      <LegalSection title="9. Changes and contact">
        <p>
          We may update this policy as Outly changes. We will post the revised date
          here and give additional notice when a change is material.
        </p>
        <p>
          For access, correction, deletion, or a privacy concern, contact Outly’s
          Privacy Officer at <a href="mailto:admin@getoutly.app">admin@getoutly.app</a>.
          Outly Labs Inc. is based in Toronto, Ontario, Canada. If we cannot resolve
          a concern, you may contact the{" "}
          <a href="https://www.priv.gc.ca/en/report-a-concern/" rel="noreferrer">
            Office of the Privacy Commissioner of Canada
          </a>.
        </p>
      </LegalSection>
    </LegalPage>
  );
}
