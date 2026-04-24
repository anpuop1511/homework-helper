import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY);

function escapeHtml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function buildEmailLayout({ title, headline, body, ctaText, ctaUrl, footer }) {
  const safeTitle = escapeHtml(title);
  const safeHeadline = escapeHtml(headline);
  const safeBody = escapeHtml(body);
  const safeCtaText = escapeHtml(ctaText);
  const safeCtaUrl = escapeHtml(ctaUrl);
  const safeFooter = escapeHtml(footer);

  return `
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>${safeTitle}</title>
    <style>
      body {
        margin: 0;
        padding: 0;
        background: #f6f8fc;
        font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        color: #0f172a;
      }

      .container {
        width: 100%;
        padding: 40px 16px;
      }

      .card {
        max-width: 640px;
        margin: 0 auto;
        background: #ffffff;
        border: 1px solid #dbe3f0;
        border-radius: 24px;
        overflow: hidden;
        box-shadow: 0 24px 80px rgba(15, 23, 42, 0.08);
      }

      .hero {
        padding: 40px;
        background: linear-gradient(180deg, rgba(0, 127, 255, 0.12), transparent);
      }

      .brand {
        display: inline-block;
        padding: 8px 12px;
        border-radius: 999px;
        background: rgba(0, 127, 255, 0.1);
        color: #005fcc;
        font-size: 12px;
        font-weight: 700;
        letter-spacing: 0.08em;
        text-transform: uppercase;
      }

      h1 {
        margin: 18px 0 12px;
        font-size: 32px;
        line-height: 1.1;
        letter-spacing: -0.04em;
      }

      p {
        margin: 0;
        font-size: 16px;
        line-height: 1.7;
        color: #5b6478;
      }

      .content {
        padding: 0 40px 40px;
      }

      .button {
        display: inline-block;
        margin: 28px 0 20px;
        padding: 16px 24px;
        border-radius: 14px;
        background: linear-gradient(180deg, #007fff, #005fcc);
        color: #fff !important;
        text-decoration: none;
        font-weight: 700;
        font-size: 15px;
      }

      .footnote {
        padding: 18px 40px 36px;
        border-top: 1px solid #dbe3f0;
        font-size: 12px;
        color: #7b8496;
      }

      @media (max-width: 640px) {
        .hero,
        .content,
        .footnote {
          padding-left: 24px;
          padding-right: 24px;
        }

        h1 {
          font-size: 28px;
        }
      }
    </style>
  </head>
  <body>
    <div class="container">
      <div class="card">
        <div class="hero">
          <span class="brand">HwHelper.tech</span>
          <h1>${safeHeadline}</h1>
          <p>${safeBody}</p>
        </div>
        <div class="content">
          <a class="button" href="${safeCtaUrl}">${safeCtaText}</a>
          <p>If the button does not work, copy this link into your browser:</p>
          <p style="word-break: break-word; margin-top: 12px; color: #005fcc;">${safeCtaUrl}</p>
        </div>
        <div class="footnote">${safeFooter}</div>
      </div>
    </div>
  </body>
</html>`;
}

export async function sendVerificationEmail({ to, verifyUrl }) {
  return resend.emails.send({
    from: 'Homework Helper <no-reply@hwhelper.tech>',
    to,
    subject: 'Verify your Homework Helper email',
    html: buildEmailLayout({
      title: 'Verify your email',
      headline: 'Verify your email to finish setting up your account.',
      body: 'Click the button below to confirm this email address and keep your account secure.',
      ctaText: 'Verify Email',
      ctaUrl: verifyUrl,
      footer:
        'If you did not create a Homework Helper account, you can ignore this email.',
    }),
  });
}

export async function sendPasswordResetEmail({ to, resetUrl }) {
  return resend.emails.send({
    from: 'Homework Helper <no-reply@hwhelper.tech>',
    to,
    subject: 'Reset your Homework Helper password',
    html: buildEmailLayout({
      title: 'Reset your password',
      headline: 'Reset your password securely.',
      body: 'Use the button below to choose a new password for your account.',
      ctaText: 'Reset Password',
      ctaUrl: resetUrl,
      footer:
        'If you did not request a password reset, you can ignore this email.',
    }),
  });
}
