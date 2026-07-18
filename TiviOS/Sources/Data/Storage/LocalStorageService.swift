import Foundation

public final class LocalStorageService {
    private let fileManager = FileManager.default
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var playlistsFileURL: URL {
        documentsDirectory.appendingPathComponent("playlists.json")
    }
    
    private var recentsFileURL: URL {
        documentsDirectory.appendingPathComponent("recents.json")
    }
    
    private func channelsFileURL(for playlistId: UUID) -> URL {
        documentsDirectory.appendingPathComponent("channels_\(playlistId.uuidString).json")
    }
    
    public init() {}
    
    // MARK: - Playlists
    
    public func savePlaylists(_ playlists: [Playlist]) throws {
        let data = try JSONEncoder().encode(playlists)
        try data.write(to: playlistsFileURL, options: .atomic)
    }
    
    public func fetchPlaylists() throws -> [Playlist] {
        guard fileManager.fileExists(atPath: playlistsFileURL.path) else {
            return []
        }
        let data = try Data(contentsOf: playlistsFileURL)
        return try JSONDecoder().decode([Playlist].self, from: data)
    }
    
    // MARK: - Channels
    
    public func saveChannels(_ channels: [Channel], for playlistId: UUID) throws {
        let fileURL = channelsFileURL(for: playlistId)
        let data = try JSONEncoder().encode(channels)
        try data.write(to: fileURL, options: .atomic)
    }
    
    public func fetchChannels(for playlistId: UUID) throws -> [Channel] {
        let fileURL = channelsFileURL(for: playlistId)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([Channel].self, from: data)
    }
    
    public func deleteChannels(for playlistId: UUID) throws {
        let fileURL = channelsFileURL(for: playlistId)
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }
    
    // MARK: - Recents
    
    public func saveRecentChannel(_ channel: Channel) throws {
        var recents = try fetchRecentChannels()
        // Remove duplicate if exists
        recents.removeAll { $0.id == channel.id }
        // Prepend new item
        recents.insert(channel, at: 0)
        // Keep last 10
        if recents.count > 10 {
            recents = Array(recents.prefix(10))
        }
        
        let data = try JSONEncoder().encode(recents)
        try data.write(to: recentsFileURL, options: .atomic)
    }
    
    public func fetchRecentChannels() throws -> [Channel] {
        guard fileManager.fileExists(atPath: recentsFileURL.path) else {
            return []
        }
        let data = try Data(contentsOf: recentsFileURL)
        return try JSONDecoder().decode([Channel].self, from: data)
    }
}
