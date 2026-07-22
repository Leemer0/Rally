interface WelcomeEmailInput {
  userId: string;
  email: string;
  firstName: string;
}

function escapeHtml(value: string) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

export async function sendConsumerWelcomeEmail(input: WelcomeEmailInput) {
  const apiKey = Deno.env.get("RESEND_API_KEY")?.trim();
  if (!apiKey || !input.email) return;

  const from = Deno.env.get("OUTLY_EMAIL_FROM")?.trim() ||
    "Outly <no-reply@getoutly.app>";
  const replyTo = Deno.env.get("OUTLY_EMAIL_REPLY_TO")?.trim() ||
    "admin@getoutly.app";
  const firstName = escapeHtml(input.firstName);
  const siteUrl = Deno.env.get("OUTLY_SITE_URL")?.trim() ||
    "https://www.getoutly.app";

  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
      "Idempotency-Key": `consumer-welcome-${input.userId}`,
    },
    body: JSON.stringify({
      from,
      to: [input.email],
      reply_to: replyTo,
      subject: "Welcome to Outly",
      text:
        `Welcome to Outly, ${input.firstName}.\n\nSee where Toronto is going tonight, choose a venue, and meet there in real life.\n\n${siteUrl}`,
      html: `<!doctype html>
<html lang="en"><body style="margin:0;background:#080b10;color:#f7f7f2;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Arial,sans-serif">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#080b10"><tr><td align="center" style="padding:40px 18px">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:560px;border:1px solid #252a31;background:#0d1117">
<tr><td style="padding:28px 32px 24px;border-bottom:1px solid #252a31"><img src="https://www.getoutly.app/brand/winged-o.png" width="64" alt="Outly" style="display:block;width:64px;height:auto;border:0"></td></tr>
<tr><td style="padding:36px 32px 40px"><p style="margin:0 0 16px;color:#b8ff2c;font-family:Menlo,Consolas,monospace;font-size:11px;letter-spacing:2px;text-transform:uppercase">Welcome to Outly</p>
<h1 style="margin:0;color:#f7f7f2;font-size:34px;line-height:1.08;letter-spacing:-1px;font-weight:600">You’re in, ${firstName}.</h1>
<p style="margin:20px 0 0;color:#a4a8ae;font-size:16px;line-height:1.65">See where Toronto is going tonight, choose a venue, and meet there in real life.</p>
<table role="presentation" cellspacing="0" cellpadding="0" style="margin-top:30px"><tr><td bgcolor="#b8ff2c" style="border-radius:5px"><a href="${siteUrl}" style="display:inline-block;padding:14px 22px;color:#080b10;font-size:15px;font-weight:650;text-decoration:none">See Outly</a></td></tr></table></td></tr>
<tr><td style="padding:22px 32px;border-top:1px solid #252a31;color:#666c74;font-size:12px;line-height:1.6">Outly · Toronto, Canada<br>admin@getoutly.app</td></tr>
</table></td></tr></table></body></html>`,
    }),
    signal: AbortSignal.timeout(4_000),
  });

  if (!response.ok) {
    throw new Error(`Resend returned ${response.status}.`);
  }
}

