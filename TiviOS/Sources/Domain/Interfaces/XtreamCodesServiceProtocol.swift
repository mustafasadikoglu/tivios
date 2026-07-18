import Foundation

public protocol XtreamCodesServiceProtocol {
    func fetchChannels(host: String, username: String, password: String, playlistId: UUID) async throws -> [Channel]
    func fetchMovies(host: String, username: String, password: String, playlistId: UUID) async throws -> [VODMovie]
    func fetchSeries(host: String, username: String, password: String, playlistId: UUID) async throws -> [VODSeries]
    func fetchEpisodes(host: String, username: String, password: String, seriesId: String) async throws -> [VODEpisode]
}
