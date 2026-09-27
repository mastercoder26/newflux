import Foundation

public struct HistoryEntry: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let inputKind: ContentKind
    public let actionName: String
    public let workflowName: String?
    public let outputKind: ContentKind
    public let summary: String
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        inputKind: ContentKind,
        actionName: String,
        workflowName: String? = nil,
        outputKind: ContentKind,
        summary: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.inputKind = inputKind
        self.actionName = actionName
        self.workflowName = workflowName
        self.outputKind = outputKind
        self.summary = summary
    }
}
