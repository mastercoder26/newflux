import SwiftUI

public struct HistoryView: View {
    @ObservedObject var viewModel: PaletteViewModel
    
    public init(viewModel: PaletteViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Button {
                    viewModel.back()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.plain)
                
                Text("Transformation History")
                    .font(.system(size: 15, weight: .semibold))
                
                Spacer()
                
                if !viewModel.historyEntries.isEmpty {
                    Button("Clear History") {
                        viewModel.clearHistory()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
                }
            }
            
            if viewModel.historyEntries.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("No history yet.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(viewModel.historyEntries) { entry in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: entry.outputKind.systemImage)
                                    .font(.system(size: 16))
                                    .foregroundColor(.accentColor)
                                    .frame(width: 24, height: 24)
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text(entry.actionName)
                                            .font(.system(size: 13, weight: .medium))
                                        
                                        if let wf = entry.workflowName {
                                            Text("via \(wf)")
                                                .font(.system(size: 10))
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 1)
                                                .background(Capsule().fill(Color.primary.opacity(0.08)))
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(entry.timestamp, style: .time)
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text(entry.summary)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                            )
                        }
                    }
                    .padding(2)
                }
            }
        }
        .padding(20)
    }
}
