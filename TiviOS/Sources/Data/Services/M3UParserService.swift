import Foundation

public final class M3UParserService: M3UParserServiceProtocol {
    
    public init() {}
    
    public func parse(content: String, playlistId: UUID) throws -> [Channel] {
        var channels: [Channel] = []
        let lines = content.components(separatedBy: .newlines)
        
        var currentInfo: [String: String] = [:]
        var currentName = ""
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            
            if trimmed.hasPrefix("#EXTINF:") {
                // Parse #EXTINF parameters and channel name
                currentInfo = parseExtInf(trimmed)
                if let commaIndex = trimmed.firstIndex(of: ",") {
                    currentName = String(trimmed[trimmed.index(after: commaIndex)...]).trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    currentName = "Bilinmeyen Kanal"
                }
            } else if trimmed.hasPrefix("#") {
                // Other tags/comments, skip
                continue
            } else if let url = URL(string: trimmed) {
                // It is a streaming URL
                let logoUrl = currentInfo["tvg-logo"].flatMap { URL(string: $0) }
                let group = currentInfo["group-title"] ?? "Diğer"
                let channelName = currentName.isEmpty ? (currentInfo["tvg-name"] ?? "Kanal") : currentName
                
                let channel = Channel(
                    id: UUID().uuidString,
                    playlistId: playlistId,
                    name: channelName,
                    logoUrl: logoUrl,
                    streamUrl: url,
                    groupTitle: group,
                    isFavorite: false
                )
                channels.append(channel)
                
                // Reset for next channel
                currentInfo = [:]
                currentName = ""
            }
        }
        return channels
    }
    
    public func parse(url: URL, playlistId: UUID) async throws -> [Channel] {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "M3UParserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Playlist dosyası indirilemedi"])
        }
        
        // M3U files are usually UTF-8 or ISO-8859-9 (Turkish) or Windows-1254. Let's try UTF-8 first, fallback to ASCII/Windows-1254 if needed.
        guard let content = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
            throw NSError(domain: "M3UParserService", code: 422, userInfo: [NSLocalizedDescriptionKey: "Playlist kodlaması okunamadı"])
        }
        
        return try parse(content: content, playlistId: playlistId)
    }
    
    private func parseExtInf(_ line: String) -> [String: String] {
        var info: [String: String] = [:]
        
        // Extract key="value" pattern
        let pattern = "([a-zA-Z0-9_-]+)=\"([^\"]*)\""
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return info
        }
        
        let nsString = line as NSString
        let results = regex.matches(in: line, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for result in results {
            if result.numberOfRanges == 3 {
                let key = nsString.substring(with: result.range(at: 1))
                let value = nsString.substring(with: result.range(at: 2))
                info[key] = value
            }
        }
        
        return info
    }
}
