import SwiftUI
import AVKit

public struct PlayerView: View {
    @StateObject private var viewModel: PlayerViewModel
    @EnvironmentObject private var router: NavigationRouter
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showTracksSheet = false
    
    public init(viewModel: PlayerViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Video Screen
                if let player = viewModel.player {
                    PlayerContainerView(player: player, videoGravity: viewModel.videoGravity)
                        .ignoresSafeArea()
                }
                
                // Left & Right Swipe Gestures Overlay (Mobile only)
                HStack(spacing: 0) {
                    // Left Half: Brightness
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 10)
                                .onChanged { value in
                                    let delta = -value.translation.height / geometry.size.height * 0.1
                                    viewModel.adjustBrightness(by: delta)
                                }
                        )
                    
                    // Right Half: Volume
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 10)
                                .onChanged { value in
                                    let delta = Float(-value.translation.height / geometry.size.height) * 0.1
                                    viewModel.adjustVolume(by: delta)
                                }
                        )
                }
                .ignoresSafeArea()
                
                // HUD Indicators (Overlay)
                VStack {
                    Spacer()
                    if viewModel.showVolumeHUD {
                        HUDBare(icon: "speaker.wave.3.fill", value: CGFloat(viewModel.volumeLevel), title: "Ses")
                    }
                    if viewModel.showBrightnessHUD {
                        HUDBare(icon: "sun.max.fill", value: viewModel.brightnessLevel, title: "Parlaklık")
                    }
                    Spacer()
                }
                
                // Custom Controls HUD Overlay
                VStack {
                    // Top Bar
                    HStack {
                        Button {
                            viewModel.stop()
                            router.pop()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding()
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                        
                        Spacer()
                        
                        Text(viewModel.channel.name)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.black.opacity(0.6)))
                        
                        Spacer()
                        
                        Button {
                            viewModel.toggleAspectRatio()
                        } label: {
                            Image(systemName: "aspectratio.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding()
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: themeManager.accentColor))
                            .scaleEffect(2)
                    }
                    
                    if let errorMessage = viewModel.errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                            
                            Text(errorMessage)
                                .font(.callout)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            
                            Button {
                                viewModel.startPlayback()
                            } label: {
                                Text("Tekrar Dene")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 10)
                                    .background(Capsule().fill(themeManager.accentColor))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Bottom Controls Bar
                    HStack(spacing: 24) {
                        // Tracks Picker
                        Button {
                            showTracksSheet = true
                        } label: {
                            Image(systemName: "captions.bubble.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                        
                        // Play/Pause Button
                        Button {
                            viewModel.togglePlayPause()
                        } label: {
                            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding(20)
                                .background(Circle().fill(themeManager.accentColor))
                        }
                        
                        #if os(iOS)
                        // AirPlay Yansıtma Butonu
                        AirPlayPickerView()
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                            .clipShape(Circle())
                        #endif
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.startPlayback()
        }
        .onDisappear {
            viewModel.stop()
        }
        .sheet(isPresented: $showTracksSheet) {
            MediaTracksSelectionSheet(viewModel: viewModel)
        }
    }
}

// Custom Video Player Container supporting Gravity
struct PlayerContainerView: UIViewControllerRepresentable {
    let player: AVPlayer
    let videoGravity: AVLayerVideoGravity
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = videoGravity
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.videoGravity = videoGravity
    }
}

// Swipe Gesture HUD Indicator Overlay
struct HUDBare: View {
    let icon: String
    let value: CGFloat
    let title: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            ProgressView(value: Double(value), total: 1.0)
                .accentColor(Color(hex: "FF007A"))
                .frame(width: 120)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.8)))
    }
}

// Subtitles & Audio Track Selector Screen
struct MediaTracksSelectionSheet: View {
    @ObservedObject var viewModel: PlayerViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(hex: "0F0C20").ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Medya Seçenekleri")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    // Audio Tracks Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ses Dili / Kanalı")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        if viewModel.audioTracks.isEmpty {
                            Text("Varsayılan Ses").foregroundColor(.white)
                        } else {
                            ForEach(viewModel.audioTracks, id: \.self) { track in
                                Button {
                                    viewModel.selectAudioTrack(track)
                                } label: {
                                    HStack {
                                        Text(track.displayName)
                                            .foregroundColor(.white)
                                        Spacer()
                                        if viewModel.selectedAudioTrack == track {
                                            Image(systemName: "checkmark").foregroundColor(Color(hex: "FF007A"))
                                        }
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    // Subtitles Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Altyazılar")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Button {
                            viewModel.selectSubtitleTrack(nil)
                        } label: {
                            HStack {
                                Text("Altyazı Yok")
                                    .foregroundColor(.white)
                                Spacer()
                                if viewModel.selectedSubtitleTrack == nil {
                                    Image(systemName: "checkmark").foregroundColor(Color(hex: "FF007A"))
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                        }
                        
                        ForEach(viewModel.subtitleTracks, id: \.self) { track in
                            Button {
                                viewModel.selectSubtitleTrack(track)
                            } label: {
                                HStack {
                                    Text(track.displayName)
                                        .foregroundColor(.white)
                                    Spacer()
                                    if viewModel.selectedSubtitleTrack == track {
                                        Image(systemName: "checkmark").foregroundColor(Color(hex: "FF007A"))
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(24)
            }
        }
    }
}
