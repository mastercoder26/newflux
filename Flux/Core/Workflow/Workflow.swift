import Foundation

public struct Workflow: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var steps: [WorkflowStep]
    
    public init(id: UUID = UUID(), name: String, steps: [WorkflowStep] = []) {
        self.id = id
        self.name = name
        self.steps = steps
    }
}
