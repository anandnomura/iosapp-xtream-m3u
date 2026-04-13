# TestFlight Delivery

This repo now includes a minimal iPhone app scaffold and a manual GitHub Actions workflow for TestFlight uploads.

## What is in place

- A minimal SwiftUI iOS app generated with `XcodeGen`
- Signing hooks for GitHub-hosted macOS runners
- Manual TestFlight workflow at `.github/workflows/ios-testflight.yml`

## Required GitHub secrets

- `APPLE_TEAM_ID`
- `BUILD_CERTIFICATE_BASE64`
- `P12_PASSWORD`
- `BUILD_PROVISION_PROFILE_BASE64`
- `KEYCHAIN_PASSWORD`
- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_PRIVATE_KEY`

## Triggering the workflow

1. Open the GitHub repository
2. Open `Actions`
3. Choose `iOS TestFlight`
4. Click `Run workflow`

## Important current limitation

This is a first-pass delivery shell meant to prove the signing and upload pipeline.

The app currently shows sample playlist content from the shared package. It does not yet include:

- provider onboarding
- real M3U import
- Xtream login
- video playback
- tvOS delivery
