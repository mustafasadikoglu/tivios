import Foundation

public final class AddPlaylistUseCase {
    private let playlistRepository: PlaylistRepositoryProtocol
    private let channelRepository: ChannelRepositoryProtocol
    private let vodRepository: VODRepositoryProtocol
    private let parserService: M3UParserServiceProtocol
    
    public init(
        playlistRepository: PlaylistRepositoryProtocol,
        channelRepository: ChannelRepositoryProtocol,
        vodRepository: VODRepositoryProtocol,
        parserService: M3UParserServiceProtocol
    ) {
        self.playlistRepository = playlistRepository
        self.channelRepository = channelRepository
        self.vodRepository = vodRepository
        self.parserService = parserService
    }
    
    public func execute(name: String, urlString: String) async throws -> Playlist {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "AddPlaylistUseCase", code: 400, userInfo: [NSLocalizedDescriptionKey: "Geçersiz URL adresi"])
        }
        
        let playlistId = UUID()
        let playlist = Playlist(id: playlistId, name: name, url: url)
        
        // 1. M3U dosyasını indir ve içerikleri ayrıştır (canlı / film / dizi)
        let result = try await parserService.parseClassified(url: url, playlistId: playlistId)
        
        // 2. Oynatma listesini kaydet
        try await playlistRepository.addPlaylist(playlist)
        
        // 3. Canlı kanalları kaydet
        try await channelRepository.saveChannels(result.channels, for: playlistId)
        
        // 4. Filmleri kaydet
        if !result.movies.isEmpty {
            try await vodRepository.saveMovies(result.movies, for: playlistId)
        }
        
        // 5. Dizileri kaydet
        if !result.series.isEmpty {
            try await vodRepository.saveSeries(result.series, for: playlistId)
        }
        
        return playlist
    }
}
