# Guidely product site

`index.html` is a standalone marketing site for `myguidely.me`. It is separate from the Flutter app and has no build step or dependencies.

## Before publishing

- [ ] Review and approve the final landing-page copy.
- [ ] Replace the draft Privacy Policy and Terms of Service with legally reviewed text appropriate for Nepal and the countries you serve.
- [ ] Add a real support contact address or support form.
- [ ] Decide where the two main calls to action should link: app download, web app, waitlist, or contact form.
- [ ] Add a favicon, social-share image, and final page title/description.
- [ ] Test on phone, tablet, and desktop.

## Content to keep current

- Guide verification description.
- Booking and payment wording.
- Support contact details.
- Privacy Policy and Terms of Service effective date.
- FAQ answers.

## Deployment later

1. Create a static-site project with a host such as Netlify or Cloudflare Pages.
2. Deploy the contents of this `site/` folder; `index.html` must be the published entry file.
3. Connect `myguidely.me` in the host dashboard.
4. Add the DNS records shown by that host in Namecheap.
5. Enable HTTPS and test `https://myguidely.me` and `https://www.myguidely.me`.

## Nice-to-have later

- App Store / Play Store download buttons.
- Screenshots of the Guidely mobile app.
- Contact form backed by your support inbox.
- Analytics only after adding a consent notice if required for your audience.
- A dedicated `/privacy` and `/terms` page if the legal text becomes longer.
