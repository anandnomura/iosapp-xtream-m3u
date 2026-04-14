# Product Roadmap

This is the authoritative execution tracker for the app. We update this file as items are shipped and tested so the next work is always obvious.

## Status Key

- `[x]` Done and verified in the app
- `[~]` Implemented but still needs validation / hardening
- `[ ]` Not started

## Current Test Batch

These are the items being grouped together for the next round of testing:

- `[~]` Favorites that persist across launches
- `[~]` Recent channels that persist across launches
- `[~]` Channel/browser UI wired to favorites and recents
- `[~]` Home screen shortcuts that surface saved content before raw source forms

## Phase 1: Stable Live TV MVP

- `[x]` M3U URL loading
- `[x]` Raw M3U text loading
- `[x]` Xtream credentials loading
- `[x]` Saved source/profile persistence
- `[x]` Cached loaded channels per saved profile
- `[x]` HTTP playlist support for common IPTV providers
- `[x]` VLC-based live playback
- `[x]` Fullscreen landscape playback
- `[x]` Next / previous channel switching
- `[~]` Player controls auto-hide and reappear reliably on tap
- `[~]` Back-to-browser flow from fullscreen
- `[~]` Channel list reliability parity between M3U and Xtream sources
- `[~]` Favorites
- `[~]` Recents
- `[ ]` Search across all loaded content

## Phase 2: Content-First App UX

- `[~]` Home dashboard instead of source-form-first landing
- `[~]` Favorites rail / screen
- `[~]` Recents / continue watching rail
- `[ ]` Search entry point at the app level
- `[ ]` Better group browsing density and sorting
- `[ ]` Source management moved into settings/admin area
- `[ ]` Cleaner empty / loading / error states

## Phase 3: Player Quality

- `[ ]` Better buffering recovery logic
- `[ ]` Stream retry / reconnect policy
- `[ ]` Visible buffering / reconnect feedback
- `[ ]` Playback diagnostics that help with provider-specific failures
- `[ ]` Audio/subtitle track controls where available
- `[ ]` AirPlay / route picker
- `[ ]` Now Playing / remote command integration

## Phase 4: Persistence and Security

- `[ ]` Move profile and cache storage to SwiftData
- `[ ]` Move provider credentials to Keychain
- `[ ]` Persist last played channel per profile
- `[ ]` Persist selected group and browser position
- `[ ]` Persist favorites in the long-term storage model
- `[ ]` Persist recents in the long-term storage model

## Phase 5: TV Guide and Library

- `[ ]` XMLTV / EPG ingestion
- `[ ]` Now / next metadata
- `[ ]` Live guide screen
- `[ ]` Movies browsing
- `[ ]` Series browsing
- `[ ]` Seasons and episodes flow

## Phase 6: Platform Polish

- `[ ]` iPad split-view polish
- `[ ]` tvOS target polish
- `[ ]` tvOS focus and remote behavior
- `[ ]` Accessibility pass
- `[ ]` Release hardening and crash visibility

## Done Recently

- `[x]` Removed the broken intermediate playback screen
- `[x]` Simplified fullscreen exit/back behavior
- `[x]` Stabilized crash path around fullscreen dismissal
- `[x]` Made saved source/profile restoration work on relaunch
- `[x]` Improved M3U parsing tolerance for real-world provider playlists

## Working Rules

- We do not reshuffle roadmap order casually.
- When an item is implemented, it moves to `[~]`.
- When you test it and confirm it is good, it moves to `[x]`.
- New ideas should be added under the right phase, not replace the current batch unless something is blocked.
