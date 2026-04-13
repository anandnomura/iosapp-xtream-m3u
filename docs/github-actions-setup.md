# GitHub Actions Setup

This repo can now validate the shared Swift package remotely with GitHub-hosted macOS runners.

## What this gives you

- Remote `swift build`
- Remote `swift test`
- A clean macOS signal before the Xcode app exists

## What this does not give you yet

- No signed `.ipa`
- No TestFlight upload
- No iOS or tvOS app archive yet
- No interactive Xcode debugging

Those come later, once a Mac creates the actual Xcode app targets and signing setup.

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

## 2. Run the workflow

After the push:

1. Open your repository on GitHub
2. Open the `Actions` tab
3. Select `Swift Package CI`
4. Confirm the macOS job completes successfully

The workflow file is:

- [.github/workflows/swift-package-ci.yml](/c:/Users/anand/Downloads/pypgms/iosapp/.github/workflows/swift-package-ci.yml)

## 3. What the workflow currently runs

On every push to `main` or `master`, on pull requests, and on manual dispatch:

- `swift package resolve`
- `swift build`
- `swift test`

## 4. Next CI milestone after you have a Mac

Once the Xcode project exists, the next pipeline upgrade should be:

1. Add an app build job using `xcodebuild`
2. Add signing material as GitHub secrets
3. Archive the app on macOS runners
4. Export an `.ipa`
5. Upload to TestFlight

## Recommended future secrets

Do not add these yet because the project is not ready for signing, but this is the usual direction:

- `BUILD_CERTIFICATE_BASE64`
- `P12_PASSWORD`
- `BUILD_PROVISION_PROFILE_BASE64`
- `KEYCHAIN_PASSWORD`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_PRIVATE_KEY`
