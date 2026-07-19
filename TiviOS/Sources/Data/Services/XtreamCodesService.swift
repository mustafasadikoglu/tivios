import Foundation

public final class XtreamCodesService: XtreamCodesServiceProtocol {
    
    public init() {}
    
    // MARK: - Flexible JSON Value (handles Int/String interchangeably)
    
    /// Xtream APIs inconsistently return numbers as strings or ints
    struct FlexibleString: Decodable {
        let value: String
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let intVal = try? container.decode(Int.self) {
                value = String(intVal)
            } else if let strVal = try? container.decode(String.self) {
                value = strVal
            } else {
                value = ""
            }
        }
    }
    
    struct FlexibleInt: Decodable {
        let value: Int
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let intVal = try? container.decode(Int.self) {
                value = intVal
            } else if let strVal = try? container.decode(String.self), let parsed = Int(strVal) {
                value = parsed
            } else {
                value = 0
            }
        }
    }
    
    // MARK: - API Decodables
    
    struct XtreamCategory: Decodable {
        let category_id: FlexibleString
        let category_name: String
    }
    
    struct XtreamStream: Decodable {
        let stream_id: FlexibleInt
        let name: String?
        let stream_icon: String?
        let category_id: FlexibleString?
        let epg_channel_id: String?
    }
    
    struct XtreamMovie: Decodable {
        let stream_id: FlexibleInt
        let name: String?
        let stream_icon: String?
        let category_id: FlexibleString?
        let rating: FlexibleString?
        let year: FlexibleString?
        let container_extension: String?
    }
    
    struct XtreamSeries: Decodable {
        let series_id: FlexibleInt
        let name: String?
        let cover: String?
        let category_id: FlexibleString?
        let rating: FlexibleString?
        let releaseDate: String?
        let plot: String?
    }
    
    struct XtreamEpisodesResponse: Decodable {
        let episodes: [String: [XtreamEpisode]]?
    }
    
    struct XtreamEpisode: Decodable {
        let id: FlexibleString
        let title: String?
        let container_extension: String?
        let season: FlexibleInt?
        let episode_num: FlexibleInt?
    }
    
    // MARK: - Live Channels
    
    public func fetchChannels(host: String, username: String, password: String, playlistId: UUID) async throws -> [Channel] {
        let cleanHost = host.hasSuffix("/") ? String(host.dropLast()) : host
        
        let categoryUrlString = "\(cleanHost)/player_api.php?username=\(username)&password=\(password)&action=get_live_categories"
        guard let categoryUrl = URL(string: categoryUrlString) else {
            throw NSError(domain: "XtreamCodesService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Geçersiz Host URL adresi"])
        }
        
        let (catData, _) = try await URLSession.shared.data(from: categoryUrl)
        let categories = (try? JSONDecoder().decode([XtreamCategory].self, from: catData)) ?? []
        let categoryMap = Dictionary(uniqueKeysWithValues: categories.map { ($0.category_id.value, $0.category_name) })
        
        let streamsUrlString = "\(cleanHost)/player_api.php?username=\(username)&password=\(password)&action=get_live_streams"
        guard let streamsUrl = URL(string: streamsUrlString) else {
            throw NSError(domain: "XtreamCodesService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Geçersiz yayın listesi URL adresi"])
        }
        
        let (streamData, _) = try await URLSession.shared.data(from: streamsUrl)
        let streams = try JSONDecoder().decode([XtreamStream].self, from: streamData)
        
        return streams.compactMap { stream in
            let streamName = stream.name ?? "Kanal"
            let groupName = categoryMap[stream.category_id?.value ?? ""] ?? "Diğer"
            let iconUrl = stream.stream_icon.flatMap { URL(string: $0) }
            // Use .m3u8 (HLS) for live streams as AVPlayer handles HLS perfectly but often fails to parse raw .ts over HTTP
            let streamUrlString = "\(cleanHost)/live/\(username)/\(password)/\(stream.stream_id.value).m3u8"
            guard let streamUrl = URL(string: streamUrlString) else { return nil }
            
            return Channel(
                id: stream.epg_channel_id ?? UUID().uuidString,
                playlistId: playlistId,
                name: streamName,
                logoUrl: iconUrl,
                streamUrl: streamUrl,
                groupTitle: groupName,
                isFavorite: false
            )
        }
    }
    
    // MARK: - VOD Movies
    
    public func fetchMovies(host: String, username: String, password: String, playlistId: UUID) async throws -> [VODMovie] {
        let cleanHost = host.hasSuffix("/") ? String(host.dropLast()) : host
        
        // 1. Fetch categories
        let categoryUrlString = "\(cleanHost)/player_api.php?username=\(username)&password=\(password)&action=get_vod_categories"
        guard let categoryUrl = URL(string: categoryUrlString) else { return [] }
        let (catData, _) = try await URLSession.shared.data(from: categoryUrl)
        let categories = (try? JSONDecoder().decode([XtreamCategory].self, from: catData)) ?? []
        let categoryMap = Dictionary(uniqueKeysWithValues: categories.map { ($0.category_id.value, $0.category_name) })
        
        // 2. Fetch Movies
        let moviesUrlString = "\(cleanHost)/player_api.php?username=\(username)&password=\(password)&action=get_vod_streams"
        guard let moviesUrl = URL(string: moviesUrlString) else { return [] }
        let (movieData, _) = try await URLSession.shared.data(from: moviesUrl)
        
        // Use JSONSerialization to prevent the entire array from failing if one item is malformed
        guard let rawArray = (try? JSONSerialization.jsonObject(with: movieData)) as? [[String: Any]] else { return [] }
        
        return rawArray.compactMap { dict in
            // stream_id can be Int or String
            let streamIdVal = dict["stream_id"]
            let streamId: String
            if let idInt = streamIdVal as? Int {
                streamId = String(idInt)
            } else if let idStr = streamIdVal as? String {
                streamId = idStr
            } else {
                return nil // stream_id is required
            }
            
            let movieName = (dict["name"] as? String) ?? "Film"
            let categoryId = String(describing: dict["category_id"] ?? "")
            let groupName = categoryMap[categoryId] ?? "Film"
            let iconUrl = (dict["stream_icon"] as? String).flatMap { URL(string: $0) }
            let ext = (dict["container_extension"] as? String) ?? "mp4"
            let rating = String(describing: dict["rating"] ?? "")
            let year = String(describing: dict["year"] ?? "")
            
            // Format: http://host/movie/username/password/stream_id.ext
            let streamUrlString = "\(cleanHost)/movie/\(username)/\(password)/\(streamId).\(ext)"
            guard let streamUrl = URL(string: streamUrlString) else { return nil }
            
            return VODMovie(
                id: streamId,
                playlistId: playlistId,
                name: movieName,
                logoUrl: iconUrl,
                streamUrl: streamUrl,
                groupTitle: groupName,
                rating: rating.isEmpty ? nil : rating,
                year: year.isEmpty ? nil : year,
                plot: nil
            )
        }
    }
    
    // MARK: - TV Series
    
    public func fetchSeries(host: String, username: String, password: String, playlistId: UUID) async throws -> [VODSeries] {
        let cleanHost = host.hasSuffix("/") ? String(host.dropLast()) : host
        
        // 1. Fetch categories
        let categoryUrlString = "\(cleanHost)/player_api.php?username=\(username)&password=\(password)&action=get_series_categories"
        guard let categoryUrl = URL(string: categoryUrlString) else { return [] }
        let (catData, _) = try await URLSession.shared.data(from: categoryUrl)
        let categories = (try? JSONDecoder().decode([XtreamCategory].self, from: catData)) ?? []
        let categoryMap = Dictionary(uniqueKeysWithValues: categories.map { ($0.category_id.value, $0.category_name) })
        
        // 2. Fetch Series
        let seriesUrlString = "\(cleanHost)/player_api.php?username=\(username)&password=\(password)&action=get_series"
        guard let seriesUrl = URL(string: seriesUrlString) else { return [] }
        let (seriesData, _) = try await URLSession.shared.data(from: seriesUrl)
        
        guard let rawArray = (try? JSONSerialization.jsonObject(with: seriesData)) as? [[String: Any]] else { return [] }
        
        return rawArray.compactMap { dict in
            let seriesIdVal = dict["series_id"]
            let seriesId: String
            if let idInt = seriesIdVal as? Int {
                seriesId = String(idInt)
            } else if let idStr = seriesIdVal as? String {
                seriesId = idStr
            } else {
                return nil
            }
            
            let seriesName = (dict["name"] as? String) ?? "Dizi"
            let categoryId = String(describing: dict["category_id"] ?? "")
            let groupName = categoryMap[categoryId] ?? "Dizi"
            let iconUrl = (dict["cover"] as? String).flatMap { URL(string: $0) }
            
            let rating = String(describing: dict["rating"] ?? "")
            let releaseDate = String(describing: dict["releaseDate"] ?? "")
            let plot = dict["plot"] as? String
            
            return VODSeries(
                id: seriesId,
                playlistId: playlistId,
                name: seriesName,
                logoUrl: iconUrl,
                groupTitle: groupName,
                rating: rating.isEmpty ? nil : rating,
                year: releaseDate.isEmpty ? nil : releaseDate,
                plot: plot
            )
        }
    }
    
    // MARK: - Series Episodes
    
    public func fetchEpisodes(host: String, username: String, password: String, seriesId: String) async throws -> [VODEpisode] {
        let cleanHost = host.hasSuffix("/") ? String(host.dropLast()) : host
        
        let urlString = "\(cleanHost)/player_api.php?username=\(username)&password=\(password)&action=get_series_info&series_id=\(seriesId)"
        guard let url = URL(string: urlString) else { return [] }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // Response contains episodes grouped by season number as keys ("1", "2"...)
        let response = try JSONDecoder().decode(XtreamEpisodesResponse.self, from: data)
        guard let seasonsMap = response.episodes else { return [] }
        
        var episodes: [VODEpisode] = []
        for (_, rawEpisodes) in seasonsMap {
            for ep in rawEpisodes {
                let ext = ep.container_extension ?? "mp4"
                let epTitle = ep.title ?? "Bölüm \(ep.episode_num?.value ?? 0)"
                
                // Format: http://host/series/username/password/id.ext
                let streamUrlString = "\(cleanHost)/series/\(username)/\(password)/\(ep.id.value).\(ext)"
                guard let streamUrl = URL(string: streamUrlString) else { continue }
                
                let episode = VODEpisode(
                    id: ep.id.value,
                    name: epTitle,
                    streamUrl: streamUrl,
                    season: ep.season?.value ?? 1,
                    episode: ep.episode_num?.value ?? 1
                )
                episodes.append(episode)
            }
        }
        
        return episodes.sorted(by: {
            if $0.season != $1.season {
                return $0.season < $1.season
            }
            return $0.episode < $1.episode
        })
    }
}
