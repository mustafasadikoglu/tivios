import Foundation

public enum PlaylistType: String, Codable {
    case m3u
    case xtream
}

public struct Playlist: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var type: PlaylistType
    
    // M3U specific fields
    public var url: URL?
    public var filePath: String?
    
    // Xtream specific fields
    public var xtreamUsername: String?
    public var xtreamPassword: String?
    public var xtreamHost: String?
    
    public let addedAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        type: PlaylistType = .m3u,
        url: URL? = nil,
        filePath: String? = nil,
        xtreamUsername: String? = nil,
        xtreamPassword: String? = nil,
        xtreamHost: String? = nil,
        addedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.url = url
        self.filePath = filePath
        self.xtreamUsername = xtreamUsername
        self.xtreamPassword = xtreamPassword
        self.xtreamHost = xtreamHost
        self.addedAt = addedAt
    }
}
