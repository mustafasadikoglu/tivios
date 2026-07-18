import Foundation

public struct VODMovie: Identifiable, Codable, Equatable {
    public let id: String
    public let playlistId: UUID
    public let name: String
    public let logoUrl: URL?
    public let streamUrl: URL
    public let groupTitle: String
    public let rating: String?
    public let year: String?
    public let plot: String?
    
    public init(
        id: String,
        playlistId: UUID,
        name: String,
        logoUrl: URL? = nil,
        streamUrl: URL,
        groupTitle: String = "Film",
        rating: String? = nil,
        year: String? = nil,
        plot: String? = nil
    ) {
        self.id = id
        self.playlistId = playlistId
        self.name = name
        self.logoUrl = logoUrl
        self.streamUrl = streamUrl
        self.groupTitle = groupTitle
        self.rating = rating
        self.year = year
        self.plot = plot
    }
}

public struct VODSeries: Identifiable, Codable, Equatable {
    public let id: String
    public let playlistId: UUID
    public let name: String
    public let logoUrl: URL?
    public let groupTitle: String
    public let rating: String?
    public let year: String?
    public let plot: String?
    
    public init(
        id: String,
        playlistId: UUID,
        name: String,
        logoUrl: URL? = nil,
        groupTitle: String = "Dizi",
        rating: String? = nil,
        year: String? = nil,
        plot: String? = nil
    ) {
        self.id = id
        self.playlistId = playlistId
        self.name = name
        self.logoUrl = logoUrl
        self.groupTitle = groupTitle
        self.rating = rating
        self.year = year
        self.plot = plot
    }
}

public struct VODEpisode: Identifiable, Codable, Equatable {
    public let id: String
    public let name: String
    public let streamUrl: URL
    public let season: Int
    public let episode: Int
    
    public init(id: String, name: String, streamUrl: URL, season: Int, episode: Int) {
        self.id = id
        self.name = name
        self.streamUrl = streamUrl
        self.season = season
        self.episode = episode
    }
}
