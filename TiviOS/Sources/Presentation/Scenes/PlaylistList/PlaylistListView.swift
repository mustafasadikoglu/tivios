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
                        .onChange(of: viewModel.globalSearchQuery) { newValue in
                            Task {
                                await viewModel.search(query: newValue)
                            }
                        }
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
                                    Task {
                                        await viewModel.search(query: viewModel.globalSearchQuery, resolution: res)
                                    }
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

// Subview representing a recently watched live channel
struct RecentChannelCard: View {
    let channel: Channel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.04))
                        .frame(width: 100, height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    
                    if let logoUrl = channel.logoUrl {
                        AsyncImage(url: logoUrl) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Image(systemName: "tv").foregroundColor(.gray)
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Image(systemName: "tv")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                }
                
                Text(channel.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .frame(width: 100)
            }
        }
    }
}

// Subview card for playlist items on main dashboard
struct PlaylistCard: View {
    let playlist: Playlist
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon / Type indicator
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: playlist.type == .m3u ? "list.bullet.rectangle" : "network")
                        .font(.title3)
                        .foregroundColor(Color(hex: "FF007A"))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(playlist.name)
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(playlist.type == .m3u ? "M3U Listesi" : "Xtream Codes Api")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(0.8))
                        .padding(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color.white.opacity(0.03))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Modal view sheet for adding a new Playlist (supports both M3U URLs and Xtream credentials)
struct AddPlaylistSheet: View {
    @ObservedObject var viewModel: PlaylistListViewModel
    
    var body: some View {
        ZStack {
            Color(hex: "0F0C20").ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Yeni Liste Ekle")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Picker("Tip", selection: $viewModel.addPlaylistType) {
                    Text("M3U Bağlantısı").tag(PlaylistType.m3u)
                    Text("Xtream Hesabı").tag(PlaylistType.xtream)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                VStack(spacing: 16) {
                    TextField("Liste Adı", text: $viewModel.newPlaylistName)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                    
                    if viewModel.addPlaylistType == .m3u {
                        TextField("M3U Linki (http...)", text: $viewModel.newPlaylistUrl)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    } else {
                        TextField("Sunucu Adresi (http://domain.com:port)", text: $viewModel.xtreamHost)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        TextField("Kullanıcı Adı", text: $viewModel.xtreamUsername)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        SecureField("Şifre", text: $viewModel.xtreamPassword)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
                
                Button {
                    Task {
                        await viewModel.addPlaylist()
                    }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Kaydet")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(colors: [Color(hex: "FF007A"), Color(hex: "7928CA")], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .disabled(viewModel.isLoading)
                
                Spacer()
            }
            .padding(.top, 40)
        }
    }
}
