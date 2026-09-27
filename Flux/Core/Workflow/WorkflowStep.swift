import Foundation

public struct WorkflowStep: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var actionKind: ActionKind
    public var configuration: ActionConfiguration
    
    public init(id: UUID = UUID(), actionKind: ActionKind, configuration: ActionConfiguration = ActionConfiguration()) {
        self.id = id
        self.actionKind = actionKind
        self.configuration = configuration
    }
}
