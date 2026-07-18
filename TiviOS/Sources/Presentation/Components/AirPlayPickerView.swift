import SwiftUI
import AVKit

public struct AirPlayPickerView: UIViewRepresentable {
    public init() {}
    
    public func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.activeTintColor = UIColor(red: 255/255, green: 0/255, blue: 122/255, alpha: 1.0) // FF007A
        picker.tintColor = .white
        return picker
    }
    
    public func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        // No-op
    }
}
