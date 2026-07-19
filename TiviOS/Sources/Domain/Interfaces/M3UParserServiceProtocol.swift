import Foundation

/// Parsed M3U output split by content type
public struct M3UParseResult {
    public let channels: [Channel]
    public let movies: [VODMovie]
    public let series: [VODSeries]
}

public protocol M3UParserServiceProtocol {
    func parse(content: String, playlistId: UUID) throws -> [Channel]
    func parse(url: URL, playlistId: UUID) async throws -> [Channel]
    
    /// Enhanced parser that classifies content into live, movie, and series
    func parseClassified(content: String, playlistId: UUID) throws -> M3UParseResult
    func parseClassified(url: URL, playlistId: UUID) async throws -> M3UParseResult
}
