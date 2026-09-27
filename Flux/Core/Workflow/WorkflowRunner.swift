import Foundation

public enum WorkflowStepStatus: Equatable, Sendable {
    case pending
    case running
    case completed
    case failed(String)
}

public struct WorkflowProgress: Equatable, Sendable {
    public let stepIndex: Int
    public let totalSteps: Int
    public let actionTitle: String
    public let status: WorkflowStepStatus
    
    public var stepNumber: Int { stepIndex + 1 }
}

public struct WorkflowRunner: Sendable {
    private let registry: ActionRegistry
    
    public init(registry: ActionRegistry = .shared) {
        self.registry = registry
    }
    
    public func run(
        workflow: Workflow,
        initialContent: FluxContent,
        onProgress: (@Sendable (WorkflowProgress) -> Void)? = nil
    ) async throws -> FluxContent {
        guard !workflow.steps.isEmpty else {
            throw ActionError.actionFailed("Workflow contains no steps.")
        }
        
        var currentContent = initialContent
        let totalSteps = workflow.steps.count
        
        for (index, step) in workflow.steps.enumerated() {
            guard let action = registry.action(for: step.actionKind) else {
                let msg = "Action '\(step.actionKind.displayName)' is not registered."
                onProgress?(WorkflowProgress(stepIndex: index, totalSteps: totalSteps, actionTitle: step.actionKind.displayName, status: .failed(msg)))
                throw ActionError.actionFailed(msg)
            }
            
            guard action.accepts(currentContent) else {
                let msg = "Step \(index + 1) (\(action.title)) cannot accept the intermediate content."
                onProgress?(WorkflowProgress(stepIndex: index, totalSteps: totalSteps, actionTitle: action.title, status: .failed(msg)))
                throw ActionError.workflowIncompatible(msg)
            }
            
            onProgress?(WorkflowProgress(stepIndex: index, totalSteps: totalSteps, actionTitle: action.title, status: .running))
            
            do {
                currentContent = try await action.execute(currentContent, configuration: step.configuration)
                onProgress?(WorkflowProgress(stepIndex: index, totalSteps: totalSteps, actionTitle: action.title, status: .completed))
            } catch {
                let desc = error.localizedDescription
                onProgress?(WorkflowProgress(stepIndex: index, totalSteps: totalSteps, actionTitle: action.title, status: .failed(desc)))
                throw error
            }
        }
        
        return currentContent
    }
}
