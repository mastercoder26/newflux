import SwiftUI

public struct TextPreviewView: View {
    let text: String
    var isMonospace: Bool = false
    
    public init(text: String, isMonospace: Bool = false) {
        self.text = text
        self.isMonospace = isMonospace
    }
    
    public var body: some View {
        ScrollView {
            Text(text)
                .font(isMonospace ? .system(size: 12, design: .monospaced) : .system(size: 13))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .padding(12)
        }
        .frame(maxHeight: 180)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .textBackgroundColor).opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}
