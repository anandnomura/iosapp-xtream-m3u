import SwiftUI
import IPTVDomain

struct RootView: View {
    @ObservedObject var viewModel: RootViewModel

    var body: some View {
        NavigationStack {
            List {
                Section("Status") {
                    Text(viewModel.statusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Groups") {
                    ForEach(viewModel.groups) { group in
                        NavigationLink(group.name) {
                            ChannelListView(group: group, items: viewModel.items(in: group))
                        }
                    }
                }
            }
            .navigationTitle("1xtream-m3u")
        }
    }
}

private struct ChannelListView: View {
    let group: MediaGroup
    let items: [MediaItem]

    var body: some View {
        List(items) { item in
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)

                if let url = item.source?.url.absoluteString {
                    Text(url)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 4)
        }
        .navigationTitle(group.name)
    }
}

#Preview {
    RootView(viewModel: RootViewModel())
}
