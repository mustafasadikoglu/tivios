import Foundation

public struct Channel: Identifiable, Codable, Equatable {
    public let id: String
    public let playlistId: UUID
    public let name: String
    public let logoUrl: URL?
    public let streamUrl: URL
    public let groupTitle: String
    public var isFavorite: Bool
    
    public init(id: String = UUID().uuidString, playlistId: UUID, name: String, logoUrl: URL? = nil, streamUrl: URL, groupTitle: String = "Diğer", isFavorite: Bool = false) {
        self.id = id
        self.playlistId = playlistId
        self.name = name
        self.logoUrl = logoUrl
        self.streamUrl = streamUrl
        self.groupTitle = groupTitle
        self.isFavorite = isFavorite
    }
}
