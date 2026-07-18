import Foundation

public final class ChannelRepository: ChannelRepositoryProtocol {
    private let localStorage: LocalStorageService
    
    public init(localStorage: LocalStorageService) {
        self.localStorage = localStorage
    }
    
    public func fetchChannels(for playlistId: UUID) async throws -> [Channel] {
        return try localStorage.fetchChannels(for: playlistId)
    }
    
    public func saveChannels(_ channels: [Channel], for playlistId: UUID) async throws {
        try localStorage.saveChannels(channels, for: playlistId)
    }
    
    public func deleteChannels(for playlistId: UUID) async throws {
        try localStorage.deleteChannels(for: playlistId)
    }
    
    public func toggleFavorite(channelId: String, playlistId: UUID) async throws -> Channel {
        var channels = try localStorage.fetchChannels(for: playlistId)
        guard let index = channels.firstIndex(where: { $0.id == channelId }) else {
            throw NSError(domain: "ChannelRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Kanal bulunamadı"])
        }
        
        channels[index].isFavorite.toggle()
        try localStorage.saveChannels(channels, for: playlistId)
        return channels[index]
    }
    
    public func fetchFavoriteChannels() async throws -> [Channel] {
        let playlists = try localStorage.fetchPlaylists()
        var favorites: [Channel] = []
        for playlist in playlists {
            let channels = try localStorage.fetchChannels(for: playlist.id)
            favorites.append(contentsOf: channels.filter { $0.isFavorite })
        }
        return favorites
    }
    
    public func fetchRecentChannels() async throws -> [Channel] {
        return try localStorage.fetchRecentChannels()
    }
    
    public func saveRecentChannel(_ channel: Channel) async throws {
        try localStorage.saveRecentChannel(channel)
    }
}
