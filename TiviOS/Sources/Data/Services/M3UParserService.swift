import Foundation

public final class M3UParserService: M3UParserServiceProtocol {
    
    public init() {}
    
    // MARK: - Content Type Detection
    
    /// Keywords in group-title that indicate movie content
    private let movieKeywords: Set<String> = [
        "movie", "movies", "film", "filmler", "sinema", "cinema",
        "vod", "video on demand", "pelikula", "película",
        "4k movie", "hd movie", "uhd movie"
    ]
    
    /// Keywords in group-title that indicate series content
    private let seriesKeywords: Set<String> = [
        "series", "serie", "dizi", "diziler", "show", "shows",
        "tv show", "tv series", "season", "episode",
        "temporada", "saison"
    ]
    
    /// File extensions that indicate VOD (non-live) content
    private let vodExtensions: Set<String> = [
        "mp4", "mkv", "avi", "mov", "wmv", "flv", "webm",
        "m4v", "3gp", "mpg", "mpeg", "ogv"
    ]
    
    private enum ContentType {
        case live
        case movie
        case series
    }
    
    private func classifyContent(groupTitle: String, urlString: String) -> ContentType {
        let lowerGroup = groupTitle.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let lowerUrl = urlString.lowercased()
        
        // 1. Check group-title keywords for series first (more specific)
        for keyword in seriesKeywords {
            if lowerGroup.contains(keyword) {
                return .series
            }
        }
        
        // 2. Check group-title keywords for movies
        for keyword in movieKeywords {
            if lowerGroup.contains(keyword) {
                return .movie
            }
        }
        
        // 3. Check URL path for /movie/ or /series/ (Xtream-style M3U exports)
        if lowerUrl.contains("/movie/") || lowerUrl.contains("/movies/") {
            return .movie
        }
        if lowerUrl.contains("/series/") {
            return .series
        }
        
        // 4. Check file extension - VOD files have video extensions, live streams use .ts/.m3u8
        let pathExtension = URL(string: urlString)?.pathExtension.lowercased() ?? ""
        if vodExtensions.contains(pathExtension) {
            // VOD content - default to movie if not identified as series
            return .movie
        }
        
        // 5. Default: live channel
        return .live
    }
    
    // MARK: - Legacy Parser (returns all as channels)
    
    public func parse(content: String, playlistId: UUID) throws -> [Channel] {
        let result = try parseClassified(content: content, playlistId: playlistId)
        // Legacy: merge all content as channels for backward compatibility
        var allChannels = result.channels
        allChannels.append(contentsOf: result.movies.map { movie in
            Channel(
                id: movie.id,
                playlistId: movie.playlistId,
                name: movie.name,
                logoUrl: movie.logoUrl,
                streamUrl: movie.streamUrl,
                groupTitle: movie.groupTitle,
                isFavorite: false
            )
        })
        return allChannels
    }
    
    public func parse(url: URL, playlistId: UUID) async throws -> [Channel] {
        let content = try await downloadContent(from: url)
        return try parse(content: content, playlistId: playlistId)
    }
    
    // MARK: - Classified Parser (separates live/movie/series)
    
    public func parseClassified(content: String, playlistId: UUID) throws -> M3UParseResult {
        var channels: [Channel] = []
        var movies: [VODMovie] = []
        var seriesList: [VODSeries] = []
        
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
                
                let contentType = classifyContent(groupTitle: group, urlString: trimmed)
                
                switch contentType {
                case .live:
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
                    
                case .movie:
                    let movie = VODMovie(
                        id: UUID().uuidString,
                        playlistId: playlistId,
                        name: channelName,
                        logoUrl: logoUrl,
                        streamUrl: url,
                        groupTitle: group
                    )
                    movies.append(movie)
                    
                case .series:
                    // M3U series entries: each episode is a separate VODMovie shown under Filmler
                    // because M3U doesn't have Xtream-like season/episode structure.
                    // We still categorize as movie but keep the series group title.
                    let movie = VODMovie(
                        id: UUID().uuidString,
                        playlistId: playlistId,
                        name: channelName,
                        logoUrl: logoUrl,
                        streamUrl: url,
                        groupTitle: group
                    )
                    movies.append(movie)
                }
                
                // Reset for next channel
                currentInfo = [:]
                currentName = ""
            }
        }
        
        return M3UParseResult(
            channels: channels,
            movies: movies,
            series: seriesList
        )
    }
    
    public func parseClassified(url: URL, playlistId: UUID) async throws -> M3UParseResult {
        let content = try await downloadContent(from: url)
        return try parseClassified(content: content, playlistId: playlistId)
    }
    
    // MARK: - Private Helpers
    
    private func downloadContent(from url: URL) async throws -> String {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "M3UParserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Playlist dosyası indirilemedi"])
        }
        
        // M3U files are usually UTF-8 or ISO-8859-9 (Turkish) or Windows-1254. Let's try UTF-8 first, fallback to ASCII/Windows-1254 if needed.
        guard let content = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
            throw NSError(domain: "M3UParserService", code: 422, userInfo: [NSLocalizedDescriptionKey: "Playlist kodlaması okunamadı"])
        }
        
        return content
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
