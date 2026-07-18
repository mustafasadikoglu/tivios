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
                        HUDBare(icon: "speaker.wave.3.fill", value: viewModel.volumeLevel, title: "Ses")
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
                        
                        // AirPlay Yansıtma Butonu
                        AirPlayPickerView()
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                            .clipShape(Circle())
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
