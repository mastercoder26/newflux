import Foundation

public final class HistoryStore: @unchecked Sendable {
    public static let shared = HistoryStore()
    
    private let lock = NSLock()
    private var entries: [HistoryEntry] = []
    private let fileURL: URL
    private let maxEntries: Int = 100
    
    public init(fileURL: URL? = nil) {
        if let fileURL = fileURL {
            self.fileURL = fileURL
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let fluxDir = appSupport.appendingPathComponent("Flux", isDirectory: true)
            if !FileManager.default.fileExists(atPath: fluxDir.path) {
                try? FileManager.default.createDirectory(at: fluxDir, withIntermediateDirectories: true)
            }
            self.fileURL = fluxDir.appendingPathComponent("history.json")
        }
        
        load()
    }
    
    public func all() -> [HistoryEntry] {
        lock.lock()
        defer { lock.unlock() }
        return entries
    }
    
    public func add(_ entry: HistoryEntry) {
        lock.lock()
        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }
        lock.unlock()
        persist()
    }
    
    public func clear() {
        lock.lock()
        entries.removeAll()
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
        if let loaded = try? decoder.decode([HistoryEntry].self, from: data) {
            self.entries = loaded
        }
    }
    
    private func persist() {
        lock.lock()
        let toSave = entries
        let targetURL = fileURL
        lock.unlock()
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(toSave)
            try data.write(to: targetURL, options: [.atomic])
        } catch {
            print("Failed to save history: \(error)")
        }
    }
}
