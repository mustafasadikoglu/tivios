import SwiftUI

public struct PlaylistListView: View {
    @StateObject private var viewModel: PlaylistListViewModel
    @EnvironmentObject private var router: NavigationRouter
    @EnvironmentObject private var themeManager: ThemeManager
    
    public init(viewModel: PlaylistListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ZStack {
            // Dynamic Theme Background
            themeManager.backgroundGradient.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TiviOS")
                            .font(.system(.largeTitle, design: .rounded))
                            .fontWeight(.black)
                            .foregroundStyle(themeManager.primaryGradient)
                        
                        Text("IPTV Merkeziniz")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Theme Menu Selection
                    Menu {
                        ForEach(ThemeType.allCases, id: \.self) { type in
                            Button {
                                themeManager.currentThemeType = type
                            } label: {
                                HStack {
                                    Text(type.rawValue)
                                    if themeManager.currentThemeType == type {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "paintpalette.fill")
                            .font(.title2)
                            .foregroundColor(themeManager.accentColor)
                            .padding(8)
                    }
                    
                    Button {
                        viewModel.showAddPlaylistSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundStyle(themeManager.primaryGradient)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Global Search Input
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Tüm Listelerde Kanal Ara...", text: $viewModel.globalSearchQuery)
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Resolution Filters (when searching globally)
                if !viewModel.globalSearchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(ResolutionFilter.allCases, id: \.self) { res in
                                Button {
                                    viewModel.selectedResolution = res
                                } label: {
                                    Text(res.rawValue)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .foregroundColor(viewModel.selectedResolution == res ? .white : .gray)
                                        .background(
                                            Capsule()
                                                .fill(viewModel.selectedResolution == res ?
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
                
                if viewModel.isLoading {
                    Spacer()
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: themeManager.accentColor))
                            .scaleEffect(1.5)
                        Spacer()
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Global Search Results View
                            if !viewModel.globalSearchResults.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Global Arama Sonuçları")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal)
                                    
                                    LazyVStack(spacing: 12) {
                                        ForEach(viewModel.globalSearchResults) { channel in
                                            ChannelRowView(channel: channel, currentProgramName: nil, onFavoriteToggle: {}) {
                                                Task {
                                                    await viewModel.playChannel(channel)
                                                    router.navigate(to: .player(channel: channel))
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            } else if !viewModel.globalSearchQuery.isEmpty {
                                // Searching but no results
                                VStack(spacing: 12) {
                                    Image(systemName: "questionmark.folder.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                    Text("Eşleşen yayın bulunamadı.")
                                        .foregroundColor(.gray)
                                        .font(.subheadline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                // Default Dashboard View (Recents & Playlists)
                                
                                // Recently Watched
                                if !viewModel.recents.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Son İzlenen Kanallar")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding(.horizontal)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 14) {
                                                ForEach(viewModel.recents) { channel in
                                                    RecentChannelCard(channel: channel) {
                                                        router.navigate(to: .player(channel: channel))
                                                    }
                                                }
                                            }
                                            .padding(.horizontal)
                                        }
                                    }
                                }
                                
                                // Playlists
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Oynatma Listeleriniz")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal)
                                    
                                    if viewModel.playlists.isEmpty {
                                        VStack(spacing: 16) {
                                            Image(systemName: "tv.slash.fill")
                                                .font(.system(size: 48))
                                                .foregroundStyle(.gray.opacity(0.5))
                                            
                                            Text("Henüz Liste Yok")
                                                .foregroundColor(.gray)
                                                .font(.subheadline)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 40)
                                    } else {
                                        LazyVStack(spacing: 16) {
                                            ForEach(viewModel.playlists) { playlist in
                                                PlaylistCard(playlist: playlist) {
                                                    router.navigate(to: .channelList(playlist: playlist))
                                                } onDelete: {
                                                    Task {
                                                        await viewModel.deletePlaylist(playlist)
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.showAddPlaylistSheet) {
            AddPlaylistSheet(viewModel: viewModel)
        }
        .task {
            await viewModel.loadPlaylists()
        }
    }
}
