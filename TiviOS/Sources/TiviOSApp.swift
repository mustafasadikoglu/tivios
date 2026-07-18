import SwiftUI

@main
struct TiviOSApp: App {
    @StateObject private var container = DependencyContainer()
    @StateObject private var router = NavigationRouter()
    @StateObject private var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                PlaylistListView(viewModel: container.makePlaylistListViewModel())
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .playlistList:
                            PlaylistListView(viewModel: container.makePlaylistListViewModel())
                        case .channelList(let playlist):
                            ChannelListView(viewModel: container.makeChannelListViewModel(playlist: playlist))
                        case .player(let channel):
                            PlayerView(viewModel: container.makePlayerViewModel(channel: channel))
                        case .movieDetail(let movie):
                            VODMovieDetailView(movie: movie)
                        case .seriesDetail(let series):
                            VODSeriesDetailView(viewModel: container.makeVODSeriesDetailViewModel(series: series))
                        }
                    }
            }
            .environmentObject(router)
            .environmentObject(container)
            .environmentObject(themeManager)
            .preferredColorScheme(.dark)
        }
    }
}
