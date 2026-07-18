import Foundation

public enum ResolutionFilter: String, CaseIterable {
    case all = "Tümü"
    case only4K = "4K"
    case onlyHD = "HD / FHD"
}

public final class GlobalSearchUseCase {
    private let playlistRepository: PlaylistRepositoryProtocol
    private let channelRepository: ChannelRepositoryProtocol
    
    public init(playlistRepository: PlaylistRepositoryProtocol, channelRepository: ChannelRepositoryProtocol) {
        self.playlistRepository = playlistRepository
        self.channelRepository = channelRepository
    }
    
    public func execute(query: String, resolution: ResolutionFilter) async throws -> [Channel] {
        let playlists = try await playlistRepository.fetchPlaylists()
        var allChannels: [Channel] = []
        
        for playlist in playlists {
            let channels = try await channelRepository.fetchChannels(for: playlist.id)
            allChannels.append(contentsOf: channels)
        }
        
        // 1. Text filter
        var filtered = allChannels
        if !query.trimmingCharacters(in: .whitespaces).isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(query) }
        }
        
        // 2. Resolution filter
        switch resolution {
        case .all:
            break
        case .only4K:
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains("4K") || $0.name.localizedCaseInsensitiveContains("uhd") }
        case .onlyHD:
            filtered = filtered.filter { 
                $0.name.localizedCaseInsensitiveContains("HD") || 
                $0.name.localizedCaseInsensitiveContains("FHD") || 
                $0.name.localizedCaseInsensitiveContains("1080p") || 
                $0.name.localizedCaseInsensitiveContains("720p")
            }
        }
        
        return filtered
    }
}
