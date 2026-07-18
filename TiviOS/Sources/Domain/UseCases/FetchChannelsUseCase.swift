import Foundation

public final class FetchChannelsUseCase {
    private let channelRepository: ChannelRepositoryProtocol
    
    public init(channelRepository: ChannelRepositoryProtocol) {
        self.channelRepository = channelRepository
    }
    
    public func execute(for playlistId: UUID) async throws -> [ChannelGroup] {
        let channels = try await channelRepository.fetchChannels(for: playlistId)
        return groupChannels(channels)
    }
    
    public func fetchFavorites() async throws -> [Channel] {
        return try await channelRepository.fetchFavoriteChannels()
    }
    
    public func toggleFavorite(channelId: String, playlistId: UUID) async throws -> Channel {
        return try await channelRepository.toggleFavorite(channelId: channelId, playlistId: playlistId)
    }
    
    private func groupChannels(_ channels: [Channel]) -> [ChannelGroup] {
        let grouped = Dictionary(grouping: channels, by: { $0.groupTitle.isEmpty ? "Diğer" : $0.groupTitle })
        return grouped.map { ChannelGroup(name: $0.key, channels: $0.value.sorted(by: { $0.name < $1.name })) }
            .sorted(by: { $0.name < $1.name })
    }
}
