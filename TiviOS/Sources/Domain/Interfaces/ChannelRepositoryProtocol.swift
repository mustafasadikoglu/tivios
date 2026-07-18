import Foundation

public protocol ChannelRepositoryProtocol {
    func fetchChannels(for playlistId: UUID) async throws -> [Channel]
    func saveChannels(_ channels: [Channel], for playlistId: UUID) async throws
    func deleteChannels(for playlistId: UUID) async throws
    func toggleFavorite(channelId: String, playlistId: UUID) async throws -> Channel
    func fetchFavoriteChannels() async throws -> [Channel]
    func fetchRecentChannels() async throws -> [Channel]
    func saveRecentChannel(_ channel: Channel) async throws
}
