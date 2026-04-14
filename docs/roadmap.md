# Product Roadmap

This is the authoritative execution tracker for the app. We update this file as items are shipped and tested so the next work is always obvious.

## Status Key

- `[x]` Done and verified in the app
- `[~]` Implemented but still needs validation / hardening
- `[ ]` Not started

## Current Test Batch

These are the items being grouped together for the next round of testing:

- `[~]` Top-level app sections for Home, Favorites, Recents, Search, and Source
- `[~]` Favorites that persist across launches
- `[~]` Recent channels that persist across launches
- `[~]` Channel/browser UI wired to favorites and recents
- `[~]` Home screen shortcuts that surface saved content before raw source forms
- `[~]` Search across all loaded content from the home screen
- `[~]` Cleaner empty and browse states on the home screen
- `[~]` Source management moved out of the main landing flow
- `[~]` Dedicated favorites and recents screens
- `[~]` App-level search section
- `[~]` AirPlay route picker in fullscreen player
- `[~]` Lock screen / Control Center media metadata
- `[~]` Remote play, pause, next, and previous command handling
- `[~]` Primary player control behaves as play / pause / retry based on state
- `[~]` One controlled auto-reconnect when playback stalls in opening/buffering
- `[~]` Visible reconnect feedback in the fullscreen player
- `[~]` In-player diagnostics panel for stream host, container, probe, and reconnect state
- `[~]` Xtream passwords moved to Keychain-backed storage
- `[~]` Per-profile last played channel and last selected group memory

### How To Test Current Batch

1. Favorites persistence
- Load a provider and open any group.
- Tap the heart on 2-3 channels.
- Confirm those channels appear in the `Favorites` rail on the home screen.
- Force close the app and relaunch it.
- Confirm the same favorites are still present and still marked with hearts in channel lists.

2. Recents persistence
- Open 2-3 channels from different groups.
- Back out to the home screen.
- Confirm those channels appear in the `Recent Channels` rail in most-recent-first order.
- Force close the app and relaunch it.
- Confirm the same recent items are still present.

3. Channel/browser wiring
- In a group list, favorite and unfavorite a channel from the row heart button.
- Open a channel and toggle favorite again from the player heart button.
- Go back to the group list and confirm the state stayed in sync.
- Open a recent/favorite shortcut from the home screen and confirm it starts the player flow.

4. Home shortcuts
- Confirm `Favorites` and `Recent Channels` appear above the source management section.
- Confirm tapping a shortcut opens playback for that item.
- Confirm the rails disappear naturally if there is no data for them.

5. Home search
- Load a provider with multiple groups.
- Search for a known channel from the home screen search box.
- Confirm matching channels appear even if they are in different groups.
- Tap a result and confirm it opens the player flow.
- Clear the search and confirm the normal home sections return.

6. Empty / browse states
- Fresh install or delete all saved profiles if practical.
- Confirm the app shows a useful empty state instead of only raw forms.
- After loading a provider, confirm live groups appear sorted and the home screen still feels usable.

7. App sections
- Confirm the section switcher shows `Home`, `Favorites`, `Recents`, `Search`, and `Source`.
- Confirm switching sections does not lose loaded state.
- Confirm `Source` is where profile switching and source entry now live.
- Confirm `Home` feels content-first instead of source-form-first.

8. Dedicated favorites / recents screens
- Open the `Favorites` section and confirm it shows a full list, not just the rail.
- Open the `Recents` section and confirm it shows a full list in recent-first order.
- Confirm tapping items from these sections opens playback.

9. App-level search section
- Open the `Search` section and search from there instead of the home screen.
- Confirm it can search across all loaded channels.
- Confirm the search section shows a useful empty or no-results state.

10. Native media controls
- Start playback and lock the phone.
- Confirm the current channel title appears in the lock screen / Control Center media area.
- Use play / pause from the lock screen or Control Center and confirm the player reacts.
- If there is a next/previous channel available, confirm those controls switch channels.
- Open fullscreen and confirm the AirPlay route picker is visible in the top bar.

11. Reconnect behavior
- Start a stream that sometimes buffers or stalls.
- Confirm the player shows a reconnect message if it stays in opening/buffering too long.
- Confirm it attempts one automatic retry instead of looping forever.
- If playback still fails, confirm the final message makes it clear that reconnect did not recover the stream.

12. Diagnostics panel
- Open fullscreen playback and tap the new info button.
- Confirm the diagnostics panel shows host, scheme, container, probe summary, and reconnect count.
- Confirm the panel helps identify whether the failure is transport, host, or playback-related.

13. Keychain-backed Xtream credentials
- Save an Xtream profile and fully close the app.
- Reopen the app and confirm the Xtream profile can still be selected and refreshed without retyping the password.
- Delete the Xtream profile and confirm it disappears from the app.
- Re-add the same Xtream profile and confirm it behaves like a fresh saved source.

14. Per-profile resume state
- Load a provider and open a specific group.
- Play a channel from that group, then return to the `Source` section.
- Confirm the profile shows a `Resume Last Channel` card.
- Tap it and confirm it opens the last played channel directly.
- Switch to another provider profile and confirm each profile keeps its own last played channel / last group memory.

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
- `[~]` Search across all loaded content

## Phase 2: Content-First App UX

- `[~]` Home dashboard instead of source-form-first landing
- `[~]` Favorites rail / screen
- `[~]` Recents / continue watching rail
- `[~]` Search entry point at the app level
- `[~]` Better group browsing density and sorting
- `[~]` Source management moved into settings/admin area
- `[~]` Cleaner empty / loading / error states

## Phase 3: Player Quality

- `[~]` Better buffering recovery logic
- `[~]` Stream retry / reconnect policy
- `[~]` Visible buffering / reconnect feedback
- `[~]` Playback diagnostics that help with provider-specific failures
- `[ ]` Audio/subtitle track controls where available
- `[~]` AirPlay / route picker
- `[~]` Now Playing / remote command integration

## Phase 4: Persistence and Security

- `[ ]` Move profile and cache storage to SwiftData
- `[~]` Move provider credentials to Keychain
- `[~]` Persist last played channel per profile
- `[~]` Persist selected group and browser position
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
