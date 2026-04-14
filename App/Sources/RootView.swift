import SwiftUI
import IPTVDomain
import UIKit

struct RootView: View {
    private enum AppSection: String, CaseIterable, Identifiable {
        case home = "Home"
        case favorites = "Favorites"
        case recents = "Recents"
        case search = "Search"
        case source = "Source"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .favorites: return "heart.fill"
            case .recents: return "clock.fill"
            case .search: return "magnifyingglass"
            case .source: return "slider.horizontal.3"
            }
        }
    }

    @ObservedObject var viewModel: RootViewModel
    @State private var globalSearchText = ""
    @State private var selectedSection: AppSection = .home

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackdrop()

                List {
                    headerSection
                    sectionSwitcherSection

                    if let errorMessage = viewModel.errorMessage {
                        issueSection(message: errorMessage)
                    }

                    contentSections
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

    private var sectionSwitcherSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AppSection.allCases) { section in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedSection = section
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: section.icon)
                                Text(section.rawValue)
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .foregroundStyle(selectedSection == section ? .black.opacity(0.85) : .white)
                            .background(
                                selectedSection == section ? AnyShapeStyle(
                                    LinearGradient(colors: [AppPalette.mint, AppPalette.sky], startPoint: .leading, endPoint: .trailing)
                                ) : AnyShapeStyle(AppPalette.fieldFill),
                                in: Capsule()
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
            .cardStyle()
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private var favoritesSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("Favorites", subtitle: "Jump back into the channels you keep coming back to")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(viewModel.favorites.prefix(12)) { item in
                            NavigationLink {
                                ChannelDetailView(
                                    playlist: [item],
                                    initialIndex: 0,
                                    groupName: item.groupID ?? "Favorites",
                                    isFavorite: viewModel.isFavorite,
                                    onToggleFavorite: viewModel.toggleFavorite,
                                    onOpenItem: viewModel.registerRecent
                                )
                            } label: {
                                MediaShortcutCard(item: item, accent: AppPalette.gold)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .cardStyle()
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private var favoritesScreenSection: some View {
        Section {
            if viewModel.favorites.isEmpty {
                contentEmptyCard(
                    title: "No favorites yet",
                    subtitle: "Tap the heart on channels you want quick access to from anywhere in the app."
                )
            } else {
                ForEach(viewModel.favorites) { item in
                    NavigationLink {
                        ChannelDetailView(
                            playlist: viewModel.favorites,
                            initialIndex: viewModel.favorites.firstIndex(of: item) ?? 0,
                            groupName: "Favorites",
                            isFavorite: viewModel.isFavorite,
                            onToggleFavorite: viewModel.toggleFavorite,
                            onOpenItem: viewModel.registerRecent
                        )
                    } label: {
                        ChannelRow(
                            item: item,
                            isFavorite: viewModel.isFavorite(item),
                            onToggleFavorite: { viewModel.toggleFavorite(item) }
                        )
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
        } header: {
            sectionHeader("Favorites Library", subtitle: "All channels you pinned for fast return access")
        }
    }

    private var recentsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("Recent Channels", subtitle: "Pick up where you left off without reopening a group first")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(viewModel.recents.prefix(12)) { item in
                            NavigationLink {
                                ChannelDetailView(
                                    playlist: [item],
                                    initialIndex: 0,
                                    groupName: item.groupID ?? "Recent",
                                    isFavorite: viewModel.isFavorite,
                                    onToggleFavorite: viewModel.toggleFavorite,
                                    onOpenItem: viewModel.registerRecent
                                )
                            } label: {
                                MediaShortcutCard(item: item, accent: AppPalette.sky)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .cardStyle()
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private var recentsScreenSection: some View {
        Section {
            if viewModel.recents.isEmpty {
                contentEmptyCard(
                    title: "No recent playback yet",
                    subtitle: "Open channels from groups, favorites, or search and they will appear here."
                )
            } else {
                ForEach(viewModel.recents) { item in
                    NavigationLink {
                        ChannelDetailView(
                            playlist: viewModel.recents,
                            initialIndex: viewModel.recents.firstIndex(of: item) ?? 0,
                            groupName: "Recents",
                            isFavorite: viewModel.isFavorite,
                            onToggleFavorite: viewModel.toggleFavorite,
                            onOpenItem: viewModel.registerRecent
                        )
                    } label: {
                        ChannelRow(
                            item: item,
                            isFavorite: viewModel.isFavorite(item),
                            onToggleFavorite: { viewModel.toggleFavorite(item) }
                        )
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
        } header: {
            sectionHeader("Recent Playback", subtitle: "Continue from the channels you opened most recently")
        }
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
                sectionHeader("Manage Source", subtitle: "Add or switch playlists only when you need to")

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

    private var globalSearchSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader("Search", subtitle: "Jump straight to a channel across every loaded group")

                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppPalette.secondaryText)

                    TextField("Search all channels", text: $globalSearchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(.white)

                    if !globalSearchText.isEmpty {
                        Button {
                            globalSearchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AppPalette.secondaryText)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(AppPalette.fieldFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .cardStyle()
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private var searchResultsSection: some View {
        Section {
            if globalSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                contentEmptyCard(
                    title: "Search all loaded channels",
                    subtitle: "Use channel names or group names to jump across every loaded provider group."
                )
            } else if filteredSearchItems.isEmpty {
                contentEmptyCard(
                    title: "No matching channels",
                    subtitle: "Try a shorter term or clear the search to browse groups again."
                )
            } else {
                ForEach(filteredSearchItems) { item in
                    NavigationLink {
                        ChannelDetailView(
                            playlist: filteredSearchItems,
                            initialIndex: filteredSearchItems.firstIndex(of: item) ?? 0,
                            groupName: "Search Results",
                            isFavorite: viewModel.isFavorite,
                            onToggleFavorite: viewModel.toggleFavorite,
                            onOpenItem: viewModel.registerRecent
                        )
                    } label: {
                        ChannelRow(
                            item: item,
                            isFavorite: viewModel.isFavorite(item),
                            onToggleFavorite: { viewModel.toggleFavorite(item) }
                        )
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
        } header: {
            sectionHeader("Search Results", subtitle: filteredSearchItems.isEmpty ? "Find channels across all groups" : "\(filteredSearchItems.count) matching channels")
        }
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

    private var emptyStateSection: some View {
        Section {
            contentEmptyCard(
                title: "Ready for your first provider",
                subtitle: "Load an M3U playlist or Xtream provider to start building your home screen, favorites, recents, and live groups."
            )
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

                if let resumeItem = viewModel.lastPlayedItem(for: profile) {
                    NavigationLink {
                        ChannelDetailView(
                            playlist: [resumeItem],
                            initialIndex: 0,
                            groupName: resumeItem.groupID ?? "Resume",
                            isFavorite: viewModel.isFavorite,
                            onToggleFavorite: viewModel.toggleFavorite,
                            onOpenItem: viewModel.registerRecent
                        )
                    } label: {
                        ResumeCard(
                            title: resumeItem.title,
                            subtitle: viewModel.lastSelectedGroup(for: profile)?.name ?? resumeItem.groupID ?? "Continue watching"
                        )
                    }
                    .buttonStyle(.plain)
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

    private var filteredSearchItems: [MediaItem] {
        let term = globalSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else {
            return []
        }

        return viewModel.items.filter { item in
            item.title.localizedCaseInsensitiveContains(term)
                || (item.groupID?.localizedCaseInsensitiveContains(term) ?? false)
        }
    }

    private var sortedGroups: [MediaGroup] {
        viewModel.groups.sorted { lhs, rhs in
            let lhsCount = viewModel.items(in: lhs).count
            let rhsCount = viewModel.items(in: rhs).count
            if lhsCount == rhsCount {
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            return lhsCount > rhsCount
        }
    }

    @ViewBuilder
    private var contentSections: some View {
        switch selectedSection {
        case .home:
            if !viewModel.favorites.isEmpty {
                favoritesSection
            }
            if !viewModel.recents.isEmpty {
                recentsSection
            }
            if let profile = viewModel.activeProfile {
                loadedSourceSection(profile: profile)
            }
            if !viewModel.groups.isEmpty {
                Section {
                    ForEach(sortedGroups) { group in
                        NavigationLink {
                            ChannelListView(
                                group: group,
                                items: viewModel.items(in: group),
                                isFavorite: viewModel.isFavorite,
                                onToggleFavorite: viewModel.toggleFavorite,
                                onOpenItem: viewModel.registerRecent,
                                onOpenGroup: viewModel.recordGroupVisit
                            )
                        } label: {
                            GroupRow(group: group, count: viewModel.items(in: group).count)
                        }
                        .listRowBackground(Color.clear)
                    }
                } header: {
                    sectionHeader("Live Groups", subtitle: "Browse channel categories")
                }
            } else if viewModel.savedProfiles.isEmpty {
                emptyStateSection
            }

        case .favorites:
            favoritesScreenSection

        case .recents:
            recentsScreenSection

        case .search:
            if !viewModel.items.isEmpty {
                globalSearchSection
                searchResultsSection
            } else {
                Section {
                    contentEmptyCard(
                        title: "Search unlocks after loading a provider",
                        subtitle: "Load a saved profile or add a source, then use search to jump across all channels."
                    )
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

        case .source:
            if !viewModel.savedProfiles.isEmpty {
                savedProfilesSection
            }
            if let profile = viewModel.activeProfile {
                loadedSourceSection(profile: profile)
            }
            sourceSection
            statusSection
        }
    }

    private func contentEmptyCard(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AppPalette.secondaryText)
        }
        .cardStyle()
    }
}

private struct ChannelListView: View {
    let group: MediaGroup
    let items: [MediaItem]
    let isFavorite: (MediaItem) -> Bool
    let onToggleFavorite: (MediaItem) -> Void
    let onOpenItem: (MediaItem) -> Void
    let onOpenGroup: (MediaGroup) -> Void
    @State private var selectedRoute: ChannelRoute?
    @State private var searchText = ""

    var body: some View {
        ZStack {
            AppBackdrop()

            List(filteredItems) { item in
                Button {
                    if let index = filteredItems.firstIndex(of: item) {
                        onOpenItem(item)
                        selectedRoute = ChannelRoute(index: index)
                    }
                } label: {
                    ChannelRow(
                        item: item,
                        isFavorite: isFavorite(item),
                        onToggleFavorite: { onToggleFavorite(item) }
                    )
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
        .onAppear {
            onOpenGroup(group)
        }
        .navigationDestination(item: $selectedRoute) { route in
            ChannelDetailView(
                playlist: filteredItems,
                initialIndex: route.index,
                groupName: group.name,
                isFavorite: isFavorite,
                onToggleFavorite: onToggleFavorite,
                onOpenItem: onOpenItem
            )
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

private struct ResumeCard: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(colors: [AppPalette.gold, AppPalette.mint], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 52, height: 52)
                .overlay {
                    Image(systemName: "play.fill")
                        .font(.title3.weight(.black))
                        .foregroundStyle(.black.opacity(0.82))
                }

            VStack(alignment: .leading, spacing: 4) {
                Text("Resume Last Channel")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(AppPalette.gold)
                Text(title)
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppPalette.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "arrow.right.circle.fill")
                .font(.title2.weight(.bold))
                .foregroundStyle(AppPalette.mint)
        }
        .cardStyle()
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
    let isFavorite: (MediaItem) -> Bool
    let onToggleFavorite: (MediaItem) -> Void
    let onOpenItem: (MediaItem) -> Void
    @StateObject private var playerController = VLCPlayerController()
    @State private var currentIndex: Int
    @Environment(\.dismiss) private var dismiss

    init(
        playlist: [MediaItem],
        initialIndex: Int,
        groupName: String,
        isFavorite: @escaping (MediaItem) -> Bool,
        onToggleFavorite: @escaping (MediaItem) -> Void,
        onOpenItem: @escaping (MediaItem) -> Void
    ) {
        self.playlist = playlist
        self.initialIndex = initialIndex
        self.groupName = groupName
        self.isFavorite = isFavorite
        self.onToggleFavorite = onToggleFavorite
        self.onOpenItem = onOpenItem
        _currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        FullScreenPlayerView(
            title: currentItem.title,
            source: sourceOrNil,
            hasPreviousChannel: currentIndex > 0,
            hasNextChannel: currentIndex < playlist.count - 1,
            isFavorite: isFavorite(currentItem),
            playerController: playerController
        ) {
            dismissToBrowser()
        } onToggleFavorite: {
            onToggleFavorite(currentItem)
        } onPreviousChannel: {
            moveChannel(by: -1)
        } onNextChannel: {
            moveChannel(by: 1)
        }
        .onAppear {
            onOpenItem(currentItem)
        }
        .onDisappear {
            playerController.stop()
            playerController.detachOutput()
        }
    }

    private var currentItem: MediaItem {
        playlist[currentIndex]
    }

    private var sourceOrNil: PlaybackSource? {
        currentItem.source
    }

    private func moveChannel(by step: Int) {
        let nextIndex = currentIndex + step
        guard playlist.indices.contains(nextIndex) else {
            return
        }

        currentIndex = nextIndex
        onOpenItem(currentItem)
        if let source = currentItem.source {
            Task {
                await playerController.startPlayback(source: source, title: currentItem.title)
            }
        }
    }

    private func dismissToBrowser() {
        playerController.stop()
        playerController.detachOutput()
        dismiss()
    }
}

private struct FullScreenPlayerView: View {
    let title: String
    let source: PlaybackSource?
    let hasPreviousChannel: Bool
    let hasNextChannel: Bool
    let isFavorite: Bool
    @ObservedObject var playerController: VLCPlayerController
    let onBackToBrowser: () -> Void
    let onToggleFavorite: () -> Void
    let onPreviousChannel: () -> Void
    let onNextChannel: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var controlsVisible = true
    @State private var diagnosticsVisible = false
    @State private var autoHideTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VLCVideoSurfaceView(mediaPlayer: playerController.mediaPlayer)
                .ignoresSafeArea()
            Rectangle()
                .fill(Color.clear)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .highPriorityGesture(TapGesture().onEnded {
                    revealControls()
                })

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

            if diagnosticsVisible {
                VStack {
                    Spacer()
                    diagnosticsPanel
                        .padding(.horizontal, 20)
                        .padding(.bottom, controlsVisible ? 186 : 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .statusBarHidden(true)
        .onAppear {
            PlayerOrientationCoordinator.shared.requestLandscape()
            controlsVisible = true
            MediaSessionCoordinator.shared.configureRemoteCommands(
                onPlay: { playerController.resumePlayback() },
                onPause: { playerController.pausePlayback() },
                onTogglePlayPause: { playerController.togglePlayPause() },
                onNextTrack: hasNextChannel ? {
                    onNextChannel()
                } : nil,
                onPreviousTrack: hasPreviousChannel ? {
                    onPreviousChannel()
                } : nil
            )
            if let source {
                Task {
                    await playerController.startPlayback(source: source, title: title)
                }
            }
        }
        .onDisappear {
            autoHideTask?.cancel()
            MediaSessionCoordinator.shared.clearRemoteCommands()
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
                playerController.stop()
                playerController.detachOutput()
                dismiss()
                Task { @MainActor in
                    onBackToBrowser()
                }
            } label: {
                Image(systemName: "arrow.backward")
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

            Button {
                onToggleFavorite()
                revealControls()
            } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(isFavorite ? AppPalette.gold : .white)
                    .frame(width: 42, height: 42)
                    .background(.black.opacity(0.45), in: Circle())
            }

            Button {
                diagnosticsVisible.toggle()
                revealControls()
            } label: {
                Image(systemName: diagnosticsVisible ? "info.circle.fill" : "info.circle")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(.black.opacity(0.45), in: Circle())
            }

            AirPlayRoutePicker()
                .frame(width: 42, height: 42)
                .background(.black.opacity(0.45), in: Circle())

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
                    primaryAction()
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

            if let transportSummary = playerController.transportSummary {
                Text(transportSummary)
                    .font(.caption)
                    .foregroundStyle(AppPalette.gold)
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

    private var diagnosticsPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Playback Diagnostics")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)

            diagnosticRow("State", value: playerController.stateDescription)
            diagnosticRow("Channel", value: title)
            diagnosticRow("Host", value: source?.url.host ?? "Unknown")
            diagnosticRow("Scheme", value: source?.url.scheme?.uppercased() ?? "Unknown")
            diagnosticRow("Container", value: source?.containerHint?.uppercased() ?? "Unknown")
            diagnosticRow("Reconnects", value: "\(playerController.reconnectAttemptCount)")

            if let probeSummary = playerController.probeSummary {
                diagnosticRow("Probe", value: probeSummary)
            }

            if let transportSummary = playerController.transportSummary {
                diagnosticRow("Transport", value: transportSummary)
            }

            if let errorMessage = playerController.errorMessage {
                diagnosticRow("Error", value: errorMessage)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppPalette.card.opacity(0.96), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }

    private func diagnosticRow(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.caption2.weight(.heavy))
                .foregroundStyle(AppPalette.secondaryText)
            Text(value)
                .font(.caption)
                .foregroundStyle(.white)
                .textSelection(.enabled)
        }
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
        if playerController.errorMessage != nil {
            return "Retry"
        }

        switch playerController.stateDescription {
        case "Playing", "Buffering...", "Opening stream...", "Starting VLC...":
            return "Pause"
        case "Paused":
            return "Play"
        default:
            return "Play"
        }
    }

    private var primaryActionIcon: String {
        if playerController.errorMessage != nil {
            return "arrow.clockwise"
        }

        switch playerController.stateDescription {
        case "Playing", "Buffering...", "Opening stream...", "Starting VLC...":
            return "pause.fill"
        default:
            return "play.fill"
        }
    }

    private func primaryAction() {
        revealControls()

        if playerController.errorMessage != nil {
            Task { await playerController.retryPlayback() }
            return
        }

        switch playerController.stateDescription {
        case "Playing", "Buffering...", "Opening stream...", "Starting VLC...":
            playerController.pausePlayback()
        default:
            playerController.resumePlayback()
        }
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
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

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

            Button {
                onToggleFavorite()
            } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(isFavorite ? AppPalette.gold : AppPalette.secondaryText)
                    .frame(width: 40, height: 40)
                    .background(AppPalette.fieldFill, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .cardStyle()
    }
}

private struct MediaShortcutCard: View {
    let item: MediaItem
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.95), AppPalette.teal.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 46, height: 46)
                    .overlay {
                        Image(systemName: item.kind == .live ? "play.tv.fill" : "film.fill")
                            .font(.headline.weight(.black))
                            .foregroundStyle(.white)
                    }

                Spacer()

                if item.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppPalette.gold)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(item.groupID ?? "Saved Channel")
                    .font(.caption)
                    .foregroundStyle(AppPalette.secondaryText)
                    .lineLimit(1)
            }
        }
        .padding(18)
        .frame(width: 220, alignment: .leading)
        .background(AppPalette.card.opacity(0.96), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.24), radius: 18, x: 0, y: 10)
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
