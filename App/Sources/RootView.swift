import SwiftUI
import IPTVDomain
import UIKit

struct RootView: View {
    @ObservedObject var viewModel: RootViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackdrop()

                List {
                    headerSection
                    if !viewModel.savedProfiles.isEmpty {
                        savedProfilesSection
                    }
                    sourceSection
                    statusSection

                    if let errorMessage = viewModel.errorMessage {
                        issueSection(message: errorMessage)
                    }

                    if let profile = viewModel.activeProfile {
                        loadedSourceSection(profile: profile)
                    }

                    if !viewModel.groups.isEmpty {
                        Section {
                            ForEach(viewModel.groups) { group in
                                NavigationLink {
                                    ChannelListView(group: group, items: viewModel.items(in: group))
                                } label: {
                                    GroupRow(group: group, count: viewModel.items(in: group).count)
                                }
                                .listRowBackground(Color.clear)
                            }
                        } header: {
                            sectionHeader("Live Groups", subtitle: "Browse channel categories")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("1xtream-m3u")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Load your provider, browse live groups, and test playback in a more polished IPTV shell.")
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.secondaryText)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
                        Text(viewModel.isLoading ? "SYNCING" : "READY")
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(viewModel.isLoading ? AppPalette.gold : AppPalette.mint)
                        Text(viewModel.sourceMode.rawValue)
                            .font(.caption2)
                            .foregroundStyle(AppPalette.secondaryText)
                    }
                }

