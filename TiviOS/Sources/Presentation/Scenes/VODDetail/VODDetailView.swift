import SwiftUI

// MARK: - Movie Detail View

public struct VODMovieDetailView: View {
    let movie: VODMovie
    @EnvironmentObject private var router: NavigationRouter
    @EnvironmentObject private var themeManager: ThemeManager
    
    public init(movie: VODMovie) {
        self.movie = movie
    }
    
    public var body: some View {
        ZStack {
            themeManager.backgroundGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header navigation
                    HStack {
                        Button {
                            router.pop()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .foregroundColor(themeManager.accentColor)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Poster Display
                    if let logoUrl = movie.logoUrl {
                        AsyncImage(url: logoUrl) { img in
                            img.resizable().aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Image(systemName: "film").foregroundColor(.gray)
                        }
                        .frame(maxHeight: 300)
                        .cornerRadius(16)
                        .shadow(color: themeManager.accentColor.opacity(0.3), radius: 10)
                    }
                    
                    // Metadata Info
                    VStack(spacing: 12) {
                        Text(movie.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 16) {
                            if let year = movie.year {
                                Text(year)
                                    .foregroundColor(.gray)
                            }
                            if let rating = movie.rating {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill").foregroundColor(.yellow)
                                    Text(rating).foregroundColor(.white)
                                }
                            }
                        }
                        .font(.subheadline)
                    }
                    
                    // Play Button
                    Button {
                        // Map VOD Movie to a Channel object to reuse the Video Player scene
                        let ch = Channel(
                            id: movie.id,
                            playlistId: movie.playlistId,
                            name: movie.name,
                            logoUrl: movie.logoUrl,
                            streamUrl: movie.streamUrl,
                            groupTitle: movie.groupTitle
                        )
                        router.navigate(to: .player(channel: ch))
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Filmi İzle")
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(themeManager.primaryGradient)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    
                    // Plot
                    if let plot = movie.plot {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Özet")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(plot)
                                .font(.body)
                                .foregroundColor(.gray)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - TV Series Detail View

public struct VODSeriesDetailView: View {
    @StateObject private var viewModel: VODSeriesDetailViewModel
    @EnvironmentObject private var router: NavigationRouter
    @EnvironmentObject private var themeManager: ThemeManager
    
    public init(viewModel: VODSeriesDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
            themeManager.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header
                HStack {
                    Button {
                        router.pop()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(themeManager.accentColor)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Poster
                        if let logoUrl = viewModel.series.logoUrl {
                            AsyncImage(url: logoUrl) { img in
                                img.resizable().aspectRatio(contentMode: .fit)
                            } placeholder: {
                                Image(systemName: "film").foregroundColor(.gray)
                            }
                            .frame(maxHeight: 220)
                            .cornerRadius(12)
                        }
                        
                        // Metadata
                        VStack(spacing: 8) {
                            Text(viewModel.series.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            HStack(spacing: 16) {
                                if let year = viewModel.series.year {
                                    Text(year).foregroundColor(.gray)
                                }
                                if let rating = viewModel.series.rating {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill").foregroundColor(.yellow)
                                        Text(rating).foregroundColor(.white)
                                    }
                                }
                            }
                            .font(.caption)
                        }
                        
                        if let plot = viewModel.series.plot {
                            Text(plot)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Season Selector
                        if !viewModel.seasons.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(viewModel.seasons, id: \.self) { s in
                                        Button {
                                            viewModel.selectedSeason = s
                                        } label: {
                                            Text("\(s). Sezon")
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .foregroundColor(viewModel.selectedSeason == s ? .white : .gray)
                                                .background(
                                                    Capsule()
                                                        .fill(viewModel.selectedSeason == s ?
                                                            AnyShapeStyle(themeManager.primaryGradient) :
                                                            AnyShapeStyle(Color.white.opacity(0.05))
                                                        )
                                                )
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Episode List
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: themeManager.accentColor))
                                .scaleEffect(1.5)
                        } else if viewModel.episodes.isEmpty {
                            Text("Bölüm bulunamadı.").foregroundColor(.gray)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(viewModel.filteredEpisodes) { ep in
                                    Button {
                                        // Play episode
                                        let ch = Channel(
                                            id: ep.id,
                                            playlistId: viewModel.playlist.id,
                                            name: "\(viewModel.series.name) - S\(ep.season)E\(ep.episode)",
                                            logoUrl: viewModel.series.logoUrl,
                                            streamUrl: ep.streamUrl,
                                            groupTitle: viewModel.series.groupTitle
                                        )
                                        router.navigate(to: .player(channel: ch))
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("\(ep.episode). Bölüm")
                                                    .font(.body)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.white)
                                                
                                                Text(ep.name)
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            Spacer()
                                            
                                            Image(systemName: "play.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(themeManager.accentColor)
                                        }
                                        .padding()
                                        .background(Color.white.opacity(0.04))
                                        .cornerRadius(10)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadEpisodes()
        }
    }
}
