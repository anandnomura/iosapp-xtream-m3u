# GitHub Actions Setup

This repo now has two GitHub-hosted macOS workflows:

- `Swift Package CI` for package build and tests
- `iOS TestFlight` for signed iPhone archive/export/upload

## What this gives you

- Remote `swift build`
- Remote `swift test`
- Signed iOS archive and TestFlight upload
- A clean macOS signal without needing a local Mac for every build

## What this still does not give you yet

- No interactive Xcode debugging
- No completed tvOS release flow yet
- No local Xcode editing environment

The iPhone TestFlight upload path is now in place, but the product itself is still under active development.

## 1. Create a GitHub repository

Create an empty repository in your GitHub account, then from this folder run:

```bash
git init
git add .
git commit -m "Initial IPTV package"
git branch -M main
git remote add origin <your-github-repo-url>
git push -u origin main
```

If this folder is already a git repository, skip `git init` and just add the remote if needed.

## 2. Run the package workflow

After the push:

1. Open your repository on GitHub
2. Open the `Actions` tab
3. Select `Swift Package CI`
4. Confirm the macOS job completes successfully

The package workflow file is:

- [.github/workflows/swift-package-ci.yml](/c:/Users/anand/Downloads/pypgms/iosapp/.github/workflows/swift-package-ci.yml)

## 3. What the package workflow runs

On every push to `main` or `master`, on pull requests, and on manual dispatch:

- `swift package resolve`
- `swift build`
- `swift test`

## 4. iPhone TestFlight workflow

The release workflow file is:

- [.github/workflows/ios-testflight.yml](/c:/Users/anand/Downloads/pypgms/iosapp/.github/workflows/ios-testflight.yml)

This workflow uses:

- `project.yml`
- `scripts/ci/install_signing_assets.sh`
- `scripts/ci/write_export_options.sh`

It depends on the repository secrets documented in [docs/testflight-setup.md](/c:/Users/anand/Downloads/pypgms/iosapp/docs/testflight-setup.md).

## 5. Secrets currently required for iPhone release

- `APPLE_TEAM_ID`
- `BUILD_CERTIFICATE_BASE64`
- `P12_PASSWORD`
- `BUILD_PROVISION_PROFILE_BASE64`
- `KEYCHAIN_PASSWORD`
- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_PRIVATE_KEY`

## 6. Next CI milestone after this
The next pipeline upgrades should be:

1. Add a tvOS archive/upload workflow
2. Add release tagging and build-number strategy
3. Add artifact retention for generated `.ipa` files if needed
4. Add automated smoke checks for the app target
5. Add App Store metadata/screenshot automation later if desired
