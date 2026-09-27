import SwiftUI

public struct SavedWorkflowsView: View {
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
                
                Text("Saved Workflows")
                    .font(.system(size: 15, weight: .semibold))
                
                Spacer()
                
                Button {
                    viewModel.mode = .workflowBuilder
                } label: {
                    Label("New", systemImage: "plus")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
            }
            
            if viewModel.savedWorkflows.isEmpty {
                VStack(spacing: 8) {
                    Text("No saved workflows.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(viewModel.savedWorkflows) { workflow in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(workflow.name)
                                        .font(.system(size: 13, weight: .medium))
                                    
                                    Text("\(workflow.steps.count) steps: " + workflow.steps.map { $0.actionKind.displayName }.joined(separator: " -> "))
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button {
                                    WorkflowStore.shared.delete(id: workflow.id)
                                    viewModel.refreshWorkflows()
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
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
