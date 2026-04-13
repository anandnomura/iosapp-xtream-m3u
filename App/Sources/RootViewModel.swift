import Foundation
import IPTVDomain
import IPTVData

@MainActor
final class RootViewModel: ObservableObject {
    @Published private(set) var groups: [MediaGroup] = []
    @Published private(set) var items: [MediaItem] = []
    @Published private(set) var statusMessage = "Loading sample data..."

    private let parser = M3UParser()
    private let providerID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!

    init() {
        loadSamplePlaylist()
    }

    func loadSamplePlaylist() {
        do {
            let parsed = try parser.parse(text: Self.samplePlaylist, providerID: providerID)
            groups = parsed.groups
            items = parsed.items
            statusMessage = "Sample playlist loaded"
        } catch {
            groups = []
            items = []
            statusMessage = "Unable to parse sample playlist"
        }
    }

    func items(in group: MediaGroup) -> [MediaItem] {
        items.filter { $0.groupID == group.id }
    }

    private static let samplePlaylist = """
    #EXTM3U
    #EXTINF:-1 tvg-id="news-one" tvg-name="News One" tvg-logo="https://example.com/news.png" group-title="News",News One HD
    https://stream.example.com/live/news-one.m3u8
    #EXTINF:-1 tvg-id="sports-one" tvg-name="Sports One" tvg-logo="https://example.com/sports.png" group-title="Sports",Sports One
    https://stream.example.com/live/sports-one.m3u8
    #EXTINF:-1 tvg-id="movies-one" tvg-name="Movies One" tvg-logo="https://example.com/movies.png" group-title="Movies",Movies One
    https://stream.example.com/live/movies-one.m3u8
    """
}
