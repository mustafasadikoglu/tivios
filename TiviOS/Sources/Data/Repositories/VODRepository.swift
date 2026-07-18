import Foundation

public final class VODRepository: VODRepositoryProtocol {
    private let fileManager = FileManager.default
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func moviesFileURL(for playlistId: UUID) -> URL {
        documentsDirectory.appendingPathComponent("movies_\(playlistId.uuidString).json")
    }
    
    private func seriesFileURL(for playlistId: UUID) -> URL {
        documentsDirectory.appendingPathComponent("series_\(playlistId.uuidString).json")
    }
    
    private func episodesFileURL(for seriesId: String, playlistId: UUID) -> URL {
        documentsDirectory.appendingPathComponent("episodes_\(seriesId)_\(playlistId.uuidString).json")
    }
    
    public init() {}
    
    // MARK: - Movies
    
    public func fetchMovies(for playlistId: UUID) async throws -> [VODMovie] {
        let fileURL = moviesFileURL(for: playlistId)
        guard fileManager.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([VODMovie].self, from: data)
    }
    
    public func saveMovies(_ movies: [VODMovie], for playlistId: UUID) async throws {
        let fileURL = moviesFileURL(for: playlistId)
        let data = try JSONEncoder().encode(movies)
        try data.write(to: fileURL, options: .atomic)
    }
    
    // MARK: - Series
    
    public func fetchSeries(for playlistId: UUID) async throws -> [VODSeries] {
        let fileURL = seriesFileURL(for: playlistId)
        guard fileManager.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([VODSeries].self, from: data)
    }
    
    public func saveSeries(_ series: [VODSeries], for playlistId: UUID) async throws {
        let fileURL = seriesFileURL(for: playlistId)
        let data = try JSONEncoder().encode(series)
        try data.write(to: fileURL, options: .atomic)
    }
    
    // MARK: - Episodes
    
    public func fetchEpisodes(for seriesId: String, playlistId: UUID) async throws -> [VODEpisode] {
        let fileURL = episodesFileURL(for: seriesId, playlistId: playlistId)
        guard fileManager.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([VODEpisode].self, from: data)
    }
    
    public func saveEpisodes(_ episodes: [VODEpisode], for seriesId: String, playlistId: UUID) async throws {
        let fileURL = episodesFileURL(for: seriesId, playlistId: playlistId)
        let data = try JSONEncoder().encode(episodes)
        try data.write(to: fileURL, options: .atomic)
    }
    
    // MARK: - Delete VOD
    
    public func deleteVODData(for playlistId: UUID) async throws {
        let mURL = moviesFileURL(for: playlistId)
        let sURL = seriesFileURL(for: playlistId)
        
        if fileManager.fileExists(atPath: mURL.path) {
            try fileManager.removeItem(at: mURL)
        }
        if fileManager.fileExists(atPath: sURL.path) {
            try fileManager.removeItem(at: sURL)
        }
        
        // Remove individual episodes cache files for this playlist
        let files = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
        let prefix = "episodes_"
        for file in files {
            let name = file.lastPathComponent
            if name.hasPrefix(prefix) && name.hasSuffix("\(playlistId.uuidString).json") {
                try fileManager.removeItem(at: file)
            }
        }
    }
}
