# Mac Bootstrap Checklist

Use this the moment you have a Mac available.

## Before we start

- Sign in to the Mac with your Apple ID
- Install Xcode from the App Store
- Open Xcode once and accept the license
- Install Command Line Tools

Command:

```bash
xcode-select --install
```

## Tooling

- Install Homebrew
- Install Git if needed

Suggested packages:

```bash
brew install swiftlint xcodegen
```

## Apple account setup

- Sign in to Xcode with your Apple Developer account
- Confirm your team appears in Xcode settings
- Confirm you can create signing certificates

## Repo setup

From the repo root:

```bash
git clone <your-repo-url>
cd iosapp
```

If you are starting from Windows first, push this folder to GitHub and let the remote macOS workflow validate the package before you touch Xcode:

```bash
git init
git add .
git commit -m "Initial IPTV package"
git branch -M main
git remote add origin <your-github-repo-url>
git push -u origin main
```

Then open the Actions tab in GitHub and confirm the `Swift Package CI` workflow passes.

## First validation

Run package tests:

```bash
swift test
```

This should validate the package code added now:

- domain models
- M3U parser
- Xtream API endpoint builder

If the package already passes in GitHub Actions, you have a good signal that the shared Swift code is healthy before you begin app target work.

## First Xcode app work

Once the package tests pass, the next build sequence should be:

1. Create a new Apple app project with shared `iOS` and `tvOS` targets
2. Add the local Swift package from this repo
3. Add `MobileVLCKit` for iOS/iPadOS
4. Add `TVVLCKit` for tvOS
5. Build a minimal player screen that accepts a URL
6. Build source onboarding for:
   - M3U URL
   - Xtream host
   - Xtream username
   - Xtream password
7. Connect the onboarding flow to the package models

## Priority order once Mac is ready

1. App shell and navigation
2. VLC player integration
3. M3U import flow
4. Xtream login flow
5. Live TV browsing
6. Favorites
7. Movies and series

## Nice to have if time allows

- Keychain storage
- SwiftData persistence
- XMLTV/EPG import
- tvOS remote shortcuts
- TestFlight pipeline
