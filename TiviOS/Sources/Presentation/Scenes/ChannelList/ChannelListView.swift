import SwiftUI

public struct ChannelListView: View {
    @StateObject private var viewModel: ChannelListViewModel
    @EnvironmentObject private var router: NavigationRouter
    @EnvironmentObject private var themeManager: ThemeManager
    
    let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]
    
    public init(viewModel: ChannelListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
            // Dynamic Background
            themeManager.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header
                HStack {
                    Button {
                        router.pop()
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Geri")
                        }
                        .foregroundColor(themeManager.accentColor)
                    }
                    
                    Spacer()
                    
                    Text(viewModel.playlist.name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    Text("Geri").opacity(0)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Content Type Picker (Live TV / Movies / Series)
                Picker("İçerik Türü", selection: $viewModel.selectedTab) {
                    Text("Canlı TV").tag(MediaContentType.live)
                    Text("Filmler").tag(MediaContentType.movie)
                    Text("Diziler").tag(MediaContentType.series)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Ara...", text: $viewModel.searchQuery)
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: themeManager.accentColor))
                        .scaleEffect(1.5)
                    Spacer()
                } else {
                    switch viewModel.selectedTab {
                    case .live:
                        liveChannelsView
                    case .movie:
                        moviesGridView
                    case .series:
                        seriesGridView
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadData()
        }
    }
    
    // MARK: - Live TV Subview
    
    private var liveChannelsView: some View {
        VStack(spacing: 12) {
            // Categories
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    CategoryPill(title: "Tümü", isSelected: viewModel.selectedGroup == nil) {
                        viewModel.selectGroup(nil)
                    }
                    
                    ForEach(viewModel.groups) { group in
                        CategoryPill(title: group.name, isSelected: viewModel.selectedGroup == group.name) {
                            viewModel.selectGroup(group.name)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            if viewModel.filteredGroups.isEmpty {
                Spacer()
                Text("Kanal Bulunamadı").foregroundColor(.gray)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 14, pinnedViews: [.sectionHeaders]) {
                        ForEach(viewModel.filteredGroups) { group in
                            Section(header: SectionHeaderView(title: group.name)) {
                                ForEach(group.channels) { channel in
                                    ChannelRowView(
                                        channel: channel,
                                        currentProgramName: viewModel.getCurrentProgramName(for: channel.id),
                                        onFavoriteToggle: {
                                            Task {
                                                await viewModel.toggleFavorite(channel)
                                            }
                                        }
                                    ) {
                                        Task {
                                            await viewModel.playChannel(channel)
                                            router.navigate(to: .player(channel: channel))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Movies Subview (Poster Grid Layout)
    
    private var moviesGridView: some View {
        ScrollView {
            if viewModel.filteredMovies.isEmpty {
                Text("Film Bulunamadı")
                    .foregroundColor(.gray)
                    .padding(.top, 40)
            } else {
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(viewModel.filteredMovies) { movie in
                        VODPosterCard(title: movie.name, logoUrl: movie.logoUrl) {
                            router.navigate(to: .movieDetail(movie: movie))
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - TV Series Subview (Poster Grid Layout)
    
    private var seriesGridView: some View {
        ScrollView {
            if viewModel.filteredSeries.isEmpty {
                Text("Dizi Bulunamadı")
                    .foregroundColor(.gray)
                    .padding(.top, 40)
            } else {
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(viewModel.filteredSeries) { series in
                        VODPosterCard(title: series.name, logoUrl: series.logoUrl) {
                            router.navigate(to: .seriesDetail(series: series))
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// Reusable Poster/Card representing movie or TV show cover
struct VODPosterCard: View {
    let title: String
    let logoUrl: URL?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.04))
                        .aspectRatio(2/3, contentMode: .fit)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    
                    if let logoUrl = logoUrl {
                        AsyncImage(url: logoUrl) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "film").foregroundColor(.gray)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Image(systemName: "film")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    }
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 4)
            }
        }
    }
}
