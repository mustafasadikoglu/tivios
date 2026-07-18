import Foundation
import Combine

@MainActor
public final class PlaylistListViewModel: ObservableObject {
    @Published public var playlists: [Playlist] = []
    @Published public var recents: [Channel] = []
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    
    @Published public var showAddPlaylistSheet = false
    @Published public var addPlaylistType: PlaylistType = .m3u
    
    // M3U parameters
    @Published public var newPlaylistName = ""
    @Published public var newPlaylistUrl = ""
    
    // Xtream parameters
    @Published public var xtreamHost = ""
    @Published public var xtreamUsername = ""
    @Published public var xtreamPassword = ""
    
    // Global Search parameters
    @Published public var globalSearchQuery = ""
    @Published public var selectedResolution: ResolutionFilter = .all
    @Published public var globalSearchResults: [Channel] = []
    
    private let fetchPlaylistsUseCase: FetchPlaylistsUseCase
    private let addPlaylistUseCase: AddPlaylistUseCase
    private let addXtreamPlaylistUseCase: AddXtreamPlaylistUseCase
    private let deletePlaylistUseCase: DeletePlaylistUseCase
    private let manageRecentsUseCase: ManageRecentsUseCase
    private let globalSearchUseCase: GlobalSearchUseCase
    
    // UUID token to track and debounce searches
    private var currentSearchId: UUID?
    
    public init(
        fetchPlaylistsUseCase: FetchPlaylistsUseCase,
        addPlaylistUseCase: AddPlaylistUseCase,
        addXtreamPlaylistUseCase: AddXtreamPlaylistUseCase,
        deletePlaylistUseCase: DeletePlaylistUseCase,
        manageRecentsUseCase: ManageRecentsUseCase,
        globalSearchUseCase: GlobalSearchUseCase
    ) {
        self.fetchPlaylistsUseCase = fetchPlaylistsUseCase
        self.addPlaylistUseCase = addPlaylistUseCase
        self.addXtreamPlaylistUseCase = addXtreamPlaylistUseCase
        self.deletePlaylistUseCase = deletePlaylistUseCase
        self.manageRecentsUseCase = manageRecentsUseCase
        self.globalSearchUseCase = globalSearchUseCase
    }
    
    // Pure async debounced search (no escaping closures or Task state)
    public func search(query: String, resolution: ResolutionFilter? = nil) async {
        let newId = UUID()
        self.currentSearchId = newId
        
        let targetResolution = resolution ?? selectedResolution
        
        // Debounce for 300ms (explicitly cast to UInt64 to prevent compiler literal conversion issues)
        try? await Task.sleep(nanoseconds: UInt64(300_000_000))
        
        // Explicitly unwrap and compare UUIDs to prevent optional type solver errors
        guard let currentId = self.currentSearchId, currentId == newId else { return }
        
        await self.performGlobalSearch(query: query, resolution: targetResolution)
    }
    
    public func loadPlaylists() async {
        isLoading = true
        errorMessage = nil
        do {
            playlists = try await fetchPlaylistsUseCase.execute()
            recents = try await manageRecentsUseCase.fetchRecents()
        } catch {
            errorMessage = "Veriler yüklenirken hata oluştu: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    public func addPlaylist() async {
        isLoading = true
        errorMessage = nil
        do {
            if addPlaylistType == .m3u {
                _ = try await addPlaylistUseCase.execute(name: newPlaylistName, urlString: newPlaylistUrl)
                newPlaylistName = ""
                newPlaylistUrl = ""
            } else {
                _ = try await addXtreamPlaylistUseCase.execute(
                    name: newPlaylistName,
                    host: xtreamHost,
                    username: xtreamUsername,
                    password: xtreamPassword
                )
                newPlaylistName = ""
                xtreamHost = ""
                xtreamUsername = ""
                xtreamPassword = ""
            }
            showAddPlaylistSheet = false
            await loadPlaylists()
        } catch {
            errorMessage = "Oynatma listesi eklenemedi: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    public func deletePlaylist(_ playlist: Playlist) async {
        isLoading = true
        errorMessage = nil
        do {
            try await deletePlaylistUseCase.execute(id: playlist.id)
            await loadPlaylists()
        } catch {
            errorMessage = "Oynatma listesi silinemedi: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    public func playChannel(_ channel: Channel) async {
        try? await manageRecentsUseCase.saveRecent(channel)
        recents = (try? await manageRecentsUseCase.fetchRecents()) ?? [] // Refresh recents bar
    }
    
    private func performGlobalSearch(query: String, resolution: ResolutionFilter) async {
        if query.trimmingCharacters(in: .whitespaces).isEmpty && resolution == .all {
            globalSearchResults = []
            return
        }
        
        do {
            globalSearchResults = try await globalSearchUseCase.execute(query: query, resolution: resolution)
        } catch {
            globalSearchResults = []
        }
    }
}
