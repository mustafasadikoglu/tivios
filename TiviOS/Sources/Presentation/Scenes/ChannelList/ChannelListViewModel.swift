import Foundation
import Combine

@MainActor
public final class ChannelListViewModel: ObservableObject {
    public let playlist: Playlist
    
    @Published public var selectedTab: MediaContentType = .live
    
    // Live TV data
    @Published public var groups: [ChannelGroup] = []
    @Published public var filteredGroups: [ChannelGroup] = []
    @Published public var epgPrograms: [EPGProgram] = []
    
    // VOD data
    @Published public var movies: [VODMovie] = []
    @Published public var filteredMovies: [VODMovie] = []
    @Published public var seriesList: [VODSeries] = []
    @Published public var filteredSeries: [VODSeries] = []
    
    @Published public var searchQuery = ""
    @Published public var selectedGroup: String? = nil
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    
    private let fetchChannelsUseCase: FetchChannelsUseCase
    private let fetchEPGUseCase: FetchEPGUseCase
    private let manageRecentsUseCase: ManageRecentsUseCase
    private let fetchVODUseCase: FetchVODUseCase
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        playlist: Playlist,
        fetchChannelsUseCase: FetchChannelsUseCase,
        fetchEPGUseCase: FetchEPGUseCase,
        manageRecentsUseCase: ManageRecentsUseCase,
        fetchVODUseCase: FetchVODUseCase
    ) {
        self.playlist = playlist
        self.fetchChannelsUseCase = fetchChannelsUseCase
        self.fetchEPGUseCase = fetchEPGUseCase
        self.manageRecentsUseCase = manageRecentsUseCase
        self.fetchVODUseCase = fetchVODUseCase
        
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }
    
    public func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            // Load Live TV Channels
            groups = try await fetchChannelsUseCase.execute(for: playlist.id)
            
            // Try to load EPG
            if let epgUrl = playlist.url?.deletingLastPathComponent().appendingPathComponent("epg.xml") {
                epgPrograms = (try? await fetchEPGUseCase.execute(url: epgUrl)) ?? []
            }
            
            // Load VOD Movies & Series
            movies = (try? await fetchVODUseCase.fetchMovies(for: playlist.id)) ?? []
            seriesList = (try? await fetchVODUseCase.fetchSeries(for: playlist.id)) ?? []
            
            applyFilters()
        } catch {
            errorMessage = "Veriler yüklenirken hata oluştu: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    public func toggleFavorite(_ channel: Channel) async {
        do {
            _ = try await fetchChannelsUseCase.toggleFavorite(channelId: channel.id, playlistId: playlist.id)
            await loadData() // Refresh
        } catch {
            errorMessage = "Favori durumu güncellenemedi: \(error.localizedDescription)"
        }
    }
    
    public func playChannel(_ channel: Channel) async {
        try? await manageRecentsUseCase.saveRecent(channel)
    }
    
    public func getCurrentProgramName(for channelId: String) -> String? {
        return fetchEPGUseCase.getCurrentProgram(for: channelId, from: epgPrograms)?.title
    }
    
    public func selectGroup(_ groupName: String?) {
        selectedGroup = groupName
        applyFilters()
    }
    
    private func applyFilters() {
        // 1. Filter Live Channels
        var resultGroups = groups
        if let selectedGroup = selectedGroup {
            resultGroups = resultGroups.filter { $0.name == selectedGroup }
        }
        if !searchQuery.isEmpty {
            resultGroups = resultGroups.map { group in
                let filteredChannels = group.channels.filter { channel in
                    channel.name.localizedCaseInsensitiveContains(searchQuery)
                }
                return ChannelGroup(name: group.name, channels: filteredChannels)
            }.filter { !$0.channels.isEmpty }
        }
        filteredGroups = resultGroups
        
        // 2. Filter Movies
        if searchQuery.isEmpty {
            filteredMovies = movies
        } else {
            filteredMovies = movies.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
        }
        
        // 3. Filter Series
        if searchQuery.isEmpty {
            filteredSeries = seriesList
        } else {
            filteredSeries = seriesList.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
        }
    }
}
