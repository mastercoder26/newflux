import SwiftUI

public struct InputBarView: View {
    @ObservedObject var viewModel: PaletteViewModel
    @FocusState private var isFocused: Bool
    
    public init(viewModel: PaletteViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 14, weight: .medium))
            
            TextField("Type or paste text, URL, JSON...", text: $viewModel.manualTextInput)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .focused($isFocused)
                .onSubmit {
                    viewModel.submitManualText()
                }
            
            if !viewModel.manualTextInput.isEmpty {
                Button {
                    viewModel.submitManualText()
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .onAppear {
            isFocused = true
        }
    }
}
