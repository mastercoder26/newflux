import SwiftUI

public struct ResultView: View {
    @ObservedObject var viewModel: PaletteViewModel
    @State private var copiedNotice = false
    
    public init(viewModel: PaletteViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Header with status and size reduction badge
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Transformation Complete")
                        .font(.system(size: 14, weight: .semibold))
                }
                
                Spacer()
                
                // Show size reduction badge if available
                if let initial = viewModel.initialFileSize, let result = viewModel.resultFileSize, initial > 0, result < initial {
                    let diff = Double(initial - result) / Double(initial) * 100.0
                    Text(String(format: "-%.1f%%", diff))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.green.opacity(0.15)))
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 4)
            
            // Content Preview
            if let result = viewModel.resultContent {
                ContentPreviewView(content: result, metadata: viewModel.resultMetadata)
            }
            
            // File size comparison info bar
            HStack(spacing: 12) {
                if let initSize = viewModel.initialFileSize {
                    Text("Original: \(formatBytes(initSize))")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                if let resSize = viewModel.resultFileSize {
                    Text("Result: \(formatBytes(resSize))")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if copiedNotice {
                    Text("Copied to clipboard")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 4)
            
            Divider()
            
            // Actions Row
            HStack(spacing: 10) {
                Button {
                    viewModel.copyResult()
                    withAnimation {
                        copiedNotice = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            copiedNotice = false
                        }
                    }
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("c", modifiers: .command)
                
                Button {
                    viewModel.exportResult()
                } label: {
                    Label("Save As...", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.bordered)
                .keyboardShortcut("s", modifiers: .command)
                
                if viewModel.lastExportedURL != nil || viewModel.resultContent?.singleFileURL != nil {
                    Button {
                        viewModel.revealLastExportedInFinder()
                    } label: {
                        Label("Reveal in Finder", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                Button {
                    viewModel.continueWithResult()
                } label: {
                    Label("Run Another Action", systemImage: "arrow.right.circle")
                }
                .buttonStyle(.bordered)
                
                Button("Done") {
                    viewModel.resetToEmpty()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.return, modifiers: [])
            }
            .padding(.top, 4)
        }
        .padding(16)
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
