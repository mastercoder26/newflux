import Foundation

public struct ActionConfiguration: Codable, Equatable, Sendable {
    public var values: [String: String]
    
    public init(values: [String: String] = [:]) {
        self.values = values
    }
    
    public subscript(key: String) -> String? {
        get { values[key] }
        set { values[key] = newValue }
    }
    
    public func string(for key: String, default defaultValue: String = "") -> String {
        values[key] ?? defaultValue
    }
    
    public func int(for key: String, default defaultValue: Int = 0) -> Int {
        if let val = values[key], let intVal = Int(val) {
            return intVal
        }
        return defaultValue
    }
    
    public func double(for key: String, default defaultValue: Double = 0.0) -> Double {
        if let val = values[key], let dVal = Double(val) {
            return dVal
        }
        return defaultValue
    }
    
    public func bool(for key: String, default defaultValue: Bool = false) -> Bool {
        if let val = values[key]?.lowercased() {
            return val == "true" || val == "1" || val == "yes"
        }
        return defaultValue
    }
    
    public mutating func set(_ value: String, for key: String) {
        values[key] = value
    }
    
    public mutating func set(_ value: Int, for key: String) {
        values[key] = String(value)
    }
    
    public mutating func set(_ value: Double, for key: String) {
        values[key] = String(value)
    }
    
    public mutating func set(_ value: Bool, for key: String) {
        values[key] = value ? "true" : "false"
    }
}