                HStack(spacing: 12) {
                    StatCapsule(title: "Sources", value: "3")
                    StatCapsule(title: "Profiles", value: "\(viewModel.savedProfiles.count)")
                    StatCapsule(title: "Groups", value: "\(viewModel.groups.count)")
                    StatCapsule(title: "Channels", value: "\(viewModel.items.count)")
                }
            }
            .cardStyle()
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private var savedProfilesSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("Saved Profiles", subtitle: "Jump back into a provider and refresh only when you want")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(viewModel.savedProfiles) { record in
                            Button {
                                viewModel.selectProfile(record)
                            } label: {
                                SavedProfileCard(
                                    record: record,
                                    isActive: viewModel.activeProfile?.id == record.id
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }

                if !viewModel.savedProfiles.isEmpty {
                    Text("Sources and loaded channels now persist on-device. Pull a profile back instantly, then refresh only when the provider changed.")
                        .font(.footnote)
                        .foregroundStyle(AppPalette.secondaryText)
                }
            }
            .cardStyle()
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private var sourceSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("Connect Source", subtitle: "M3U URL, pasted M3U, or Xtream credentials")

                Picker("Mode", selection: $viewModel.sourceMode) {
                    ForEach(RootViewModel.SourceMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .colorScheme(.dark)

                sourceField("Profile Name") {
                    TextField("Weekend Sports", text: $viewModel.profileName)
                        .textInputAutocapitalization(.words)
                }

                switch viewModel.sourceMode {
                case .m3uURL:
                    sourceField("Playlist URL") {
                        TextField("http://example.com/get.php?...&type=m3u_plus&output=ts", text: $viewModel.m3uURLString)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                    }

                case .m3uText:
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Playlist Text")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppPalette.secondaryText)

                        TextEditor(text: $viewModel.rawM3UText)
                            .frame(minHeight: 160)
                            .font(.system(.footnote, design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .background(AppPalette.fieldFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .foregroundStyle(.white)
                    }

                case .xtream:
                    sourceField("Provider Host") {
                        TextField("provider.example.com", text: $viewModel.xtreamHostString)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                    }

                    sourceField("Username") {
                        TextField("demo-user", text: $viewModel.xtreamUsername)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }

                    sourceField("Password") {
                        SecureField("Password", text: $viewModel.xtreamPassword)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }

                Button {
                    Task { await viewModel.loadChannels() }
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView().tint(.black)
                        } else {
                            Image(systemName: "dot.radiowaves.left.and.right")
                        }
                        Text(viewModel.isLoading ? "Loading..." : "Load Channels")
                            .fontWeight(.bold)
                        Spacer()
                    }
                    .foregroundStyle(.black.opacity(0.85))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 15)
                    .background(
                        LinearGradient(colors: [AppPalette.mint, AppPalette.sky], startPoint: .leading, endPoint: .trailing),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                }
                .disabled(viewModel.isLoading)

                if !viewModel.savedProfiles.isEmpty {
                    Text("Your current source entry is saved automatically so you can come back without retyping it.")
                        .font(.caption)
                        .foregroundStyle(AppPalette.secondaryText)
                }
            }
            .cardStyle()
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private var statusSection: some View {
        Section {
            Text(viewModel.statusMessage)
                .font(.footnote)
                .foregroundStyle(AppPalette.secondaryText)
                .cardStyle()
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private func issueSection(message: String) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Label("Issue", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Text(message)
                    .foregroundStyle(AppPalette.secondaryText)
            }
            .cardStyle(background: AppPalette.danger)
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private func loadedSourceSection(profile: ProviderProfile) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader(profile.name, subtitle: "Current loaded source")
                HStack(spacing: 12) {
                    StatCapsule(title: "Type", value: profile.kind.rawValue.uppercased())
                    StatCapsule(title: "Groups", value: "\(viewModel.groups.count)")
                    StatCapsule(title: "Channels", value: "\(viewModel.items.count)")
                }

                if let lastUpdatedAt = viewModel.lastUpdatedAt {
                    Text("Last refreshed \(lastUpdatedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(AppPalette.secondaryText)
                }

                HStack(spacing: 12) {
                    Button {
                        Task { await viewModel.refreshActiveProfile() }
                    } label: {
                        quickActionButton("Refresh Source", systemImage: "arrow.clockwise", fill: true)
                    }
                    .disabled(viewModel.isLoading)

                    Button {
                        if let active = viewModel.savedProfiles.firstIndex(where: { $0.profile.id == profile.id }) {
                            viewModel.deleteProfiles(at: IndexSet(integer: active))
                        }
                    } label: {
                        quickActionButton("Remove", systemImage: "trash", fill: false)
                    }
                }
            }
            .cardStyle()
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    @ViewBuilder
    private func sourceField<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppPalette.secondaryText)
            content()
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(AppPalette.fieldFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .foregroundStyle(.white)
        }
    }

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.black))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(AppPalette.secondaryText)
        }
    }

    private func quickActionButton(_ title: String, systemImage: String, fill: Bool) -> some View {
        HStack {
            Image(systemName: systemImage)
            Text(title)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .foregroundStyle(fill ? .black.opacity(0.85) : .white)
        .background(
            fill ? AnyShapeStyle(
                LinearGradient(colors: [AppPalette.mint, AppPalette.sky], startPoint: .leading, endPoint: .trailing)
            ) : AnyShapeStyle(AppPalette.fieldFill),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }
}

private struct ChannelListView: View {
    let group: MediaGroup
    let items: [MediaItem]
    @State private var selectedRoute: ChannelRoute?
    @State private var searchText = ""

    var body: some View {
        ZStack {
            AppBackdrop()

            List(filteredItems) { item in
                Button {
                    if let index = filteredItems.firstIndex(of: item) {
                        selectedRoute = ChannelRoute(index: index)
                    }
                } label: {
                    ChannelRow(item: item)
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search channels")
        .navigationDestination(item: $selectedRoute) { route in
            ChannelDetailView(playlist: filteredItems, initialIndex: route.index, groupName: group.name)
        }
    }

    private var filteredItems: [MediaItem] {
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else {
            return items
        }

        return items.filter { item in
            item.title.localizedCaseInsensitiveContains(term)
        }
    }
}

private struct ChannelRoute: Identifiable, Hashable {
    let index: Int

    var id: Int { index }
}

private struct ChannelDetailView: View {
    let playlist: [MediaItem]
    let initialIndex: Int
    let groupName: String
    @StateObject private var playerController = VLCPlayerController()
    @State private var isPresentingFullscreen = false
    @State private var hasAutoPresented = false
    @State private var isMiniPlayerActive = false
    @State private var currentIndex: Int
    @Environment(\.dismiss) private var dismiss

    init(playlist: [MediaItem], initialIndex: Int, groupName: String) {
        self.playlist = playlist
        self.initialIndex = initialIndex
        self.groupName = groupName
        _currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            AppBackdrop()

            List {
                Section {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(currentItem.title)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        HStack(spacing: 12) {
                            StatCapsule(title: "Kind", value: currentItem.kind.rawValue.uppercased())
                            StatCapsule(title: "ID", value: currentItem.id)
                            StatCapsule(title: "Group", value: groupName)
                        }
                    }
                    .cardStyle()
                }

                if let source = currentItem.source {
                    Section {
                        VStack(alignment: .leading, spacing: 14) {
                            videoSurfaceCard

                            HStack(spacing: 12) {
                                Button {
                                    Task {
                                        await playerController.startPlayback(source: source)
                                    }
                                } label: {
                                    playerButton("Play Stream", systemImage: "play.fill", fill: true)
                                }

                                Button {
                                    playerController.stop()
                                } label: {
                                    playerButton("Stop", systemImage: "stop.fill", fill: false)
                                }
                            }

                            Button {
                                isPresentingFullscreen = true
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    Text("Open Full Screen")
                                        .fontWeight(.bold)
                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .foregroundStyle(.white)
                                .background(AppPalette.fieldFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }

                            StatCapsule(title: "Player", value: playerController.stateDescription)

                            if let probeSummary = playerController.probeSummary {
                                Text(probeSummary)
                                    .font(.footnote)
                                    .foregroundStyle(AppPalette.secondaryText)
                            }

                            if let errorMessage = playerController.errorMessage {
                                Text(errorMessage)
                                    .font(.footnote)
                                    .foregroundStyle(AppPalette.secondaryText)
                            }
                        }
                        .cardStyle()
                    } header: {
                        Text("Playback")
                    }

                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            if let hint = source.containerHint {
                                StatCapsule(title: "Container", value: hint.uppercased())
                            }

                            Text(source.url.absoluteString)
                                .font(.footnote.monospaced())
                                .foregroundStyle(AppPalette.secondaryText)
                                .textSelection(.enabled)
                        }
                        .cardStyle()
                    } header: {
                        Text("Stream URL")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
        }
        .navigationTitle(currentItem.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onDisappear {
            playerController.stop()
            playerController.detachOutput()
        }
        .task {
            guard !playlist.isEmpty,
                  !hasAutoPresented,
                  currentItem.source != nil else {
                return
            }

            hasAutoPresented = true
            isMiniPlayerActive = true
            isPresentingFullscreen = true
        }
        .fullScreenCover(isPresented: $isPresentingFullscreen) {
            FullScreenPlayerView(
                title: currentItem.title,
                source: sourceOrNil,
                hasPreviousChannel: currentIndex > 0,
                hasNextChannel: currentIndex < playlist.count - 1,
                playerController: playerController
            ) {
                dismissToBrowser()
            } onMinimize: {
                isMiniPlayerActive = true
            } onPreviousChannel: {
                moveChannel(by: -1)
            } onNextChannel: {
                moveChannel(by: 1)
            )
        }
    }

    private var currentItem: MediaItem {
        playlist[currentIndex]
    }

    private var sourceOrNil: PlaybackSource? {
        currentItem.source
    }

    @ViewBuilder
    private var videoSurfaceCard: some View {
        if isPresentingFullscreen {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.black)

                VStack(spacing: 10) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(AppPalette.mint)
                    Text("Playing in full screen")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Close the player to return here.")
                        .font(.footnote)
                        .foregroundStyle(AppPalette.secondaryText)
                }
            }
            .frame(minHeight: 230)
        } else if isMiniPlayerActive {
            VStack(alignment: .leading, spacing: 12) {
                VLCVideoSurfaceView(mediaPlayer: playerController.mediaPlayer)
                    .frame(minHeight: 210)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                HStack(spacing: 12) {
                    Button {
                        isPresentingFullscreen = true
                    } label: {
                        playerButton("Expand Player", systemImage: "arrow.up.left.and.arrow.down.right", fill: true)
                    }

                    Button {
                        playerController.stop()
                        playerController.detachOutput()
                        isMiniPlayerActive = false
                    } label: {
                        playerButton("Stop", systemImage: "stop.fill", fill: false)
                    }
                }
            }
        } else {
            VLCVideoSurfaceView(mediaPlayer: playerController.mediaPlayer)
                .frame(minHeight: 230)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private func playerButton(_ title: String, systemImage: String, fill: Bool) -> some View {
        HStack {
            Image(systemName: systemImage)
            Text(title)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .foregroundStyle(fill ? .black.opacity(0.85) : .white)
        .background(
            fill ? AnyShapeStyle(
                LinearGradient(colors: [AppPalette.mint, AppPalette.sky], startPoint: .leading, endPoint: .trailing)
            ) : AnyShapeStyle(AppPalette.fieldFill),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    private func moveChannel(by step: Int) {
        let nextIndex = currentIndex + step
        guard playlist.indices.contains(nextIndex) else {
            return
        }

        currentIndex = nextIndex
        isMiniPlayerActive = true
        if let source = currentItem.source {
            Task {
                await playerController.startPlayback(source: source)
            }
        }
    }

    private func dismissToBrowser() {
        playerController.stop()
        playerController.detachOutput()
        isMiniPlayerActive = false
        dismiss()
    }
}

private struct FullScreenPlayerView: View {
    let title: String
    let source: PlaybackSource?
    let hasPreviousChannel: Bool
    let hasNextChannel: Bool
    @ObservedObject var playerController: VLCPlayerController
    let onBackToBrowser: () -> Void
    let onMinimize: () -> Void
    let onPreviousChannel: () -> Void
    let onNextChannel: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var controlsVisible = true
    @State private var autoHideTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VLCVideoSurfaceView(mediaPlayer: playerController.mediaPlayer)
                .ignoresSafeArea()
            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture {
                    revealControls()
                }

            if controlsVisible {
                VStack(spacing: 0) {
                    topBar
                    Spacer()
                    bottomBar
                }
                .padding(.top, 10)
                .padding(.bottom, 20)
                .transition(.opacity)
            }
        }
        .statusBarHidden(true)
        .onAppear {
            PlayerOrientationCoordinator.shared.requestLandscape()
            controlsVisible = true
            if let source {
                Task {
                    await playerController.startPlayback(source: source)
                }
            }
        }
        .onDisappear {
            autoHideTask?.cancel()
            playerController.detachOutput()
            PlayerOrientationCoordinator.shared.requestPortrait()
        }
        .onReceive(playerController.$stateDescription) { _ in
            if shouldAutoHideControls {
                revealControls()
            } else {
                autoHideTask?.cancel()
                withAnimation(.easeInOut(duration: 0.2)) {
                    controlsVisible = true
                }
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            Button {
                onMinimize()
                dismiss()
            } label: {
                Image(systemName: "pip.exit")
                    .font(.headline.weight(.bold))
                    .frame(width: 42, height: 42)
                    .background(.black.opacity(0.45), in: Circle())
            }

            Button {
                playerController.stop()
                playerController.detachOutput()
                dismiss()
                Task { @MainActor in
                    onBackToBrowser()
                }
            } label: {
                Image(systemName: "chevron.backward")
                    .font(.headline.weight(.bold))
                    .frame(width: 42, height: 42)
                    .background(.black.opacity(0.45), in: Circle())
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(playerController.stateDescription)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var bottomBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    onPreviousChannel()
                    revealControls()
                } label: {
                    fullscreenButton("Prev", systemImage: "backward.fill", fill: false)
                }
                .disabled(!hasPreviousChannel)

                Button {
                    Task { await playerController.retryPlayback() }
                } label: {
                    fullscreenButton(primaryActionTitle, systemImage: primaryActionIcon, fill: true)
                }

                Button {
                    playerController.stop()
                    playerController.detachOutput()
                } label: {
                    fullscreenButton("Stop", systemImage: "stop.fill", fill: false)
                }

                Button {
                    onNextChannel()
                    revealControls()
                } label: {
                    fullscreenButton("Next", systemImage: "forward.fill", fill: false)
                }
                .disabled(!hasNextChannel)
            }

            if let probeSummary = playerController.probeSummary {
                Text(probeSummary)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }

            if let errorMessage = playerController.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black.opacity(0.52), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 20)
    }

    private func fullscreenButton(_ title: String, systemImage: String, fill: Bool) -> some View {
        HStack {
            Image(systemName: systemImage)
            Text(title)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .foregroundStyle(fill ? .black.opacity(0.85) : .white)
        .background(
            fill ? AnyShapeStyle(
                LinearGradient(colors: [AppPalette.mint, AppPalette.sky], startPoint: .leading, endPoint: .trailing)
            ) : AnyShapeStyle(Color.white.opacity(0.12)),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    private func revealControls() {
        withAnimation(.easeInOut(duration: 0.2)) {
            controlsVisible = true
        }

        autoHideTask?.cancel()
        guard shouldAutoHideControls else {
            return
        }

        autoHideTask = Task {
            try? await Task.sleep(for: .seconds(10))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.25)) {
                    controlsVisible = false
                }
            }
        }
    }

    private var shouldAutoHideControls: Bool {
        playerController.stateDescription == "Playing" || playerController.stateDescription == "Buffering..."
    }

    private var primaryActionTitle: String {
        playerController.errorMessage == nil ? "Play" : "Retry"
    }

    private var primaryActionIcon: String {
        playerController.errorMessage == nil ? "play.fill" : "arrow.clockwise"
    }
}

private struct SavedProfileCard: View {
    let record: SavedProfileRecord
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(record.profile.name)
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text(record.profile.kind.rawValue.uppercased())
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(isActive ? .black.opacity(0.8) : AppPalette.mint)
                }

                Spacer()

                if isActive {
                    Image(systemName: "dot.radiowaves.forward")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.black.opacity(0.82))
                }
            }

            HStack(spacing: 10) {
                miniStat("Groups", value: "\(record.groups.count)")
                miniStat("Channels", value: "\(record.items.count)")
            }

            Text(summaryText)
                .font(.caption)
                .foregroundStyle(isActive ? .black.opacity(0.75) : AppPalette.secondaryText)
                .lineLimit(2)
        }
        .padding(18)
        .frame(width: 240, alignment: .leading)
        .background(background, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(isActive ? 0.0 : 0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(isActive ? 0.18 : 0.24), radius: 18, x: 0, y: 10)
    }

    private var background: some ShapeStyle {
        if isActive {
            return AnyShapeStyle(
                LinearGradient(colors: [AppPalette.mint, AppPalette.sky], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
        }

        return AnyShapeStyle(AppPalette.card.opacity(0.96))
    }

    private var summaryText: String {
        if let lastUpdatedAt = record.lastUpdatedAt {
            return "Updated \(lastUpdatedAt.formatted(date: .abbreviated, time: .shortened))"
        }

        return "Saved and ready to refresh whenever the provider changes."
    }

    private func miniStat(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.caption2.weight(.heavy))
                .foregroundStyle(isActive ? .black.opacity(0.55) : AppPalette.secondaryText)
            Text(value)
                .font(.subheadline.weight(.black))
                .foregroundStyle(isActive ? .black.opacity(0.85) : .white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background((isActive ? Color.black.opacity(0.08) : AppPalette.fieldFill), in: Capsule())
    }
}

private final class PlayerOrientationCoordinator {
    static let shared = PlayerOrientationCoordinator()

    func requestLandscape() {
        request(mask: .landscape)
    }

    func requestPortrait() {
        request(mask: .portrait)
    }

    private func request(mask: UIInterfaceOrientationMask) {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            return
        }

        let preferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: mask)
        try? scene.requestGeometryUpdate(preferences)
    }
}

private struct GroupRow: View {
    let group: MediaGroup
    let count: Int

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: [AppPalette.blue, AppPalette.teal], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 54, height: 54)
                .overlay {
                    Image(systemName: "sparkles.tv")
                        .font(.title3.weight(.black))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 5) {
                Text(group.name)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Text("Browse live channels")
                    .font(.caption)
                    .foregroundStyle(AppPalette.secondaryText)
            }

            Spacer()

            Text("\(count)")
                .font(.title3.weight(.black))
                .foregroundStyle(AppPalette.mint)
        }
        .cardStyle()
    }
}

