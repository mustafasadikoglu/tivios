import Foundation

public protocol M3UParserServiceProtocol {
    func parse(content: String, playlistId: UUID) throws -> [Channel]
    func parse(url: URL, playlistId: UUID) async throws -> [Channel]
}
