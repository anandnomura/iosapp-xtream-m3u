import SwiftUI
import IPTVDomain

struct RootView: View {
    @ObservedObject var viewModel: RootViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackdrop()

                List {
                    headerSection
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
                    StatCapsule(title: "Groups", value: "\(viewModel.groups.count)")
                    StatCapsule(title: "Channels", value: "\(viewModel.items.count)")
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
}

private struct ChannelListView: View {
    let group: MediaGroup
    let items: [MediaItem]

    var body: some View {
        ZStack {
            AppBackdrop()

            List(items) { item in
                NavigationLink {
                    ChannelDetailView(item: item)
                } label: {
                    ChannelRow(item: item)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .scrollContentBackground(.hidden)
            .listStyle(.plain)
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}

private struct ChannelDetailView: View {
    let item: MediaItem
    @StateObject private var playerController = VLCPlayerController()

    var body: some View {
        ZStack {
            AppBackdrop()

            List {
                Section {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(item.title)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        HStack(spacing: 12) {
                            StatCapsule(title: "Kind", value: item.kind.rawValue.uppercased())
                            StatCapsule(title: "ID", value: item.id)
                        }
                    }
                    .cardStyle()
                }

                if let source = item.source {
                    Section {
                        VStack(alignment: .leading, spacing: 14) {
                            VLCVideoSurfaceView(mediaPlayer: playerController.mediaPlayer)
                                .frame(minHeight: 230)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

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
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onDisappear {
            playerController.stop()
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
