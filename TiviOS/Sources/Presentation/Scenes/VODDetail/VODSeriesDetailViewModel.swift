import Foundation
import Combine

@MainActor
public final class VODSeriesDetailViewModel: ObservableObject {
    public let series: VODSeries
    public let playlist: Playlist
    
    @Published public var episodes: [VODEpisode] = []
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    @Published public var selectedSeason = 1
    
    private let fetchVODUseCase: FetchVODUseCase
    
    public init(series: VODSeries, playlist: Playlist, fetchVODUseCase: FetchVODUseCase) {
        self.series = series
        self.playlist = playlist
        self.fetchVODUseCase = fetchVODUseCase
    }
    
    public func loadEpisodes() async {
        isLoading = true
        errorMessage = nil
        do {
            episodes = try await fetchVODUseCase.fetchEpisodes(for: series.id, playlist: playlist)
            if let firstOption = seasons.first {
                selectedSeason = firstOption
            }
        } catch {
            errorMessage = "Dizi bölümleri yüklenemedi: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    public var seasons: [Int] {
        Array(Set(episodes.map { $0.season })).sorted()
    }
    
    public var filteredEpisodes: [VODEpisode] {
        episodes.filter { $0.season == selectedSeason }
    }
}
