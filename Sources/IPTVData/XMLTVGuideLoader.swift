import Foundation
import IPTVDomain

public struct XMLTVGuideLoader: Sendable {
    private let parser: XMLTVParser
    private let session: URLSession

    public init(parser: XMLTVParser = XMLTVParser(), session: URLSession = .shared) {
        self.parser = parser
        self.session = session
    }

    public func load(source: PlaylistSource) async throws -> ParsedEPG {
        if let rawText = source.rawText, !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return try parser.parse(data: Data(rawText.utf8))
        }

        guard let remoteURL = source.remoteURL else {
            throw PlaylistLoaderError.missingSource
        }

        let (data, response) = try await session.data(from: remoteURL)
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            throw PlaylistLoaderError.invalidResponse
        }

        return try parser.parse(data: data)
    }
}
