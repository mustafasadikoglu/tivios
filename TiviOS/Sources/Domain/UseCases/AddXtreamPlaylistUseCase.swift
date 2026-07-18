import Foundation

public final class AddXtreamPlaylistUseCase {
    private let playlistRepository: PlaylistRepositoryProtocol
    private let channelRepository: ChannelRepositoryProtocol
    private let vodRepository: VODRepositoryProtocol
    private let xtreamService: XtreamCodesServiceProtocol
    
    public init(
        playlistRepository: PlaylistRepositoryProtocol,
        channelRepository: ChannelRepositoryProtocol,
        vodRepository: VODRepositoryProtocol,
        xtreamService: XtreamCodesServiceProtocol
    ) {
        self.playlistRepository = playlistRepository
        self.channelRepository = channelRepository
        self.vodRepository = vodRepository
        self.xtreamService = xtreamService
    }
    
    public func execute(name: String, host: String, username: String, password: String) async throws -> Playlist {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
              !host.trimmingCharacters(in: .whitespaces).isEmpty,
              !username.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw NSError(domain: "AddXtreamPlaylistUseCase", code: 400, userInfo: [NSLocalizedDescriptionKey: "Eksik hesap bilgileri girdiniz"])
        }
        
        let playlistId = UUID()
        let playlist = Playlist(
            id: playlistId,
            name: name,
            type: .xtream,
            xtreamUsername: username,
            xtreamPassword: password,
            xtreamHost: host
        )
        
        // 1. Fetch live channels
        let channels = try await xtreamService.fetchChannels(
            host: host,
            username: username,
            password: password,
            playlistId: playlistId
        )
        
        // 2. Fetch movies & series (VOD)
        let movies = (try? await xtreamService.fetchMovies(host: host, username: username, password: password, playlistId: playlistId)) ?? []
        let series = (try? await xtreamService.fetchSeries(host: host, username: username, password: password, playlistId: playlistId)) ?? []
        
        // 3. Save
        try await playlistRepository.addPlaylist(playlist)
        try await channelRepository.saveChannels(channels, for: playlistId)
        try await vodRepository.saveMovies(movies, for: playlistId)
        try await vodRepository.saveSeries(series, for: playlistId)
        
        return playlist
    }
}
