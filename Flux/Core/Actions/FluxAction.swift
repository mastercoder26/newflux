import Foundation

public protocol FluxAction: Sendable {
    var id: ActionKind { get }
    var title: String { get }
    var systemImage: String { get }
    var acceptedKinds: Set<ContentKind> { get }
    
    func accepts(_ content: FluxContent) -> Bool
    func expectedOutputKind(for inputKind: ContentKind, configuration: ActionConfiguration) -> ContentKind
    func execute(_ content: FluxContent, configuration: ActionConfiguration) async throws -> FluxContent
}

extension FluxAction {
    public var title: String {
        id.displayName
    }
    
    public var systemImage: String {
        id.systemImage
    }
}
