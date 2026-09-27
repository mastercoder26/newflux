import SwiftUI

public struct WorkflowBuilderView: View {
    @ObservedObject var viewModel: PaletteViewModel
    
    @State private var workflowName: String = ""
    @State private var steps: [WorkflowStep] = []
    @State private var showingAddActionSheet: Bool = false
    @State private var validationError: String? = nil
    
    private let registry = ActionRegistry.shared
    private let workflowStore = WorkflowStore.shared
    
    public init(viewModel: PaletteViewModel) {
        self.viewModel = viewModel
    }
    
    public var currentInputKind: ContentKind {
        viewModel.metadata?.kind ?? .image
    }
    
    public var intermediateKind: ContentKind {
        var kind = currentInputKind
        for step in steps {
            if let action = registry.action(for: step.actionKind) {
                kind = action.expectedOutputKind(for: kind, configuration: step.configuration)
            }
        }
        return kind
    }
    
    public var compatibleNextActions: [any FluxAction] {
        registry.compatibleActions(for: intermediateKind)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Button {
                    viewModel.back()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.plain)
                
                Text("Create Workflow")
                    .font(.system(size: 15, weight: .semibold))
                
                Spacer()
                
                Button("Save") {
                    saveWorkflow()
                }
                .buttonStyle(.borderedProminent)
                .disabled(workflowName.trimmingCharacters(in: .whitespaces).isEmpty || steps.isEmpty)
            }
            
            // Workflow Name Field
            TextField("Workflow Name (e.g. Web Ready)", text: $workflowName)
                .textFieldStyle(.roundedBorder)
            
            // Initial Input Badge
            HStack(spacing: 6) {
                Text("INPUT:")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                
                Label(currentInputKind.displayName, systemImage: currentInputKind.systemImage)
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.accentColor.opacity(0.12)))
                    .foregroundColor(.accentColor)
                
                Spacer()
            }
            
            // Steps List
            ScrollView {
                VStack(spacing: 8) {
                    if steps.isEmpty {
                        VStack(spacing: 8) {
                            Text("No steps added yet.")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            Text("Add compatible actions to build a reusable chain.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity, minHeight: 120)
                    } else {
                        ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                            WorkflowStepView(
                                index: index,
                                step: $steps[index],
                                onDelete: {
                                    steps.remove(at: index)
                                    validateCurrentChain()
                                }
                            )
                        }
                    }
                }
                .padding(2)
            }
            .frame(maxHeight: 220)
            
            if let error = validationError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 4)
            }
            
            Divider()
            
            // Add Action section
            VStack(alignment: .leading, spacing: 8) {
                Text("Compatible Next Actions")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                if compatibleNextActions.isEmpty {
                    Text("No further compatible actions for output: \(intermediateKind.displayName)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(compatibleNextActions, id: \.id) { action in
                                Button {
                                    addAction(action)
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: action.systemImage)
                                            .font(.system(size: 12))
                                        Text(action.title)
                                            .font(.system(size: 12))
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.7))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
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
        .padding(20)
    }
    
    private func addAction(_ action: any FluxAction) {
        let descriptor = registry.descriptor(for: action.id)
        let config = descriptor?.defaultConfiguration() ?? ActionConfiguration()
        let step = WorkflowStep(actionKind: action.id, configuration: config)
        steps.append(step)
        validateCurrentChain()
    }
    
    private func validateCurrentChain() {
        let wf = Workflow(id: UUID(), name: workflowName, steps: steps)
        let validator = WorkflowValidator(registry: registry)
        let result = validator.validate(workflow: wf, for: currentInputKind)
        if !result.isValid {
            validationError = result.errorMessage
        } else {
            validationError = nil
        }
    }
    
    private func saveWorkflow() {
        let trimmedName = workflowName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty, !steps.isEmpty else { return }
        
        let newWorkflow = Workflow(id: UUID(), name: trimmedName, steps: steps)
        workflowStore.save(newWorkflow)
        viewModel.refreshWorkflows()
        viewModel.back()
    }
}
