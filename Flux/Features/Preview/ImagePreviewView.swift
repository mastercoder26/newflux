import SwiftUI
import AppKit

public struct ImagePreviewView: View {
    let image: NSImage
    
    public init(image: NSImage) {
        self.image = image
    }
    
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .padding(8)
        }
        .frame(maxHeight: 180)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}
