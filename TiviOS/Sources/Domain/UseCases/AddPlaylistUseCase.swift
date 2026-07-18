import Foundation

public final class AddPlaylistUseCase {
    private let playlistRepository: PlaylistRepositoryProtocol
    private let channelRepository: ChannelRepositoryProtocol
    private let parserService: M3UParserServiceProtocol
    
    public init(
        playlistRepository: PlaylistRepositoryProtocol,
        channelRepository: ChannelRepositoryProtocol,
        parserService: M3UParserServiceProtocol
    ) {
        self.playlistRepository = playlistRepository
        self.channelRepository = channelRepository
        self.parserService = parserService
    }
    
    public func execute(name: String, urlString: String) async throws -> Playlist {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "AddPlaylistUseCase", code: 400, userInfo: [NSLocalizedDescriptionKey: "Geçersiz URL adresi"])
        }
        
        let playlistId = UUID()
        let playlist = Playlist(id: playlistId, name: name, url: url)
        
        // 1. M3U dosyasını indir ve kanalları ayrıştır
        let channels = try await parserService.parse(url: url, playlistId: playlistId)
        
        // 2. Oynatma listesini kaydet
        try await playlistRepository.addPlaylist(playlist)
        
        // 3. Kanalları kaydet
        try await channelRepository.saveChannels(channels, for: playlistId)
        
        return playlist
    }
}
