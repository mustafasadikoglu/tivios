import Foundation
import AVFoundation
import Combine
#if canImport(UIKit)
import UIKit
#endif

@MainActor
public final class PlayerViewModel: ObservableObject {
    public let channel: Channel
    
    @Published public var player: AVPlayer?
    @Published public var isPlaying = false
    @Published public var isLoading = true
    @Published public var errorMessage: String?
    
    // Gestures HUD
    @Published public var showVolumeHUD = false
    @Published public var volumeLevel: Float = 1.0
    @Published public var showBrightnessHUD = false
    @Published public var brightnessLevel: CGFloat = 1.0
    
    // Video aspect ratio
    @Published public var videoGravity: AVLayerVideoGravity = .resizeAspect
    
    // Track Selection
    @Published public var audioTracks: [AVMediaSelectionOption] = []
    @Published public var selectedAudioTrack: AVMediaSelectionOption? = nil
    @Published public var subtitleTracks: [AVMediaSelectionOption] = []
    @Published public var selectedSubtitleTrack: AVMediaSelectionOption? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(channel: Channel) {
        self.channel = channel
    }
    
    public func startPlayback() {
        isLoading = true
        errorMessage = nil
        
        // Stop any previous player
        player?.pause()
        player = nil
        cancellables.removeAll()
        
        // Use standard URL initialization (AVURLAsset with custom headers sometimes breaks .ts parsing on iOS)
        let playerItem = AVPlayerItem(url: channel.streamUrl)
        playerItem.preferredForwardBufferDuration = 5 // Buffer 5 seconds ahead
        
        let player = AVPlayer(playerItem: playerItem)
        player.automaticallyWaitsToMinimizeStalling = true
        self.player = player
        
        // Observe loading / playback state
        playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                switch status {
                case .readyToPlay:
                    self.isLoading = false
                    self.isPlaying = true
                    self.loadMediaSelectionTracks()
                    player.play()
                case .failed:
                    self.isLoading = false
                    let failureReason = playerItem.error?.localizedDescription ?? "Bilinmeyen hata"
                    self.errorMessage = "Yayın yüklenemedi: \(failureReason)"
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Observe player error notifications
        NotificationCenter.default.publisher(for: .AVPlayerItemFailedToPlayToEndTime, object: playerItem)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self else { return }
                let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
                self.errorMessage = "Akış kesildi: \(error?.localizedDescription ?? "Bağlantı koptu")"
                self.isPlaying = false
            }
            .store(in: &cancellables)
        
        // Timeout: if still loading after 15 seconds, show error
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 15_000_000_000)
            guard let self = self else { return }
            if self.isLoading {
                self.isLoading = false
                self.errorMessage = "Bağlantı zaman aşımına uğradı. Sunucu yanıt vermiyor."
            }
        }
    }
    
    public func togglePlayPause() {
        guard let player = player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }
    
    public func toggleAspectRatio() {
        if videoGravity == .resizeAspect {
            videoGravity = .resizeAspectFill
        } else if videoGravity == .resizeAspectFill {
            videoGravity = .resize
        } else {
            videoGravity = .resizeAspect
        }
    }
    
    // Adjust Volume (called by Swipe gesture)
    public func adjustVolume(by delta: Float) {
        guard let player = player else { return }
        let current = player.volume
        let target = max(0.0, min(1.0, current + delta))
        player.volume = target
        volumeLevel = target
        showVolumeHUD = true
        
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            self.showVolumeHUD = false
        }
    }
    
    // Adjust Brightness (called by Swipe gesture - iOS only)
    public func adjustBrightness(by delta: CGFloat) {
        #if os(iOS)
        let current = UIScreen.main.brightness
        let target = max(0.0, min(1.0, current + delta))
        UIScreen.main.brightness = target
        brightnessLevel = target
        showBrightnessHUD = true
        
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            self.showBrightnessHUD = false
        }
        #endif
    }
    
    // MARK: - Media Selection Tracks (Audio & Subtitles)
    
    private func loadMediaSelectionTracks() {
        guard let asset = player?.currentItem?.asset else { return }
        
        // 1. Audio Tracks
        if let audioGroup = asset.mediaSelectionGroup(forMediaCharacteristic: .audible) {
            audioTracks = audioGroup.options
            selectedAudioTrack = player?.currentItem?.currentMediaSelection.selectedMediaOption(in: audioGroup)
        }
        
        // 2. Subtitle Tracks
        if let subtitleGroup = asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
            subtitleTracks = subtitleGroup.options
            selectedSubtitleTrack = player?.currentItem?.currentMediaSelection.selectedMediaOption(in: subtitleGroup)
        }
    }
    
    public func selectAudioTrack(_ option: AVMediaSelectionOption) {
        guard let playerItem = player?.currentItem,
              let asset = player?.currentItem?.asset,
              let group = asset.mediaSelectionGroup(forMediaCharacteristic: .audible) else { return }
        
        playerItem.select(option, in: group)
        selectedAudioTrack = option
    }
    
    public func selectSubtitleTrack(_ option: AVMediaSelectionOption?) {
        guard let playerItem = player?.currentItem,
              let asset = player?.currentItem?.asset,
              let group = asset.mediaSelectionGroup(forMediaCharacteristic: .legible) else { return }
        
        playerItem.select(option, in: group)
        selectedSubtitleTrack = option
    }
    
    public func stop() {
        player?.pause()
        player = nil
        isPlaying = false
    }
}
