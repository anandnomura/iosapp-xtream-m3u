# IPTV App Plan

## Goal

Build a professional IPTV app for:

- iOS
- iPadOS
- tvOS

Core features:

- Add playlist by M3U or M3U URL
- Add Xtream profile using host, username, and password
- Browse live TV, movies, and series
- Switch channels quickly
- Switch groups and folders
- Add and remove favorites
- Resume playback and track recents
- Support Apple TV remote-focused navigation

## What is realistic on iOS

The app can support a broad set of audio and video formats, but not literally every format.

Important reality:

- `AVPlayer` is the safest Apple-native choice, but format support is limited compared with VLC/mpv.
- For IPTV, many providers use inconsistent streams, odd containers, MPEG-TS variants, redirects, and codecs that `AVPlayer` does not handle well.
- For a serious IPTV product, a VLC- or mpv-based core is the practical choice.

## Recommended stack

### App layer

- `SwiftUI`
- `NavigationSplitView` and adaptive layouts for iPhone, iPad, and tvOS
- Shared domain/data code across all Apple platforms

### Playback layer

- `VLCKit`
- Use `MobileVLCKit` for iOS/iPadOS
- Use `TVVLCKit` for tvOS

Why `VLCKit`:

- Mature Apple-platform playback SDK
- Better IPTV tolerance than `AVPlayer`
- Existing iOS and tvOS integration paths
- Stronger practical support for mixed stream types

### Data and persistence

- `SwiftData` for favorites, recents, watch progress, and connection profiles
- `URLSession` for M3U downloads, Xtream API calls, posters, and EPG/XMLTV ingestion
- `Keychain` for storing Xtream credentials

### Architecture

- `AppCore`
  - routing, dependency setup, platform adaptation
- `Domain`
  - channel, group, movie, series, episode, profile, favorite, recent
- `Data`
  - m3u parser
  - xtream client
  - epg/xmltv parser
  - repositories
- `Features`
  - onboarding
  - live tv
  - movies
  - series
  - search
  - favorites
  - settings
- `Player`
  - vlc wrapper
  - track selection
  - buffering/retry
  - next/previous channel

## Best simple stack recommendation

If you want the best balance of professionalism and simplicity, use:

- Native `SwiftUI`
- `VLCKit`
- `SwiftData`
- `URLSession`
- GitHub Actions macOS runners for cloud builds

I do not recommend starting with React Native or Flutter for this app unless your main goal is reusing web/mobile skills. For a TV-first streaming experience, native Apple UI and remote handling are simpler and more reliable.

## Open-source evaluation

### Candidate 1: `tarikalaouimhamdi/IOS_IPTV_PLAYER`

Repo:

- https://github.com/tarikalaouimhamdi/IOS_IPTV_PLAYER

What is good:

- Native Swift app
- Already models live TV, VOD, and series
- Uses VLC on iOS/tvOS
- Includes favorites and tvOS targets
- Uses Xtream-style API structure

Why I would not ship it as-is:

- It appears to be an early-stage personal project, not a production foundation
- The API layer is tightly coupled to local user defaults and a specific server pattern
- Some filtering logic is hard-coded for specific regional categories
- No visible evidence of production-grade onboarding, secure credential storage, offline handling, EPG architecture, or strong test coverage

Best use:

- Reference implementation for screens, models, and VLC integration ideas
- Not the base I would fork directly for a commercial-quality app

### Candidate 2: `Kimentanm/aptv`

Repo:

- https://github.com/Kimentanm/aptv

What is good:

- Real App Store shipping history
- Targets iOS, iPadOS, tvOS, macOS, and more
- Proves one Apple-family codebase is viable

Why it is not the right base:

- The public repo is mainly a project shell and playlist samples
- It does not expose a reusable full source app here
- It is centered on M3U-style live playback, not a full Xtream/VOD/series product foundation

Best use:

- Product reference for platform coverage and feature direction

### Playback engine choice: `VLCKit` vs `MPVKit`

`VLCKit`:

- Better fit for an Apple IPTV app today
- More directly aligned with iOS/tvOS integration patterns used by existing IPTV examples

`MPVKit`:

- Interesting and capable
- Promising for advanced codec cases
- But its own README says it is mainly suitable for learning and not maintained too frequently

Recommendation:

