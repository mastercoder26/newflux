import Foundation
import CryptoKit

public enum FileUtilities {
    public static var fluxTempDirectory: URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("Flux", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    public static func makeTempFileURL(prefix: String = "flux", fileExtension: String) -> URL {
        let uuid = UUID().uuidString.prefix(8)
        let filename = "\(prefix)-\(uuid).\(fileExtension)"
        return fluxTempDirectory.appendingPathComponent(filename)
    }
    
    public static func cleanOldTempFiles(olderThanSeconds: TimeInterval = 3600) {
        let dir = fluxTempDirectory
        guard let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.contentModificationDateKey]) else {
            return
        }
        let cutoff = Date().addingTimeInterval(-olderThanSeconds)
        for file in files {
            if let date = (try? file.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate,
               date < cutoff {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }
    
    public static func calculateSHA256(for fileURL: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: fileURL)
        defer { try? handle.close() }
        
        var hasher = SHA256()
        let bufferSize = 64 * 1024 // 64 KB chunks
        
        while autoreleasepool(invoking: {
            let data = handle.readData(ofLength: bufferSize)
            if !data.isEmpty {
                hasher.update(data: data)
                return true
            }
            return false
        }) {}
        
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    public static func calculateSHA256(for data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
