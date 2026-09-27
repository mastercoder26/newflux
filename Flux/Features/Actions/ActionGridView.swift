import SwiftUI

public struct ActionGridView: View {
    @ObservedObject var viewModel: PaletteViewModel
    
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    public init(viewModel: PaletteViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Actions")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Spacer()
                
                Button {
                    viewModel.mode = .workflowBuilder
                } label: {
                    Label("Create Workflow", systemImage: "plus")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 4)
            
            if viewModel.compatibleActions.isEmpty {
                Text("No compatible actions found for this content.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(viewModel.compatibleActions, id: \.id) { action in
                            let desc = ActionRegistry.shared.descriptor(for: action.id)
                            ActionRowView(action: action, descriptor: desc) {
                                viewModel.selectAction(action)
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.bottom, 6)
                }
            }
        }
    }
}
