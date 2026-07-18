import Foundation

public protocol VODRepositoryProtocol {
    func fetchMovies(for playlistId: UUID) async throws -> [VODMovie]
    func saveMovies(_ movies: [VODMovie], for playlistId: UUID) async throws
    
    func fetchSeries(for playlistId: UUID) async throws -> [VODSeries]
    func saveSeries(_ series: [VODSeries], for playlistId: UUID) async throws
    
    func fetchEpisodes(for seriesId: String, playlistId: UUID) async throws -> [VODEpisode]
    func saveEpisodes(_ episodes: [VODEpisode], for seriesId: String, playlistId: UUID) async throws
    
    func deleteVODData(for playlistId: UUID) async throws
}
