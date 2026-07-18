import Foundation

public struct EPGProgram: Identifiable, Codable, Equatable {
    public var id: String { "\(channelId)_\(start.timeIntervalSince1970)" }
    public let channelId: String
    public let start: Date
    public let stop: Date
    public let title: String
    public let description: String?
    
    public init(channelId: String, start: Date, stop: Date, title: String, description: String? = nil) {
        self.channelId = channelId
        self.start = start
        self.stop = stop
        self.title = title
        self.description = description
    }
    
    public var isCurrent: Bool {
        let now = Date()
        return now >= start && now <= stop
    }
}
