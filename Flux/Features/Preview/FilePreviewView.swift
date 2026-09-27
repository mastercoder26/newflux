import SwiftUI

public struct FilePreviewView: View {
    let urls: [URL]
    
    public init(urls: [URL]) {
        self.urls = urls
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            if urls.count == 1, let first = urls.first {
                HStack(spacing: 12) {
                    Image(systemName: iconName(for: first))
                        .font(.system(size: 28))
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(first.lastPathComponent)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(1)
                        
                        Text(first.deletingLastPathComponent().path)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding(12)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(urls, id: \.self) { url in
                            HStack(spacing: 8) {
                                Image(systemName: iconName(for: url))
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                
                                Text(url.lastPathComponent)
                                    .font(.system(size: 12))
                                    .lineLimit(1)
                                
                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(10)
                }
                .frame(maxHeight: 140)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
    
    private func iconName(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        if ext == "pdf" { return "doc.richtext" }
        if ["png", "jpg", "jpeg", "webp", "gif"].contains(ext) { return "photo" }
        return "doc"
    }
}
