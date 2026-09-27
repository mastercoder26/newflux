import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct DropZoneView: View {
    @ObservedObject var viewModel: PaletteViewModel
    
    public init(viewModel: PaletteViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            // Main Drop Zone Area
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            viewModel.isTargetedForDrop ? Color.accentColor : Color.secondary.opacity(0.25),
                            style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(viewModel.isTargetedForDrop ? Color.accentColor.opacity(0.08) : Color.clear)
                        )
                    
                    VStack(spacing: 14) {
                        Image(systemName: viewModel.isTargetedForDrop ? "arrow.down.circle.fill" : "plus.viewfinder")
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(viewModel.isTargetedForDrop ? .accentColor : .secondary)
                        
                        VStack(spacing: 4) {
                            Text(viewModel.isTargetedForDrop ? "Release to open in Flux" : "Paste or drop anything")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Text("Text • Images • PDFs • URLs • JSON")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 14) {
                            Button {
                                viewModel.pasteClipboard()
                            } label: {
                                Label("Paste", systemImage: "doc.on.clipboard")
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.borderedProminent)
                            .keyboardShortcut("v", modifiers: .command)
                            
                            Button {
                                selectFile()
                            } label: {
                                Label("Choose File", systemImage: "folder")
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.top, 4)
                    }
                    .padding(24)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .onDrop(of: [.fileURL, .text, .image, .pdf, .url], isTargeted: $viewModel.isTargetedForDrop) { providers in
                    viewModel.handleDrop(providers: providers)
                }
            }
            
            // Manual Input Bar
            InputBarView(viewModel: viewModel)
            
            // Saved Workflows Quick Access
            if !viewModel.savedWorkflows.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Workflows")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.savedWorkflows) { workflow in
                                Button {
                                    viewModel.pasteClipboard()
                                    if viewModel.content != nil {
                                        viewModel.runWorkflow(workflow)
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "point.3.connected.trianglepath.dotted")
                                            .font(.system(size: 12))
                                        Text(workflow.name)
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.8))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.prompt = "Choose"
        
        if panel.runModal() == .OK {
            viewModel.handleFileDrop(urls: panel.urls)
        }
    }
}
