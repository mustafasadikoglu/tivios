import Foundation

public final class DeletePlaylistUseCase {
    private let playlistRepository: PlaylistRepositoryProtocol
    private let channelRepository: ChannelRepositoryProtocol
    private let vodRepository: VODRepositoryProtocol
    
    public init(
        playlistRepository: PlaylistRepositoryProtocol,
        channelRepository: ChannelRepositoryProtocol,
        vodRepository: VODRepositoryProtocol
    ) {
        self.playlistRepository = playlistRepository
        self.channelRepository = channelRepository
        self.vodRepository = vodRepository
    }
    
    public func execute(id: UUID) async throws {
        try await channelRepository.deleteChannels(for: id)
        try await vodRepository.deleteVODData(for: id)
        try await playlistRepository.deletePlaylist(id: id)
    }
}
