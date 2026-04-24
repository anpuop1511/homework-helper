# Auth Email Workflow

## Architecture

The Flutter app now calls a Vercel API route, and that backend generates Firebase action links and sends the branded email through Resend. This bypasses Firebase's locked email-template body while keeping Firebase Auth as the source of truth for verification and password-reset actions.

## Repo pieces

- Flutter client service: [lib/services/auth_email_service.dart](lib/services/auth_email_service.dart)
- Vercel backend endpoint: [api/send-auth-email.js](api/send-auth-email.js)
- Shared branded layout: [docs/email_templates/resend_email_layout.js](docs/email_templates/resend_email_layout.js)

## Firebase setup

1. Enable Email/Password in Firebase Authentication.
2. Keep `hwhelper.tech` in Authorized Domains.
3. Do not rely on the Firebase template body for these auth emails anymore.

## Vercel setup

Set these environment variables in your Vercel project:

- `RESEND_API_KEY`
- `RESEND_FROM` (optional), for example `Homework Helper <no-reply@hwhelper.tech>`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY` (paste with `\n` line breaks)

Keep the `hwhelper.tech` domain verified in Resend.

## Endpoint contract

The client posts to `/api/send-auth-email` with:

- `action`: `verifyEmail` or `resetPassword`
- `email`: recipient email
- `displayName`: optional personalization for verification

The endpoint generates the Firebase link with `url: https://hwhelper.tech/` and `handleCodeInApp: true`, then sends the HTML through Resend.

## What you still need to do

1. Deploy the Vercel project that hosts this API route.
2. Set the Vercel environment variables listed above.
3. Run the Flutter web app and test verification and password reset end to end.