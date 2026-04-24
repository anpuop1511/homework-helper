# Auth Email Workflow

## Architecture

The Flutter app now calls a small Firebase Functions endpoint, and that backend generates the Firebase action links and sends the branded email through Resend. This bypasses Firebase's locked email-template body while keeping Firebase Auth as the source of truth for verification and password-reset actions.

## Repo pieces

- Flutter client service: [lib/services/auth_email_service.dart](lib/services/auth_email_service.dart)
- Firebase Functions backend: [functions/index.js](functions/index.js)
- Shared branded layout: [docs/email_templates/resend_email_layout.js](docs/email_templates/resend_email_layout.js)

## Firebase setup

1. Enable Email/Password in Firebase Authentication.
2. Keep `hwhelper.tech` in Authorized Domains.
3. Do not rely on the Firebase template body for these auth emails anymore.
4. Deploy the Functions folder with your Firebase project.

## Resend setup

1. Keep the `hwhelper.tech` domain verified in Resend.
2. Set `RESEND_API_KEY` in the Functions environment.
3. Optionally set `RESEND_FROM`, for example `Homework Helper <no-reply@hwhelper.tech>`.

## Functions endpoint

The client posts to `sendAuthEmail` with:

- `action`: `verifyEmail` or `resetPassword`
- `email`: recipient email
- `displayName`: optional personalization for verification

The function generates the Firebase link with `url: https://hwhelper.tech/auth-handler` and `handleCodeInApp: true`, then sends the HTML through Resend.

## What you still need to do

1. Deploy Firebase Functions.
2. Set the Resend env vars for the function.
3. Run the Flutter web app and test verification and password reset end to end.