import "server-only";

import { Resend } from "resend";
import { getSiteUrl } from "@/lib/supabase/config";

const BRAND_GREEN = "#b8ff2c";
const BRAND_BLACK = "#080b10";

function escapeHtml(value: string) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function emailDocument({
  preview,
  eyebrow,
  title,
  body,
  ctaLabel,
  ctaUrl,
}: {
  preview: string;
  eyebrow: string;
  title: string;
  body: string;
  ctaLabel: string;
  ctaUrl: string;
}) {
  return `<!doctype html>
<html lang="en">
  <head><meta charset="utf-8"><meta name="viewport" content="width=device-width"></head>
  <body style="margin:0;background:${BRAND_BLACK};color:#f7f7f2;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Arial,sans-serif">
    <div style="display:none;max-height:0;overflow:hidden;opacity:0">${escapeHtml(preview)}</div>
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:${BRAND_BLACK}">
      <tr><td align="center" style="padding:40px 18px">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:560px;border:1px solid #252a31;background:#0d1117">
          <tr><td style="padding:28px 32px 24px;border-bottom:1px solid #252a31">
            <img src="https://www.getoutly.app/brand/winged-o.png" width="64" alt="Outly" style="display:block;width:64px;height:auto;border:0">
          </td></tr>
          <tr><td style="padding:36px 32px 40px">
            <p style="margin:0 0 16px;color:${BRAND_GREEN};font-family:Menlo,Consolas,monospace;font-size:11px;letter-spacing:2px;text-transform:uppercase">${escapeHtml(eyebrow)}</p>
            <h1 style="margin:0;color:#f7f7f2;font-size:34px;line-height:1.08;letter-spacing:-1px;font-weight:600">${escapeHtml(title)}</h1>
            <p style="margin:20px 0 0;color:#a4a8ae;font-size:16px;line-height:1.65">${escapeHtml(body)}</p>
            <table role="presentation" cellspacing="0" cellpadding="0" style="margin-top:30px"><tr><td bgcolor="${BRAND_GREEN}" style="border-radius:5px">
              <a href="${escapeHtml(ctaUrl)}" style="display:inline-block;padding:14px 22px;color:#080b10;font-size:15px;font-weight:650;text-decoration:none">${escapeHtml(ctaLabel)}</a>
            </td></tr></table>
            <p style="margin:30px 0 0;color:#666c74;font-size:12px;line-height:1.6">If the button doesn’t open, copy this address:<br><a href="${escapeHtml(ctaUrl)}" style="color:#9ca2aa;word-break:break-all">${escapeHtml(ctaUrl)}</a></p>
          </td></tr>
          <tr><td style="padding:22px 32px;border-top:1px solid #252a31;color:#666c74;font-size:12px;line-height:1.6">
            Outly · Toronto, Canada<br>Questions? Reply to this email or contact admin@getoutly.app.
          </td></tr>
        </table>
      </td></tr>
    </table>
  </body>
</html>`;
}

export async function sendVenueApprovedEmail({
  venueId,
  venueName,
  email,
}: {
  venueId: string;
  venueName: string;
  email: string;
}) {
  const apiKey = process.env.RESEND_API_KEY?.trim();
  if (!apiKey || !email) return { sent: false as const };

  const siteUrl = getSiteUrl();
  const from =
    process.env.OUTLY_EMAIL_FROM?.trim() ||
    "Outly <no-reply@getoutly.app>";
  const replyTo =
    process.env.OUTLY_EMAIL_REPLY_TO?.trim() || "admin@getoutly.app";
  const venue = venueName.trim() || "Your venue";
  const dashboardUrl = `${siteUrl}/venue/login?next=/dashboard`;
  const resend = new Resend(apiKey);
  const { error } = await resend.emails.send(
    {
      from,
      to: email,
      replyTo,
      subject: `${venue} is approved on Outly`,
      html: emailDocument({
        preview: `${venue} is approved. Your venue dashboard is ready.`,
        eyebrow: "Venue approved",
        title: "You’re in.",
        body: `${venue} is approved on Outly. Sign in to finish your venue profile, create your first offer, and see how guests engage.`,
        ctaLabel: "Open venue dashboard",
        ctaUrl: dashboardUrl,
      }),
      text: `${venue} is approved on Outly.\n\nSign in to finish your venue profile and create your first offer:\n${dashboardUrl}\n\nQuestions? Contact admin@getoutly.app.`,
    },
    { idempotencyKey: `venue-approved-${venueId}` },
  );

  return { sent: !error };
}

