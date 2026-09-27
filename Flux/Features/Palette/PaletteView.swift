import SwiftUI

public struct PaletteView: View {
    @ObservedObject var viewModel: PaletteViewModel
    @State private var showingSettings = false
    
    public init(viewModel: PaletteViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Palette Header
            HStack(spacing: 12) {
                if viewModel.mode != .empty {
                    Button {
                        viewModel.back()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.accentColor)
                    
                    Text("Flux")
                        .font(.system(size: 14, weight: .semibold))
                }
                
                Spacer()
                
                Button {
                    viewModel.mode = .history
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("History")
                
                Button {
                    showingSettings.toggle()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Settings")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.primary.opacity(0.03))
            
            Divider()
            
            // Error Banner
            if let error = viewModel.errorMessage, viewModel.mode != .processing {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                    Spacer()
                    Button {
                        viewModel.errorMessage = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                Divider()
            }
            
            // Content switching
            ZStack {
                switch viewModel.mode {
                case .empty:
                    DropZoneView(viewModel: viewModel)
                        .padding(16)
                case .content:
                    if let content = viewModel.content {
                        VStack(spacing: 16) {
                            ContentPreviewView(content: content, metadata: viewModel.metadata)
                            Divider()
                            ActionGridView(viewModel: viewModel)
                        }
                        .padding(16)
                    }
                case .configuring:
                    ActionConfigurationView(viewModel: viewModel)
                case .processing:
                    WorkflowProgressView(viewModel: viewModel)
                case .result:
                    ResultView(viewModel: viewModel)
                case .workflowBuilder:
                    WorkflowBuilderView(viewModel: viewModel)
                case .history:
                    HistoryView(viewModel: viewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 700, height: 530)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onDrop(of: [.fileURL, .text, .image, .pdf, .url], isTargeted: $viewModel.isTargetedForDrop) { providers in
            viewModel.handleDrop(providers: providers)
        }
    }
}
