import Foundation

public final class XtreamCodesService: XtreamCodesServiceProtocol {
    
    public init() {}
    
    // MARK: - API Decodables
    
    struct XtreamCategory: Decodable {
        let category_id: String
        let category_name: String
    }
    
    struct XtreamStream: Decodable {
        let stream_id: Int
        let name: String
        let stream_icon: String?
        let category_id: String
        let epg_channel_id: String?
    }
    
    struct XtreamMovie: Decodable {
        let stream_id: Int
        let name: String
        let stream_icon: String?
        let category_id: String
        let rating: String?
        let year: String?
        let container_extension: String?
    }
    
    struct XtreamSeries: Decodable {
        let series_id: Int
        let name: String
        let cover: String?
        let category_id: String
        let rating: String?
        let releaseDate: String?
        let plot: String?
    }
    
    struct XtreamEpisodesResponse: Decodable {
        let episodes: [String: [XtreamEpisode]]?
    }
    
    struct XtreamEpisode: Decodable {
        let id: String
        let title: String
        let container_extension: String?
        let season: Int?
        let episode_num: Int?
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
        let categoryMap = Dictionary(uniqueKeysWithValues: categories.map { ($0.category_id, $0.category_name) })
        
        let streamsUrlString = "\(cleanHost)/player_api.php?username=\(username)&password=\(password)&action=get_live_streams"
        guard let streamsUrl = URL(string: streamsUrlString) else {
            throw NSError(domain: "XtreamCodesService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Geçersiz yayın listesi URL adresi"])
        }
        
        let (streamData, _) = try await URLSession.shared.data(from: streamsUrl)
        let streams = try JSONDecoder().decode([XtreamStream].self, from: streamData)
        
        return streams.compactMap { stream in
            let groupName = categoryMap[stream.category_id] ?? "Diğer"
            let iconUrl = stream.stream_icon.flatMap { URL(string: $0) }
            
            let streamUrlString = "\(cleanHost)/live/\(username)/\(password)/\(stream.stream_id).m3u8"
            guard let streamUrl = URL(string: streamUrlString) else { return nil }
            
            return Channel(
                id: stream.epg_channel_id ?? UUID().uuidString,
                playlistId: playlistId,
                name: stream.name,
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
        let categoryMap = Dictionary(uniqueKeysWithValues: categories.map { ($0.category_id, $0.category_name) })
        
        // 2. Fetch Movies
        let moviesUrlString = "\(cleanHost)/player_api.php?username=\(username)&password=\(password)&action=get_vod_streams"
        guard let moviesUrl = URL(string: moviesUrlString) else { return [] }
        let (movieData, _) = try await URLSession.shared.data(from: moviesUrl)
        let rawMovies = try JSONDecoder().decode([XtreamMovie].self, from: movieData)
        
        return rawMovies.compactMap { movie in
            let groupName = categoryMap[movie.category_id] ?? "Film"
            let iconUrl = movie.stream_icon.flatMap { URL(string: $0) }
            let ext = movie.container_extension ?? "mp4"
            
            // Format: http://host/movie/username/password/stream_id.ext
            let streamUrlString = "\(cleanHost)/movie/\(username)/\(password)/\(movie.stream_id).\(ext)"
            guard let streamUrl = URL(string: streamUrlString) else { return nil }
            
            return VODMovie(
                id: String(movie.stream_id),
                playlistId: playlistId,
                name: movie.name,
                logoUrl: iconUrl,
                streamUrl: streamUrl,
                groupTitle: groupName,
                rating: movie.rating,
                year: movie.year,
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
        let categoryMap = Dictionary(uniqueKeysWithValues: categories.map { ($0.category_id, $0.category_name) })
        
        // 2. Fetch Series
        let seriesUrlString = "\(cleanHost)/player_api.php?username=\(username)&password=\(password)&action=get_series"
        guard let seriesUrl = URL(string: seriesUrlString) else { return [] }
        let (seriesData, _) = try await URLSession.shared.data(from: seriesUrl)
        let rawSeries = try JSONDecoder().decode([XtreamSeries].self, from: seriesData)
        
        return rawSeries.compactMap { series in
            let groupName = categoryMap[series.category_id] ?? "Dizi"
            let iconUrl = series.cover.flatMap { URL(string: $0) }
            
            return VODSeries(
                id: String(series.series_id),
                playlistId: playlistId,
                name: series.name,
                logoUrl: iconUrl,
                groupTitle: groupName,
                rating: series.rating,
                year: series.releaseDate,
                plot: series.plot
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
                
                // Format: http://host/series/username/password/id.ext
                let streamUrlString = "\(cleanHost)/series/\(username)/\(password)/\(ep.id).\(ext)"
                guard let streamUrl = URL(string: streamUrlString) else { continue }
                
                let episode = VODEpisode(
                    id: ep.id,
                    name: ep.title,
                    streamUrl: streamUrl,
                    season: ep.season ?? 1,
                    episode: ep.episode_num ?? 1
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
