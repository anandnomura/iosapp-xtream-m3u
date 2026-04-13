# TestFlight Delivery

This repo now includes a minimal iPhone app scaffold and a working GitHub Actions workflow for TestFlight uploads.

## Current release identifiers

- App name: `1xtream-m3u`
- iOS bundle identifier: `com.bl.1xtream-m3u`
- Apple Team ID: `QAXZVV2HVR`
- Xcode scheme: `OneXtreamM3U`
- Project file generated in CI: `OneXtreamM3U.xcodeproj`
- Upload workflow: `.github/workflows/ios-testflight.yml`

## What is in place

- A minimal SwiftUI iOS app generated with `XcodeGen`
- Real source onboarding for:
  - `M3U URL`
  - raw `M3U` text paste
  - `Xtream` host, username, and password
- Live channel browsing by loaded groups
- Signing hooks for GitHub-hosted macOS runners
- Manual TestFlight workflow at `.github/workflows/ios-testflight.yml`
- Successful archive and export from GitHub Actions
- Workflow artifact retention for the generated `.ipa` and release diagnostics

## GitHub repository secrets actually used

These are the exact secret names used by the TestFlight workflow:

- `APPLE_TEAM_ID`
- `BUILD_CERTIFICATE_BASE64`
- `P12_PASSWORD`
- `BUILD_PROVISION_PROFILE_BASE64`
- `KEYCHAIN_PASSWORD`
- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_PRIVATE_KEY`

## What each secret contains

- `APPLE_TEAM_ID`
  - Apple Developer Team ID
  - Current value used for this app: `QAXZVV2HVR`
- `BUILD_CERTIFICATE_BASE64`
  - Base64-encoded contents of the exported Apple Distribution `.p12` certificate
- `P12_PASSWORD`
  - Password used when exporting the `.p12` certificate
- `BUILD_PROVISION_PROFILE_BASE64`
  - Base64-encoded contents of the iOS App Store Connect `.mobileprovision` profile
- `KEYCHAIN_PASSWORD`
  - Temporary password used by CI when creating its ephemeral macOS keychain
- `APP_STORE_CONNECT_KEY_ID`
  - App Store Connect API key ID
- `APP_STORE_CONNECT_ISSUER_ID`
  - App Store Connect API issuer ID
- `APP_STORE_CONNECT_PRIVATE_KEY`
  - Full text contents of the App Store Connect `.p8` private key
  - Store the raw multi-line private key text, not base64

## Manual Apple-side artifacts that were created

These are not stored in git and should remain local or in GitHub Secrets only:

- Apple Distribution certificate export: `.p12`
- Distribution certificate file: `.cer`
- Certificate signing request: `.csr`
- App Store Connect provisioning profile: `.mobileprovision`
- App Store Connect API key: `.p8`

## Local sensitive files currently ignored by git

The repo `.gitignore` intentionally blocks these patterns:

- `*.p12`
- `*.cer`
- `*.csr`
- `*.mobileprovision`
- `*.p8`
- `private.key`

## Workflow variables and values currently hard-coded in CI

These values are referenced by the iOS upload workflow:

- `PRODUCT_BUNDLE_IDENTIFIER="com.bl.1xtream-m3u"`
- `CODE_SIGN_IDENTITY="Apple Distribution"`
- `scheme: OneXtreamM3U`
- `archivePath: $RUNNER_TEMP/OneXtreamM3U.xcarchive`
- export method: `app-store`
- generated IPA filename: `1xtream-m3u.ipa`

## Version metadata requirement

The upload flow is sensitive to the packaged app metadata types:

- `CFBundleVersion` must be packaged as a string
- `CFBundleShortVersionString` must be packaged as a string

This repo now enforces that by:

- keeping the version keys in [App/Info.plist](/c:/Users/anand/Downloads/pypgms/iosapp/App/Info.plist)
- using plist placeholders like `$(CURRENT_PROJECT_VERSION)` and `$(MARKETING_VERSION)`
- avoiding numeric injection of those keys from [project.yml](/c:/Users/anand/Downloads/pypgms/iosapp/project.yml)

For TestFlight uploads in CI:

- `CFBundleShortVersionString` is currently stamped to `1.0`
- `CFBundleVersion` is stamped from `GITHUB_RUN_NUMBER`

That means every workflow run should produce a higher build number automatically.

## Workflow artifacts created on every run

The workflow now preserves these artifacts even if the upload step fails:

- `1xtream-m3u-ipa-<run_number>`
  - contains the exported `1xtream-m3u.ipa`
- `1xtream-m3u-diagnostics-<run_number>`
  - contains:
    - `archive.log`
    - `export.log`
    - `altool-upload.log`
    - `App-Info.plist`
    - `Archive-Info.plist`
    - `ExportOptions.plist`
    - `DistributionSummary.plist`
    - `Packaging.log`
    - `bundle_id.txt`
    - `version.txt`
    - `build_number.txt`
    - `ipa-sha256.txt`
    - `export-directory.txt`

## Triggering the workflow

1. Open the GitHub repository
2. Open `Actions`
3. Choose `iOS TestFlight`
4. Click `Run workflow`
5. After it finishes, open the run and download:
   - the `.ipa` artifact if you want to upload manually from a Mac
   - the diagnostics artifact if the build still does not appear in TestFlight

## What the workflow does

1. Checks out the repo
2. Selects the latest stable Xcode
3. Installs `XcodeGen`
4. Generates `OneXtreamM3U.xcodeproj` from `project.yml`
5. Installs the signing certificate and provisioning profile from secrets
6. Writes the App Store Connect API key to the runner
7. Archives the app with distribution signing
8. Exports the `.ipa`
9. Uploads the build to TestFlight with `altool`
10. Saves the `.ipa` and release diagnostics as downloadable workflow artifacts

## Important current limitation

This is now an MVP-in-progress build with working onboarding and channel loading, while deeper playback and persistence work continue.

The app does not yet include:

- VLC playback
- actual video player UI
- favorites and recents persistence
- Keychain credential storage
- SwiftData-backed profile management
- tvOS target delivery
