import Foundation

public protocol EPGServiceProtocol {
    func fetchEPG(url: URL) async throws -> [EPGProgram]
    func getCurrentProgram(for channelId: String, from programs: [EPGProgram]) -> EPGProgram?
}
