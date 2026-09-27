import Foundation

public enum AppSettings {
    public static let showRecentWorkflowsKey = "showRecentWorkflows"
    public static let defaultJPEGQualityKey = "defaultJPEGQuality"
    public static let defaultResizeWidthKey = "defaultResizeWidth"
    
    public static var defaultResizeWidth: Int {
        get {
            let val = UserDefaults.standard.integer(forKey: defaultResizeWidthKey)
            return val > 0 ? val : 1200
        }
        set {
            UserDefaults.standard.set(newValue, forKey: defaultResizeWidthKey)
        }
    }
    
    public static var defaultJPEGQuality: Double {
        get {
            let val = UserDefaults.standard.double(forKey: defaultJPEGQualityKey)
            return val > 0.0 ? val : 0.85
        }
        set {
            UserDefaults.standard.set(newValue, forKey: defaultJPEGQualityKey)
        }
    }
}
