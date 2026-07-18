import Foundation

public final class DependencyContainer: ObservableObject {
    // Services & Storage
    private let localStorage: LocalStorageService
    private let parserService: M3UParserServiceProtocol
    private let xtreamService: XtreamCodesServiceProtocol
    private let epgService: EPGServiceProtocol
    
    // Repositories
    private let playlistRepository: PlaylistRepositoryProtocol
    private let channelRepository: ChannelRepositoryProtocol
    private let vodRepository: VODRepositoryProtocol
    
    // Use Cases
    private let fetchPlaylistsUseCase: FetchPlaylistsUseCase
    private let addPlaylistUseCase: AddPlaylistUseCase
    private let addXtreamPlaylistUseCase: AddXtreamPlaylistUseCase
    private let deletePlaylistUseCase: DeletePlaylistUseCase
    private let fetchChannelsUseCase: FetchChannelsUseCase
    private let fetchEPGUseCase: FetchEPGUseCase
    private let manageRecentsUseCase: ManageRecentsUseCase
    private let globalSearchUseCase: GlobalSearchUseCase
    private let fetchVODUseCase: FetchVODUseCase
    
    public init() {
        self.localStorage = LocalStorageService()
        self.parserService = M3UParserService()
        self.xtreamService = XtreamCodesService()
        self.epgService = EPGParserService()
        
        self.playlistRepository = PlaylistRepository(localStorage: localStorage)
        self.channelRepository = ChannelRepository(localStorage: localStorage)
        self.vodRepository = VODRepository()
        
        self.fetchPlaylistsUseCase = FetchPlaylistsUseCase(playlistRepository: playlistRepository)
        self.addPlaylistUseCase = AddPlaylistUseCase(
            playlistRepository: playlistRepository,
            channelRepository: channelRepository,
            parserService: parserService
        )
        self.addXtreamPlaylistUseCase = AddXtreamPlaylistUseCase(
            playlistRepository: playlistRepository,
            channelRepository: channelRepository,
            vodRepository: vodRepository,
            xtreamService: xtreamService
        )
        self.deletePlaylistUseCase = DeletePlaylistUseCase(
            playlistRepository: playlistRepository,
            channelRepository: channelRepository,
            vodRepository: vodRepository
        )
        self.fetchChannelsUseCase = FetchChannelsUseCase(channelRepository: channelRepository)
        self.fetchEPGUseCase = FetchEPGUseCase(epgService: epgService)
        self.manageRecentsUseCase = ManageRecentsUseCase(channelRepository: channelRepository)
        self.globalSearchUseCase = GlobalSearchUseCase(
            playlistRepository: playlistRepository,
            channelRepository: channelRepository
        )
        self.fetchVODUseCase = FetchVODUseCase(
            vodRepository: vodRepository,
            xtreamService: xtreamService
        )
    }
    
    // MARK: - View Model Factories
    
    @MainActor
    public func makePlaylistListViewModel() -> PlaylistListViewModel {
        return PlaylistListViewModel(
            fetchPlaylistsUseCase: fetchPlaylistsUseCase,
            addPlaylistUseCase: addPlaylistUseCase,
            addXtreamPlaylistUseCase: addXtreamPlaylistUseCase,
            deletePlaylistUseCase: deletePlaylistUseCase,
            manageRecentsUseCase: manageRecentsUseCase,
            globalSearchUseCase: globalSearchUseCase
        )
    }
    
    @MainActor
    public func makeChannelListViewModel(playlist: Playlist) -> ChannelListViewModel {
        return ChannelListViewModel(
            playlist: playlist,
            fetchChannelsUseCase: fetchChannelsUseCase,
            fetchEPGUseCase: fetchEPGUseCase,
            manageRecentsUseCase: manageRecentsUseCase,
            fetchVODUseCase: fetchVODUseCase
        )
    }
    
    @MainActor
    public func makeVODSeriesDetailViewModel(series: VODSeries) -> VODSeriesDetailViewModel {
        let playlists = (try? localStorage.fetchPlaylists()) ?? []
        let playlist = playlists.first { $0.id == series.playlistId } ?? Playlist(name: "", type: .m3u)
        
        return VODSeriesDetailViewModel(
            series: series,
            playlist: playlist,
            fetchVODUseCase: fetchVODUseCase
        )
    }
    
    @MainActor
    public func makePlayerViewModel(channel: Channel) -> PlayerViewModel {
        return PlayerViewModel(channel: channel)
    }
}
