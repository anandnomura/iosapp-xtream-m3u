# Session Handoff

This file is the restart point for the next session on a Mac.

## Current status

Done in this Windows session:

- Chose the target architecture: native Apple app for `iOS`, `iPadOS`, and `tvOS`
- Chose the playback direction: `VLCKit`
- Evaluated open-source references and documented why they are references, not direct production forks
- Created a shared Swift package so business logic is separated from the future app targets
- Added first-pass domain models
- Added first-pass `M3U` parser
- Added first-pass `Xtream` endpoint builder
- Added unit tests for parser and endpoint generation
- Added a GitHub Actions macOS workflow for remote package builds and tests

Not done yet:

- No Xcode project
- No app targets
- No `VLCKit` integration
- No player UI
- No SwiftData persistence
- No Keychain storage
- No tvOS focus/navigation code
- No TestFlight pipeline
- No code signing or App Store Connect automation

## Files added so far

- [Package.swift](/c:/Users/anand/Downloads/pypgms/iosapp/Package.swift)
- [Sources/IPTVDomain/Models.swift](/c:/Users/anand/Downloads/pypgms/iosapp/Sources/IPTVDomain/Models.swift:1)
- [Sources/IPTVData/M3UParser.swift](/c:/Users/anand/Downloads/pypgms/iosapp/Sources/IPTVData/M3UParser.swift:1)
- [Sources/IPTVData/XtreamAPI.swift](/c:/Users/anand/Downloads/pypgms/iosapp/Sources/IPTVData/XtreamAPI.swift:1)
- [Tests/IPTVDomainTests/IPTVDomainTests.swift](/c:/Users/anand/Downloads/pypgms/iosapp/Tests/IPTVDomainTests/IPTVDomainTests.swift:1)
- [Tests/IPTVDataTests/M3UParserTests.swift](/c:/Users/anand/Downloads/pypgms/iosapp/Tests/IPTVDataTests/M3UParserTests.swift:1)
- [Tests/IPTVDataTests/XtreamAPITests.swift](/c:/Users/anand/Downloads/pypgms/iosapp/Tests/IPTVDataTests/XtreamAPITests.swift:1)
- [docs/iptv-app-plan.md](/c:/Users/anand/Downloads/pypgms/iosapp/docs/iptv-app-plan.md)
- [docs/mac-bootstrap-checklist.md](/c:/Users/anand/Downloads/pypgms/iosapp/docs/mac-bootstrap-checklist.md)
- [docs/github-actions-setup.md](/c:/Users/anand/Downloads/pypgms/iosapp/docs/github-actions-setup.md)
- [.github/workflows/swift-package-ci.yml](/c:/Users/anand/Downloads/pypgms/iosapp/.github/workflows/swift-package-ci.yml)

## First actions on the Mac

1. Install Xcode and command line tools
2. Push this repo to GitHub if that is not done yet
3. Run:

```bash
swift test
```

4. Confirm the `Swift Package CI` workflow passes in GitHub Actions
5. Confirm local package tests also pass on the Mac
6. Create the Apple app project
7. Add this local package to the Xcode project
8. Integrate `MobileVLCKit` for `iOS/iPadOS`
9. Integrate `TVVLCKit` for `tvOS`

## Recommended build order

### Phase 1: get something playing

1. Create app shell with shared navigation
2. Create source onboarding screen
3. Add `M3U URL` form
4. Add `Xtream` form with:
   - host
   - username
   - password
5. Create basic live channel list
6. Create VLC-backed player screen
7. Verify a live channel plays on iPhone first

### Phase 2: make it feel like an app

1. Add groups and folders
2. Add channel switching
3. Add favorites
4. Add recents
5. Add movie and series browsing

### Phase 3: Apple TV polish

1. tvOS focus management
2. remote shortcuts
3. split layout tuned for TV
4. playback overlay

## Suggested Xcode structure

- `IPTVApp`
  - app entry
  - navigation
  - platform-specific wrappers
- `IPTVFeatures`
  - onboarding
  - live
  - movies
  - series
  - favorites
  - settings
- `IPTVPlayer`
  - VLC wrapper
  - player view
  - playback controls
- Local package
  - `IPTVDomain`
  - `IPTVData`

## Important implementation notes

- Keep playback behind a protocol so the app is not tightly bound to VLC internals
- Store provider credentials in Keychain, not plain user defaults
- Use SwiftData for favorites, recents, and saved profiles
- Normalize both `M3U` and `Xtream` into the same app-facing models
- Treat `iPadOS` as part of the iOS target with adaptive layouts
- Build `tvOS` as a dedicated target with shared feature/view models where possible

## Known limitation from this session

Swift was not installed in this Windows environment, so no package tests were executed here.

Remote validation is now partially covered by GitHub Actions, but full app builds still require creating real Xcode targets on a Mac.

## Resume prompt

When restarting on the Mac, a good first prompt is:

> Continue this IPTV app from the existing repo. Start by running the Swift package tests, then scaffold the Xcode app targets for iOS/iPadOS/tvOS, integrate VLCKit, and build the first M3U/Xtream onboarding plus live playback flow.
