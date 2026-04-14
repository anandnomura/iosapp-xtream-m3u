# IPTV Apple App Strategy

This repo now holds the product and technical plan for a professional IPTV app targeting:

- iOS
- iPadOS
- tvOS

The recommended implementation is a single native Apple-platform codebase built with:

- SwiftUI for app UI
- VLCKit for playback
- URLSession for M3U/Xtream networking
- SwiftData for favorites, recents, and profiles

Why this stack:

- It is the simplest serious stack for Apple platforms.
- It supports iPhone, iPad, and Apple TV cleanly.
- It gives much broader codec and stream support than `AVPlayer` alone.
- It avoids the complexity of forcing a React Native or Flutter app to behave like a high-end TV player.

Start with [docs/iptv-app-plan.md](/c:/Users/anand/Downloads/pypgms/iosapp/docs/iptv-app-plan.md) for the full recommendation, research notes, open-source evaluation, and no-Mac deployment path.

Use [docs/roadmap.md](/c:/Users/anand/Downloads/pypgms/iosapp/docs/roadmap.md) as the live execution tracker for what is done, what is in the current test batch, and what comes next.

## Remote build status

This repo now includes a GitHub Actions workflow at [.github/workflows/swift-package-ci.yml](/c:/Users/anand/Downloads/pypgms/iosapp/.github/workflows/swift-package-ci.yml) that runs the Swift package build and test suite on GitHub-hosted macOS runners.

That means you can validate the shared package remotely from GitHub even before the full Xcode app targets exist.

Use [docs/github-actions-setup.md](/c:/Users/anand/Downloads/pypgms/iosapp/docs/github-actions-setup.md) to push this repo to GitHub and enable the workflow.

For restart-on-Mac guidance, use these in order:

- [docs/mac-bootstrap-checklist.md](/c:/Users/anand/Downloads/pypgms/iosapp/docs/mac-bootstrap-checklist.md)
- [docs/session-handoff.md](/c:/Users/anand/Downloads/pypgms/iosapp/docs/session-handoff.md)