private struct ChannelRow: View {
    let item: MediaItem

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: [AppPalette.blue, AppPalette.teal], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 58, height: 58)
                .overlay {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 5) {
                Text(item.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(item.kind.rawValue.uppercased())
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(AppPalette.mint)

                    if let container = item.source?.containerHint, !container.isEmpty {
                        Text(container.uppercased())
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(AppPalette.secondaryText)
                    }
                }
            }

            Spacer()
        }
        .cardStyle()
    }
}

private struct StatCapsule: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased())
                .font(.caption2.weight(.heavy))
                .foregroundStyle(AppPalette.secondaryText)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppPalette.fieldFill, in: Capsule())
    }
}

private struct AppBackdrop: View {
    var body: some View {
        LinearGradient(
            colors: [Color(red: 0.03, green: 0.05, blue: 0.11), Color(red: 0.02, green: 0.08, blue: 0.15), Color(red: 0.05, green: 0.15, blue: 0.16)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(AppPalette.teal.opacity(0.28))
                .frame(width: 240, height: 240)
                .blur(radius: 30)
                .offset(x: 80, y: -40)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(AppPalette.blue.opacity(0.22))
                .frame(width: 260, height: 260)
                .blur(radius: 32)
                .offset(x: -80, y: 90)
        }
        .ignoresSafeArea()
    }
}

private enum AppPalette {
    static let mint = Color(red: 0.33, green: 0.96, blue: 0.86)
    static let sky = Color(red: 0.66, green: 0.95, blue: 1.00)
    static let blue = Color(red: 0.14, green: 0.26, blue: 0.52)
    static let teal = Color(red: 0.04, green: 0.43, blue: 0.43)
    static let gold = Color(red: 1.00, green: 0.73, blue: 0.31)
    static let danger = Color(red: 0.30, green: 0.08, blue: 0.12)
    static let card = Color(red: 0.08, green: 0.11, blue: 0.19)
    static let fieldFill = Color.white.opacity(0.08)
    static let secondaryText = Color.white.opacity(0.68)
}

private extension View {
    func cardStyle(background: Color = AppPalette.card) -> some View {
        self
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background.opacity(0.96), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.24), radius: 18, x: 0, y: 12)
    }
}

#Preview {
    RootView(viewModel: RootViewModel())
        .preferredColorScheme(.dark)
}
