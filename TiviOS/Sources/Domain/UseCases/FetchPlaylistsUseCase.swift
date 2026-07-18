import Foundation

public final class FetchPlaylistsUseCase {
    private let playlistRepository: PlaylistRepositoryProtocol
    
    public init(playlistRepository: PlaylistRepositoryProtocol) {
        self.playlistRepository = playlistRepository
    }
    
    public func execute() async throws -> [Playlist] {
        return try await playlistRepository.fetchPlaylists()
    }
}
