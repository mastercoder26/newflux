import Foundation

public struct WorkflowValidationResult: Sendable {
    public let isValid: Bool
    public let errorMessage: String?
    public let outputKind: ContentKind?
    
    public static func valid(outputKind: ContentKind) -> WorkflowValidationResult {
        WorkflowValidationResult(isValid: true, errorMessage: nil, outputKind: outputKind)
    }
    
    public static func invalid(_ message: String) -> WorkflowValidationResult {
        WorkflowValidationResult(isValid: false, errorMessage: message, outputKind: nil)
    }
}

public struct WorkflowValidator: Sendable {
    private let registry: ActionRegistry
    
    public init(registry: ActionRegistry = .shared) {
        self.registry = registry
    }
    
    public func validate(workflow: Workflow, for initialKind: ContentKind) -> WorkflowValidationResult {
        guard !workflow.steps.isEmpty else {
            return .invalid("Workflow has no steps.")
        }
        
        var currentKind = initialKind
        var previousActionName: String? = nil
        
        for step in workflow.steps {
            guard let action = registry.action(for: step.actionKind) else {
                return .invalid("Unknown action: \(step.actionKind.rawValue).")
            }
            
            // Check if current action accepts currentKind
            if !action.acceptedKinds.contains(currentKind) {
                if let prev = previousActionName {
                    return .invalid("\(action.title) cannot run after \(prev) because \(prev) outputs \(currentKind.displayName.lowercased()).")
                } else {
                    return .invalid("\(action.title) cannot accept input of type \(currentKind.displayName.lowercased()).")
                }
            }
            
            // Calculate output kind
            currentKind = action.expectedOutputKind(for: currentKind, configuration: step.configuration)
            previousActionName = action.title
        }
        
        return .valid(outputKind: currentKind)
    }
}
