import Foundation

public final class FetchEPGUseCase {
    private let epgService: EPGServiceProtocol
    
    public init(epgService: EPGServiceProtocol) {
        self.epgService = epgService
    }
    
    public func execute(url: URL) async throws -> [EPGProgram] {
        return try await epgService.fetchEPG(url: url)
    }
    
    public func getCurrentProgram(for channelId: String, from programs: [EPGProgram]) -> EPGProgram? {
        return epgService.getCurrentProgram(for: channelId, from: programs)
    }
}
