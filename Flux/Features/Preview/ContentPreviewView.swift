import SwiftUI

public struct ContentPreviewView: View {
    let content: FluxContent
    let metadata: ContentMetadata?
    
    public init(content: FluxContent, metadata: ContentMetadata?) {
        self.content = content
        self.metadata = metadata
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with kind icon, title and details
            if let meta = metadata {
                HStack(spacing: 8) {
                    Image(systemName: meta.kind.systemImage)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(meta.displayName)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                        
                        Text(meta.subtitle)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
            
            // Content Preview Box
            switch content {
            case .text(let str):
                let isJSON = metadata?.kind == .json
                TextPreviewView(text: str, isMonospace: isJSON)
            case .url(let u):
                if u.isFileURL {
                    FilePreviewView(urls: [u])
                } else {
                    TextPreviewView(text: u.absoluteString, isMonospace: true)
                }
            case .image(let img, _):
                ImagePreviewView(image: img)
            case .pdf(let u):
                FilePreviewView(urls: [u])
            case .file(let u):
                FilePreviewView(urls: [u])
            case .files(let urls):
                FilePreviewView(urls: urls)
            }
        }
    }
}
