# Manual Release Checklist

This file records the manual setup that was created outside git so the release pipeline can be rebuilt later without guessing.

## Apple app record

- App name: `1xtream-m3u`
- iOS bundle ID: `com.bl.1xtream-m3u`
- Team ID: `QAXZVV2HVR`

## Manual Apple-side items created

- Apple Distribution certificate
- Exported `.p12` certificate package
- Certificate signing request `.csr`
- iOS App Store Connect provisioning profile
- App Store Connect API key

## Manual local files created during setup

These were created locally and must not be committed:

- `distribution.cer`
- `distribution.p12`
- `request.csr`
- `1xtreamipappprofile.mobileprovision`
- `.p8` App Store Connect API key file
- `private.key`

## GitHub repository secrets that must exist

- `APPLE_TEAM_ID`
- `BUILD_CERTIFICATE_BASE64`
- `P12_PASSWORD`
- `BUILD_PROVISION_PROFILE_BASE64`
- `KEYCHAIN_PASSWORD`
- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_PRIVATE_KEY`

## How those secrets map to local artifacts

- `APPLE_TEAM_ID`
  - Value: `QAXZVV2HVR`
- `BUILD_CERTIFICATE_BASE64`
  - Source: base64 of `distribution.p12`
- `P12_PASSWORD`
  - Source: password chosen when exporting `distribution.p12`
- `BUILD_PROVISION_PROFILE_BASE64`
  - Source: base64 of `1xtreamipappprofile.mobileprovision`
- `KEYCHAIN_PASSWORD`
  - Source: random CI-only password chosen manually
- `APP_STORE_CONNECT_KEY_ID`
  - Source: App Store Connect API key metadata
- `APP_STORE_CONNECT_ISSUER_ID`
  - Source: App Store Connect API key metadata
- `APP_STORE_CONNECT_PRIVATE_KEY`
  - Source: contents of the downloaded `.p8` file

## Repo files that depend on this setup

- [project.yml](/c:/Users/anand/Downloads/pypgms/iosapp/project.yml)
- [.github/workflows/ios-testflight.yml](/c:/Users/anand/Downloads/pypgms/iosapp/.github/workflows/ios-testflight.yml)
- [scripts/ci/install_signing_assets.sh](/c:/Users/anand/Downloads/pypgms/iosapp/scripts/ci/install_signing_assets.sh)
- [scripts/ci/write_export_options.sh](/c:/Users/anand/Downloads/pypgms/iosapp/scripts/ci/write_export_options.sh)

## Current iPhone release path

1. Push app changes to `main`
2. Run the `iOS TestFlight` workflow
3. Download the workflow artifacts:
   - `1xtream-m3u-ipa-<run_number>`
   - `1xtream-m3u-diagnostics-<run_number>`
4. If the build does not appear in App Store Connect, inspect:
   - `transporter-upload.log`
   - `DistributionSummary.plist`
   - `Packaging.log`
   - `bundle_id.txt`
   - `version.txt`
   - `build_number.txt`
5. If needed, copy the `.ipa` to a Mac and upload it manually with Apple Transporter
6. Wait for App Store Connect processing
7. Assign the processed build to internal TestFlight testers
