import Foundation

public final class PlaylistRepository: PlaylistRepositoryProtocol {
    private let localStorage: LocalStorageService
    
    public init(localStorage: LocalStorageService) {
        self.localStorage = localStorage
    }
    
    public func fetchPlaylists() async throws -> [Playlist] {
        return try localStorage.fetchPlaylists()
    }
    
    public func addPlaylist(_ playlist: Playlist) async throws {
        var playlists = try localStorage.fetchPlaylists()
        playlists.append(playlist)
        try localStorage.savePlaylists(playlists)
    }
    
    public func deletePlaylist(id: UUID) async throws {
        var playlists = try localStorage.fetchPlaylists()
        playlists.removeAll { $0.id == id }
        try localStorage.savePlaylists(playlists)
    }
}
