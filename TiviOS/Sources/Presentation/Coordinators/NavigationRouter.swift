import SwiftUI

public enum AppRoute: Hashable {
    case playlistList
    case channelList(playlist: Playlist)
    case player(channel: Channel)
    case movieDetail(movie: VODMovie)
    case seriesDetail(series: VODSeries)
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .playlistList:
            hasher.combine(0)
        case .channelList(let playlist):
            hasher.combine(1)
            hasher.combine(playlist.id)
        case .player(let channel):
            hasher.combine(2)
            hasher.combine(channel.id)
        case .movieDetail(let movie):
            hasher.combine(3)
            hasher.combine(movie.id)
        case .seriesDetail(let series):
            hasher.combine(4)
            hasher.combine(series.id)
        }
    }
    
    public static func == (lhs: AppRoute, rhs: AppRoute) -> Bool {
        switch (lhs, rhs) {
        case (.playlistList, .playlistList):
            return true
        case (.channelList(let lPlay), .channelList(let rPlay)):
            return lPlay.id == rPlay.id
        case (.player(let lChan), .player(let rChan)):
            return lChan.id == rChan.id
        case (.movieDetail(let lMovie), .movieDetail(let rMovie)):
            return lMovie.id == rMovie.id
        case (.seriesDetail(let lSeries), .seriesDetail(let rSeries)):
            return lSeries.id == rSeries.id
        default:
            return false
        }
    }
}

public final class NavigationRouter: ObservableObject {
    @Published public var path: [AppRoute] = []
    
    public init() {}
    
    public func navigate(to route: AppRoute) {
        path.append(route)
    }
    
    public func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    public func popToRoot() {
        path.removeAll()
    }
}