- Use `VLCKit` first
- Keep playback wrapped behind your own `PlayerEngine` protocol so mpv can be evaluated later without rewriting the app

## Product outline

### 1. Onboarding

- Welcome screen
- Add connection
- Choose `M3U` or `Xtream`

### 2. Source management

- Multiple profiles
- Enable or disable profiles
- Reconnect and refresh playlist
- Import M3U from URL
- Optional raw M3U paste
- Xtream login with:
  - host
  - username
  - password

### 3. Browsing

- Live
- Movies
- Series
- Search
- Favorites
- Recently watched

### 4. Live TV experience

- Channel groups on left
- Channel list in middle
- Player/details on right for iPad/tvOS
- Fast next/previous channel
- Mini EPG strip if XMLTV is present
- Favorite toggle from player and list

### 5. Movies and series

- Posters and metadata
- Season and episode drill-down
- Resume progress
- Related content section

### 6. Apple TV requirements

- Focus engine support
- Large-screen split view
- Remote play/pause/select/menu handling
- Top Shelf integration can be added later

## Data model summary

- `ProviderProfile`
- `PlaylistSource`
- `XtreamCredentials`
- `ChannelGroup`
- `Channel`
- `Movie`
- `Series`
- `Season`
- `Episode`
- `Favorite`
- `RecentPlayback`
- `EPGProgram`

## Xtream and M3U support plan

### M3U

- Parse:
  - `#EXTINF`
  - `tvg-id`
  - `tvg-name`
  - `tvg-logo`
  - `group-title`
- Support plain URLs and remote playlists
- Normalize channels into shared models

### Xtream

- Authenticate with host, username, password
- Fetch:
  - live categories
  - live streams
  - VOD categories
  - VOD streams
  - series categories
  - series
  - series detail
- Normalize everything into the same shared domain models as M3U

## Important App Store risk

You can build this app, but App Store approval depends on what content sources users access and whether you have the rights to distribute or facilitate that access.

You should position the product as a personal IPTV client and avoid bundling or advertising unauthorized content.

## No-Mac delivery path

You said you do not have a Mac. The strongest path is:

### Option A: Native SwiftUI app with cloud macOS CI

- Write code in VS Code or another editor on Windows
- Keep the project in GitHub
- Build on `macos-latest` GitHub Actions runners
- Sign with your Apple Developer credentials/certificates stored as GitHub secrets
- Upload to TestFlight from CI

Why this is the best long-term option:

- Native Apple UX
- Best tvOS result
- No local Mac required for every build

### Option B: Rent Mac build time only when needed

- MacStadium
- MacinCloud
- GitHub-hosted macOS CI

Use this if you want occasional manual Xcode debugging without buying hardware.

### Option C: Expo/EAS

Expo is excellent for many apps and can build iOS apps from Windows using cloud builds, but for this project it is not my first recommendation because:

- high-end IPTV playback often needs native player control
- tvOS support is not the strongest path here
- VLC-style engine integration becomes more complex

## Recommended build sequence

### Phase 1

- Create universal Apple project
- Add provider profile management
- Implement M3U parser
- Implement Xtream client
- Build live TV list and player

### Phase 2

- Add movies and series
- Add favorites and recents
- Add XMLTV/EPG
- Add robust loading/error states

### Phase 3

- Add tvOS polish
- Add search across all content
- Add resume logic and watch history
- Add TestFlight distribution

## Final recommendation

If we are optimizing for:

- professional result
- iPhone + iPad + Apple TV
- no Mac ownership
- strong IPTV compatibility

then the best path is:

1. Build a native `SwiftUI` app
2. Use `VLCKit` as the playback engine
3. Implement clean M3U and Xtream adapters yourself
4. Store credentials in Keychain and app data in SwiftData
5. Build and ship through GitHub Actions macOS runners and TestFlight

## Research links

- Expo FAQ on cloud iOS builds from Windows: https://docs.expo.dev/faq/
- MPVKit repository: https://github.com/mpvkit/MPVKit
- Reference IPTV app with Xtream/VLC/tvOS concepts: https://github.com/tarikalaouimhamdi/IOS_IPTV_PLAYER
- APTV reference app: https://github.com/Kimentanm/aptv
- Apple App Review guidelines: https://developer.apple.com/app-store/guidelines/
