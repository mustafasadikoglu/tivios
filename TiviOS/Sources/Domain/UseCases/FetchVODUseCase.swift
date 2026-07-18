import Foundation

public final class FetchVODUseCase {
    private let vodRepository: VODRepositoryProtocol
    private let xtreamService: XtreamCodesServiceProtocol
    
    public init(vodRepository: VODRepositoryProtocol, xtreamService: XtreamCodesServiceProtocol) {
        self.vodRepository = vodRepository
        self.xtreamService = xtreamService
    }
    
    public func fetchMovies(for playlistId: UUID) async throws -> [VODMovie] {
        return try await vodRepository.fetchMovies(for: playlistId)
    }
    
    public func fetchSeries(for playlistId: UUID) async throws -> [VODSeries] {
        return try await vodRepository.fetchSeries(for: playlistId)
    }
    
    public func fetchEpisodes(for seriesId: String, playlist: Playlist) async throws -> [VODEpisode] {
        let cached = try await vodRepository.fetchEpisodes(for: seriesId, playlistId: playlist.id)
        if !cached.isEmpty {
            return cached
        }
        
        if playlist.type == .xtream,
           let host = playlist.xtreamHost,
           let user = playlist.xtreamUsername,
           let pass = playlist.xtreamPassword {
            let remote = try await xtreamService.fetchEpisodes(host: host, username: user, password: pass, seriesId: seriesId)
            try await vodRepository.saveEpisodes(remote, for: seriesId, playlistId: playlist.id)
            return remote
        }
        
        return []
    }
}
