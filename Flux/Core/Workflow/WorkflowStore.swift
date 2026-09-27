import Foundation

public final class WorkflowStore: @unchecked Sendable {
    public static let shared = WorkflowStore()
    
    private let lock = NSLock()
    private var workflows: [Workflow] = []
    private let fileURL: URL
    
    public init(fileURL: URL? = nil) {
        if let fileURL = fileURL {
            self.fileURL = fileURL
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let fluxDir = appSupport.appendingPathComponent("Flux", isDirectory: true)
            if !FileManager.default.fileExists(atPath: fluxDir.path) {
                try? FileManager.default.createDirectory(at: fluxDir, withIntermediateDirectories: true)
            }
            self.fileURL = fluxDir.appendingPathComponent("workflows.json")
        }
        
        load()
        if workflows.isEmpty {
            seedDefaults()
        }
    }
    
    public func all() -> [Workflow] {
        lock.lock()
        defer { lock.unlock() }
        return workflows
    }
    
    public func save(_ workflow: Workflow) {
        lock.lock()
        if let index = workflows.firstIndex(where: { $0.id == workflow.id }) {
            workflows[index] = workflow
        } else {
            workflows.append(workflow)
        }
        lock.unlock()
        persist()
    }
    
    public func delete(id: UUID) {
        lock.lock()
        workflows.removeAll { $0.id == id }
        lock.unlock()
        persist()
    }
    
    private func load() {
        lock.lock()
        defer { lock.unlock() }
        
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else {
            return
        }
        
        let decoder = JSONDecoder()
        if let loaded = try? decoder.decode([Workflow].self, from: data) {
            self.workflows = loaded
        }
    }
    
    private func persist() {
        lock.lock()
        let toSave = workflows
        let targetURL = fileURL
        lock.unlock()
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(toSave)
            try data.write(to: targetURL, options: [.atomic])
        } catch {
            print("Failed to save workflows: \(error)")
        }
    }
    
    private func seedDefaults() {
        var webReadyConfig1 = ActionConfiguration()
        webReadyConfig1.set(1600, for: "width")
        webReadyConfig1.set(true, for: "preserveAspectRatio")
        
        var webReadyConfig2 = ActionConfiguration()
        webReadyConfig2.set(0.85, for: "quality")
        
        var webReadyConfig3 = ActionConfiguration()
        webReadyConfig3.set(0.80, for: "quality")
        
        let webReady = Workflow(
            id: UUID(),
            name: "Web Ready",
            steps: [
                WorkflowStep(actionKind: .resizeImage, configuration: webReadyConfig1),
                WorkflowStep(actionKind: .convertToJPEG, configuration: webReadyConfig2),
                WorkflowStep(actionKind: .compressJPEG, configuration: webReadyConfig3)
            ]
        )
        
        let ocrScreenshot = Workflow(
            id: UUID(),
            name: "OCR Screenshot",
            steps: [
                WorkflowStep(actionKind: .ocr)
            ]
        )
        
        save(webReady)
        save(ocrScreenshot)
    }
}
