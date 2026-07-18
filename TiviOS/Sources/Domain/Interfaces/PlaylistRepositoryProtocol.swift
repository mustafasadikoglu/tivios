import Foundation

public protocol PlaylistRepositoryProtocol {
    func fetchPlaylists() async throws -> [Playlist]
    func addPlaylist(_ playlist: Playlist) async throws
    func deletePlaylist(id: UUID) async throws
}
