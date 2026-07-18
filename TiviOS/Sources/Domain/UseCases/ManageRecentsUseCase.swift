import Foundation

public final class ManageRecentsUseCase {
    private let channelRepository: ChannelRepositoryProtocol
    
    public init(channelRepository: ChannelRepositoryProtocol) {
        self.channelRepository = channelRepository
    }
    
    public func fetchRecents() async throws -> [Channel] {
        return try await channelRepository.fetchRecentChannels()
    }
    
    public func saveRecent(_ channel: Channel) async throws {
        try await channelRepository.saveRecentChannel(channel)
    }
}
