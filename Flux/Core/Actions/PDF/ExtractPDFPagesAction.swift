import Foundation
import PDFKit

public struct ExtractPDFPagesAction: FluxAction {
    public let id: ActionKind = .extractPDFPages
    public let title: String = "Extract Pages"
    public let systemImage: String = "doc.badge.gearshape"
    public let acceptedKinds: Set<ContentKind> = [.pdf]
    
    public init() {}
    
    public func accepts(_ content: FluxContent) -> Bool {
        switch content {
        case .pdf:
            return true
        case .file(let url):
            return url.pathExtension.lowercased() == "pdf"
        default:
            return false
        }
    }
    
    public func expectedOutputKind(for inputKind: ContentKind, configuration: ActionConfiguration) -> ContentKind {
        .pdf
    }
    
    public func execute(_ content: FluxContent, configuration: ActionConfiguration) async throws -> FluxContent {
        let pdfURL: URL
        switch content {
        case .pdf(let url):
            pdfURL = url
        case .file(let url) where url.pathExtension.lowercased() == "pdf":
            pdfURL = url
        default:
            throw ActionError.unsupportedContent
        }
        
        guard let sourceDoc = PDFDocument(url: pdfURL) else {
            throw ActionError.pdfLoadFailed("Unable to open PDF at \(pdfURL.lastPathComponent)")
        }
        
        let totalPages = sourceDoc.pageCount
        guard totalPages > 0 else {
            throw ActionError.pdfLoadFailed("PDF has no pages.")
        }
        
        let expression = configuration.string(for: "pages", default: "1")
        let targetPages = try parsePages(expression: expression, totalPages: totalPages)
        
        let outputDoc = PDFDocument()
        var insertedIndex = 0
        for pageNum in targetPages {
            // pageNum is 1-based
            let zeroIndex = pageNum - 1
            guard let page = sourceDoc.page(at: zeroIndex) else {
                continue
            }
            outputDoc.insert(page, at: insertedIndex)
            insertedIndex += 1
        }
        
        guard outputDoc.pageCount > 0 else {
            throw ActionError.invalidPageRange("No pages could be extracted.")
        }
        
        let tempURL = FileUtilities.makeTempFileURL(prefix: "extracted-pages", fileExtension: "pdf")
        guard outputDoc.write(to: tempURL) else {
            throw ActionError.actionFailed("Failed to save extracted PDF.")
        }
        
        return .pdf(tempURL)
    }
    
    public func parsePages(expression: String, totalPages: Int) throws -> [Int] {
        let trimmed = expression.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ActionError.invalidPageRange("Page expression cannot be empty.")
        }
        
        var selectedPages: [Int] = []
        var seenPages: Set<Int> = []
        
        let tokens = trimmed.components(separatedBy: ",")
        for rawToken in tokens {
            let token = rawToken.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !token.isEmpty else { continue }
            
            if token.contains("-") {
                let rangeParts = token.components(separatedBy: "-")
                guard rangeParts.count == 2,
                      let start = Int(rangeParts[0].trimmingCharacters(in: .whitespaces)),
                      let end = Int(rangeParts[1].trimmingCharacters(in: .whitespaces))
                else {
                    throw ActionError.invalidPageRange("Invalid page range format: '\(token)'.")
                }
                
                guard start > 0 && end > 0 else {
                    throw ActionError.invalidPageRange("Page numbers must be positive: '\(token)'.")
                }
                
                guard start <= end else {
                    throw ActionError.invalidPageRange("Range start (\(start)) must be <= range end (\(end)).")
                }
                
                guard end <= totalPages else {
                    throw ActionError.invalidPageRange("Requested page \(end) exceeds total pages (\(totalPages)).")
                }
                
                for p in start...end {
                    if !seenPages.contains(p) {
                        seenPages.insert(p)
                        selectedPages.append(p)
                    }
                }
            } else {
                guard let single = Int(token) else {
                    throw ActionError.invalidPageRange("Invalid page number: '\(token)'.")
                }
                guard single > 0 else {
                    throw ActionError.invalidPageRange("Page number must be positive: '\(single)'.")
                }
                guard single <= totalPages else {
                    throw ActionError.invalidPageRange("Requested page \(single) exceeds total pages (\(totalPages)).")
                }
                if !seenPages.contains(single) {
                    seenPages.insert(single)
                    selectedPages.append(single)
                }
            }
        }
        
        guard !selectedPages.isEmpty else {
            throw ActionError.invalidPageRange("No valid pages specified.")
        }
        
        return selectedPages
    }
}
