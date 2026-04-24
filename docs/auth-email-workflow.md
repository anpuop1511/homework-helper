# Auth Email Workflow

## Firebase Console checklist

1. Open Firebase Console for the project.
2. Go to Authentication -> Sign-in method.
3. Enable Email/Password.
4. In Authentication -> Templates, open each template you plan to use:
   - Email verification
   - Password reset
5. Set the action URL to:
   - https://hwhelper.tech/auth-handler
6. Keep the Flutter app set to handle the code in-app.
7. Add `hwhelper.tech` to Authentication -> Settings -> Authorized domains.
8. If you are using a custom SMTP server, enter the Resend SMTP settings below.

## Firebase SMTP settings for Resend

Use these values in Firebase Console -> Authentication -> Templates -> SMTP:

- SMTP host: smtp.resend.com
- Port: 465
- Username: resend
- Password: your Resend SMTP API key
- Security: SSL

If Firebase asks for a sender address, use a verified sender on your Resend domain, such as `no-reply@hwhelper.tech`.

## DNS records to add in Vercel for Resend

Resend generates the exact DNS values for your domain inside the Resend dashboard. Add the records it gives you in Vercel DNS. The usual record set is:

- 1 SPF TXT record for the root domain, usually `v=spf1 include:resend.com ~all`
- 2 DKIM CNAME records supplied by Resend
- Optional DMARC TXT record for `._dmarc.hwhelper.tech`

Important:

- Keep only one SPF TXT record per domain.
- If you already have an SPF record, merge Resend into the existing TXT value.
- Copy the exact hostnames and targets from the Resend domain screen; they are domain-specific.

## Web app routing

- Verification links can be opened directly in the Flutter app.
- Password reset links open the in-app reset screen, where the user enters a new password and the app calls `confirmPasswordReset`.
- Verification links automatically call `applyActionCode` and then refresh the signed-in user.

## Resend email layout in JavaScript

If you want to build the email entirely in JavaScript, use [docs/email_templates/resend_email_layout.js](docs/email_templates/resend_email_layout.js) as the pattern:

- Create one function that returns a full HTML string.
- Pass the HTML into `resend.emails.send({ html: ... })`.
- Keep the email responsive with a single-column card, strong headline, and one CTA button.
- Reuse the same layout function for both verification and password reset messages.

## What you need to do on your side

1. Create or verify the `hwhelper.tech` sender domain in Resend.
2. Copy the exact SPF/DKIM DNS records from Resend into Vercel DNS.
3. Paste the SMTP credentials into Firebase Auth email templates.
4. Make sure `hwhelper.tech` is in Firebase Authorized Domains.
5. Deploy the Flutter web app so `https://hwhelper.tech/auth-handler` serves this app.
6. Send one verification email and one password reset email to confirm the full flow.