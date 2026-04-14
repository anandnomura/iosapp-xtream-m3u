import Foundation
import IPTVDomain

public enum XMLTVParserError: Error, Equatable {
    case invalidDocument
    case invalidDate(String)
}

public struct XMLTVParser: Sendable {
    public init() {}

    public func parse(data: Data) throws -> ParsedEPG {
        let delegate = XMLTVParserDelegate()
        let parser = Foundation.XMLParser(data: data)
        parser.delegate = delegate

        guard parser.parse() else {
            if let dateError = delegate.dateError {
                throw dateError
            }
            throw XMLTVParserError.invalidDocument
        }

        if let dateError = delegate.dateError {
            throw dateError
        }

        return ParsedEPG(
            channels: delegate.channels.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending },
            programmes: delegate.programmes.sorted { $0.startDate < $1.startDate }
        )
    }
}

private final class XMLTVParserDelegate: NSObject, Foundation.XMLParserDelegate {
    private(set) var channels: [EPGChannel] = []
    private(set) var programmes: [EPGProgramme] = []
    private(set) var dateError: XMLTVParserError?

    private var currentElement = ""
    private var textBuffer = ""
    private var pendingChannelID: String?
    private var pendingChannelName: String?
    private var pendingProgrammeChannelID: String?
    private var pendingProgrammeStart: Date?
    private var pendingProgrammeEnd: Date?
    private var pendingProgrammeTitle: String?
    private var pendingProgrammeSubtitle: String?
    private var pendingProgrammeSummary: String?

    func parser(
        _ parser: Foundation.XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        currentElement = elementName
        textBuffer = ""

        switch elementName {
        case "channel":
            pendingChannelID = attributeDict["id"]
            pendingChannelName = nil

        case "programme":
            pendingProgrammeChannelID = attributeDict["channel"]
            pendingProgrammeTitle = nil
            pendingProgrammeSubtitle = nil
            pendingProgrammeSummary = nil

            if let rawStart = attributeDict["start"] {
                pendingProgrammeStart = parseXMLTVDate(rawStart)
                if pendingProgrammeStart == nil {
                    dateError = .invalidDate(rawStart)
                    parser.abortParsing()
                    return
                }
            }

            if let rawEnd = attributeDict["stop"] {
                pendingProgrammeEnd = parseXMLTVDate(rawEnd)
                if pendingProgrammeEnd == nil {
                    dateError = .invalidDate(rawEnd)
                    parser.abortParsing()
                    return
                }
            }

        default:
            break
        }
    }

    func parser(_ parser: Foundation.XMLParser, foundCharacters string: String) {
        textBuffer += string
    }

    func parser(
        _ parser: Foundation.XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let trimmed = textBuffer.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName {
        case "display-name" where pendingChannelID != nil && pendingChannelName == nil && !trimmed.isEmpty:
            pendingChannelName = trimmed

        case "title" where pendingProgrammeChannelID != nil && !trimmed.isEmpty:
            pendingProgrammeTitle = trimmed

        case "sub-title" where pendingProgrammeChannelID != nil && !trimmed.isEmpty:
            pendingProgrammeSubtitle = trimmed

        case "desc" where pendingProgrammeChannelID != nil && !trimmed.isEmpty:
            pendingProgrammeSummary = trimmed

        case "channel":
            if let id = pendingChannelID, let name = pendingChannelName, !name.isEmpty {
                channels.append(EPGChannel(id: id, displayName: name))
            }
            pendingChannelID = nil
            pendingChannelName = nil

        case "programme":
            if let channelID = pendingProgrammeChannelID,
               let start = pendingProgrammeStart,
               let end = pendingProgrammeEnd,
               let title = pendingProgrammeTitle,
               !title.isEmpty {
                let identifier = "\(channelID)::\(start.timeIntervalSince1970)::\(title)"
                programmes.append(
                    EPGProgramme(
                        id: identifier,
                        channelID: channelID,
                        title: title,
                        subtitle: pendingProgrammeSubtitle,
                        summary: pendingProgrammeSummary,
                        startDate: start,
                        endDate: end
                    )
                )
            }

            pendingProgrammeChannelID = nil
            pendingProgrammeStart = nil
            pendingProgrammeEnd = nil
            pendingProgrammeTitle = nil
            pendingProgrammeSubtitle = nil
            pendingProgrammeSummary = nil

        default:
            break
        }

        currentElement = ""
        textBuffer = ""
    }

    private func parseXMLTVDate(_ value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 14 else {
            return nil
        }

        let compact = String(trimmed.prefix(14))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMddHHmmss"
        return formatter.date(from: compact)
    }
}
