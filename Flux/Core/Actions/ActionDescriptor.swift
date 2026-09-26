import Foundation

public enum ActionParameterType: Sendable {
    case string
    case integer(min: Int, max: Int)
    case double(min: Double, max: Double, step: Double)
    case boolean
    case selection([String])
}

public struct ActionParameterDescriptor: Sendable {
    public let key: String
    public let label: String
    public let type: ActionParameterType
    public let defaultValue: String
    
    public init(key: String, label: String, type: ActionParameterType, defaultValue: String) {
        self.key = key
        self.label = label
        self.type = type
        self.defaultValue = defaultValue
    }
}

public struct ActionDescriptor: Sendable {
    public let kind: ActionKind
    public let title: String
    public let subtitle: String
    public let systemImage: String
    public let acceptedKinds: Set<ContentKind>
    public let parameters: [ActionParameterDescriptor]
    
    public init(
        kind: ActionKind,
        title: String,
        subtitle: String,
        systemImage: String,
        acceptedKinds: Set<ContentKind>,
        parameters: [ActionParameterDescriptor] = []
    ) {
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.acceptedKinds = acceptedKinds
        self.parameters = parameters
    }
    
    public var hasConfiguration: Bool {
        !parameters.isEmpty
    }
    
    public func defaultConfiguration() -> ActionConfiguration {
        var values: [String: String] = [:]
        for p in parameters {
            values[p.key] = p.defaultValue
        }
        return ActionConfiguration(values: values)
    }
}
