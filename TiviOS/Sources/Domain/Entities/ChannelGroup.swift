import Foundation

public struct ChannelGroup: Identifiable, Equatable {
    public var id: String { name }
    public let name: String
    public var channels: [Channel]
    
    public init(name: String, channels: [Channel] = []) {
        self.name = name
        self.channels = channels
    }
}
