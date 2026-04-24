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

function buildEmailLayout({
  title,
  headline,
  greeting,
  body,
  ctaText,
  ctaUrl,
  footer,
}) {
  const safeTitle = escapeHtml(title);
  const safeHeadline = escapeHtml(headline);
  const safeGreeting = greeting ? escapeHtml(greeting) : '';
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
      :root {
        color-scheme: light;
      }

      body {
        margin: 0;
        padding: 0;
        background:
          radial-gradient(circle at top left, rgba(53, 89, 224, 0.12), transparent 30%),
          radial-gradient(circle at top right, rgba(33, 150, 243, 0.1), transparent 28%),
          linear-gradient(180deg, #f8f9ff 0%, #f3f5fb 100%);
        font-family: Roboto, Arial, Helvetica, sans-serif;
        color: #10172a;
      }

      .container {
        width: 100%;
        padding: 44px 16px;
      }

      .card {
        max-width: 640px;
        margin: 0 auto;
        background: #ffffff;
        border: 1px solid #d7deef;
        border-radius: 28px;
        overflow: hidden;
        box-shadow: 0 20px 64px rgba(16, 23, 42, 0.12);
      }

      .hero {
        position: relative;
        padding: 42px 40px 28px;
        background:
          linear-gradient(180deg, rgba(53, 89, 224, 0.12), rgba(53, 89, 224, 0.02) 58%, transparent),
          #eef2ff;
      }

      .hero::after {
        content: "";
        position: absolute;
        inset: 18px 18px auto auto;
        width: 120px;
        height: 120px;
        border-radius: 50%;
        background: radial-gradient(circle, rgba(53, 89, 224, 0.14), transparent 68%);
      }

      .brand {
        display: inline-block;
        padding: 8px 14px;
        border-radius: 999px;
        background: rgba(53, 89, 224, 0.12);
        color: #2442b5;
        font-size: 12px;
        font-weight: 700;
        letter-spacing: 0.12em;
        text-transform: uppercase;
      }

      h1 {
        margin: 18px 0 12px;
        font-size: 32px;
        line-height: 1.12;
        letter-spacing: -0.03em;
      }

      p {
        margin: 0;
        font-size: 15px;
        line-height: 1.75;
        color: #55607a;
      }

      .content {
        padding: 0 40px 40px;
      }

      .supporting-card {
        margin-top: 18px;
        padding: 16px 18px;
        border-radius: 18px;
        background: #f8faff;
        border: 1px solid #d7deef;
      }

      .button {
        display: inline-block;
        margin: 28px 0 20px;
        padding: 16px 26px;
        border-radius: 999px;
        background: linear-gradient(180deg, #3559e0, #2442b5);
        color: #fff !important;
        text-decoration: none;
        font-weight: 700;
        font-size: 15px;
        letter-spacing: 0.01em;
        box-shadow: 0 12px 24px rgba(53, 89, 224, 0.28);
      }

      .footnote {
        padding: 18px 40px 36px;
        border-top: 1px solid #d7deef;
        font-size: 12px;
        color: #6b7489;
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

        .hero::after {
          width: 92px;
          height: 92px;
        }
      }
    </style>
  </head>
  <body>
    <div class="container">
      <div class="card">
        <div class="hero">
          <span class="brand">HwHelper.tech</span>
          ${safeGreeting ? `<p style="margin-top: 18px; color: #2442b5; font-weight: 700;">${safeGreeting}</p>` : ''}
          <h1>${safeHeadline}</h1>
          <p>${safeBody}</p>
        </div>
        <div class="content">
          <a class="button" href="${safeCtaUrl}">${safeCtaText}</a>
          <div class="supporting-card">
            <p>If the button does not work, copy this link into your browser:</p>
            <p style="word-break: break-word; margin-top: 12px; color: #2442b5;">${safeCtaUrl}</p>
          </div>
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
      greeting: 'Hi there,',
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
      greeting: 'Hi there,',
      headline: 'Reset your password securely.',
      body: 'Use the button below to choose a new password for your account.',
      ctaText: 'Reset Password',
      ctaUrl: resetUrl,
      footer:
        'If you did not request a password reset, you can ignore this email.',
    }),
  });
}
