import SwiftUI
import IPTVDomain

struct RootView: View {
    @ObservedObject var viewModel: RootViewModel

    var body: some View {
        NavigationStack {
            List {
                sourceSection

                if let errorMessage = viewModel.errorMessage {
                    Section("Issue") {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                if let profile = viewModel.activeProfile {
                    Section("Loaded Source") {
                        LabeledContent("Name", value: profile.name)
                        LabeledContent("Type", value: profile.kind.rawValue.uppercased())
                        LabeledContent("Channels", value: "\(viewModel.items.count)")
                    }
                }

                Section("Status") {
                    Text(viewModel.statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if !viewModel.groups.isEmpty {
                    Section("Groups") {
                        ForEach(viewModel.groups) { group in
                            NavigationLink {
                                ChannelListView(group: group, items: viewModel.items(in: group))
                            } label: {
                                HStack {
                                    Text(group.name)
                                    Spacer()
                                    Text("\(viewModel.items(in: group).count)")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("1xtream-m3u")
        }
    }

    private var sourceSection: some View {
        Section("Source") {
            Picker("Mode", selection: $viewModel.sourceMode) {
                ForEach(RootViewModel.SourceMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            TextField("Profile name", text: $viewModel.profileName)
                .textInputAutocapitalization(.words)

            switch viewModel.sourceMode {
            case .m3uURL:
                TextField("https://example.com/playlist.m3u", text: $viewModel.m3uURLString)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()

            case .m3uText:
                VStack(alignment: .leading, spacing: 8) {
                    Text("Paste playlist text")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextEditor(text: $viewModel.rawM3UText)
                        .frame(minHeight: 160)
                        .font(.system(.footnote, design: .monospaced))
                }

            case .xtream:
                TextField("provider.example.com", text: $viewModel.xtreamHostString)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()

                TextField("Username", text: $viewModel.xtreamUsername)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("Password", text: $viewModel.xtreamPassword)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Button {
                Task {
                    await viewModel.loadChannels()
                }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    Text(viewModel.isLoading ? "Loading..." : "Load Channels")
                }
                .frame(maxWidth: .infinity)
            }
            .disabled(viewModel.isLoading)
        }
    }
}

private struct ChannelListView: View {
    let group: MediaGroup
    let items: [MediaItem]

    var body: some View {
        List(items) { item in
            NavigationLink {
                ChannelDetailView(item: item)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)

                    if let container = item.source?.containerHint, !container.isEmpty {
                        Text(container.uppercased())
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle(group.name)
    }
}

private struct ChannelDetailView: View {
    let item: MediaItem

    var body: some View {
        List {
            Section("Channel") {
                LabeledContent("Title", value: item.title)
                LabeledContent("ID", value: item.id)
                LabeledContent("Kind", value: item.kind.rawValue)
            }

            if let source = item.source {
                Section("Playback Source") {
                    Text(source.url.absoluteString)
                        .textSelection(.enabled)
                        .font(.footnote)
                    if let hint = source.containerHint {
                        LabeledContent("Container", value: hint)
                    }
                }
            }

            if let posterURL = item.artwork.posterURL?.absoluteString {
                Section("Artwork") {
                    Text(posterURL)
                        .textSelection(.enabled)
                        .font(.footnote)
                }
            }
        }
        .navigationTitle(item.title)
    }
}

#Preview {
    RootView(viewModel: RootViewModel())
}
