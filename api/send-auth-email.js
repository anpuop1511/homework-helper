const { Resend } = require('resend');
const admin = require('firebase-admin');

const resend = new Resend(process.env.RESEND_API_KEY);
const fromAddress =
  process.env.RESEND_FROM || 'Homework Helper <no-reply@hwhelper.tech>';
const authHandlerUrl = 'https://www.hwhelper.tech/app';

function initializeFirebaseAdmin() {
  if (admin.apps.length > 0) return;

  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');

  if (!projectId || !clientEmail || !privateKey) {
    throw new Error(
      'Missing Firebase Admin credentials. Set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, and FIREBASE_PRIVATE_KEY.',
    );
  }

  admin.initializeApp({
    credential: admin.credential.cert({
      projectId,
      clientEmail,
      privateKey,
    }),
  });
}

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
  greeting,
  headline,
  body,
  ctaText,
  ctaUrl,
  footer,
}) {
  const safeTitle = escapeHtml(title);
  const safeGreeting = greeting ? escapeHtml(greeting) : '';
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
      * {
        box-sizing: border-box;
      }

      body {
        margin: 0;
        padding: 0;
        background-color: #edf1fb;
        background-image:
          radial-gradient(circle at top left, rgba(53, 89, 224, 0.14), transparent 30%),
          radial-gradient(circle at top right, rgba(33, 150, 243, 0.1), transparent 28%),
          linear-gradient(180deg, #f8faff 0%, #edf1fb 100%);
        font-family: Roboto, Arial, Helvetica, sans-serif;
        color: #10172a;
      }

      .container {
        width: 100%;
        padding: 32px 16px;
      }

      .card {
        max-width: 640px;
        margin: 0 auto;
        background: #ffffff;
        border: 1px solid #d7deef;
        border-radius: 30px;
        overflow: hidden;
        box-shadow: 0 18px 60px rgba(16, 23, 42, 0.12);
      }

      .hero {
        position: relative;
        padding: 36px 40px 30px;
        background:
          linear-gradient(180deg, rgba(53, 89, 224, 0.12), rgba(53, 89, 224, 0.03) 58%, transparent),
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
        margin: 16px 0 12px;
        font-size: 32px;
        line-height: 1.1;
        letter-spacing: -0.03em;
      }

      p {
        margin: 0;
        font-size: 15px;
        line-height: 1.7;
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

      .supporting-card p {
        font-size: 13px;
        line-height: 1.6;
      }

      .button {
        display: block;
        width: 100%;
        margin: 28px 0 18px;
        padding: 16px 24px;
        border-radius: 999px;
        background: linear-gradient(180deg, #3559e0, #2442b5);
        color: #fff !important;
        text-decoration: none;
        font-weight: 700;
        font-size: 15px;
        line-height: 1;
        letter-spacing: 0.01em;
        text-align: center;
        box-shadow: 0 12px 24px rgba(53, 89, 224, 0.28);
      }

      .footnote {
        padding: 18px 40px 36px;
        border-top: 1px solid #d7deef;
        font-size: 12px;
        line-height: 1.6;
        color: #6b7489;
      }

      .link-text {
        word-break: break-word;
        margin-top: 12px;
        color: #2442b5;
        font-size: 13px;
      }

      @media only screen and (max-width: 640px) {
        .container {
          padding: 12px;
        }

        .hero,
        .content,
        .footnote {
          padding-left: 20px;
          padding-right: 20px;
        }

        .hero {
          padding-top: 28px;
          padding-bottom: 24px;
        }

        h1 {
          font-size: 26px;
        }

        p {
          font-size: 14px;
          line-height: 1.65;
        }

        .button {
          margin-top: 22px;
          padding: 15px 20px;
          font-size: 14px;
        }

        .supporting-card {
          padding: 14px 16px;
        }

        .hero::after {
          width: 88px;
          height: 88px;
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
            <p class="link-text">${safeCtaUrl}</p>
          </div>
        </div>
        <div class="footnote">${safeFooter}</div>
      </div>
    </div>
  </body>
</html>`;
}

async function sendAuthEmail({ to, action, displayName }) {
  const email = String(to || '').trim();
  if (!email) throw new Error('Email is required.');

  initializeFirebaseAdmin();
  const auth = admin.auth();
  const actionCodeSettings = {
    url: authHandlerUrl,
    handleCodeInApp: true,
  };

  let link;
  let subject;
  let title;
  let headline;
  let body;
  let ctaText;
  let footer;

  if (action === 'verifyEmail') {
    link = await auth.generateEmailVerificationLink(email, actionCodeSettings);
    subject = 'Verify your Homework Helper email';
    title = 'Verify your email';
    headline = 'Verify your email to finish setting up your account.';
    body = 'Click the button below to confirm this email address and keep your account secure.';
    ctaText = 'Verify Email';
    footer = 'If you did not create a Homework Helper account, you can ignore this email.';
  } else if (action === 'resetPassword') {
    link = await auth.generatePasswordResetLink(email, actionCodeSettings);
    subject = 'Reset your Homework Helper password';
    title = 'Reset your password';
    headline = 'Reset your password securely.';
    body = 'Use the button below to choose a new password for your account.';
    ctaText = 'Reset Password';
    footer = 'If you did not request a password reset, you can ignore this email.';
  } else {
    throw new Error('Unsupported action.');
  }

  const greetingName = displayName ? `Hi ${displayName},` : 'Hi there,';

  await resend.emails.send({
    from: fromAddress,
    to: [email],
    subject,
    html: buildEmailLayout({
      title,
      greeting: greetingName,
      headline,
      body,
      ctaText,
      ctaUrl: link,
      footer,
    }),
  });
}

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'method-not-allowed' });
    return;
  }

  try {
    const { action, email, displayName } = req.body || {};
    if (!action || !email) {
      res.status(400).json({ error: 'action-and-email-required' });
      return;
    }

    await sendAuthEmail({ action, to: email, displayName });
    res.json({ ok: true });
  } catch (error) {
    console.error('[send-auth-email] failed:', error);
    res.status(500).json({
      error: 'send-failed',
      message: error instanceof Error ? error.message : String(error),
    });
  }
};
