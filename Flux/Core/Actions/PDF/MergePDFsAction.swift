import Foundation
import PDFKit

public struct MergePDFsAction: FluxAction {
    public let id: ActionKind = .mergePDFs
    public let title: String = "Merge PDFs"
    public let systemImage: String = "doc.on.doc.fill"
    public let acceptedKinds: Set<ContentKind> = [.multiplePDFs, .multipleFiles]
    
    public init() {}
    
    public func accepts(_ content: FluxContent) -> Bool {
        if case .files(let urls) = content, urls.count >= 2 {
            return urls.allSatisfy { $0.pathExtension.lowercased() == "pdf" }
        }
        return false
    }
    
    public func expectedOutputKind(for inputKind: ContentKind, configuration: ActionConfiguration) -> ContentKind {
        .pdf
    }
    
    public func execute(_ content: FluxContent, configuration: ActionConfiguration) async throws -> FluxContent {
        guard case .files(let urls) = content, urls.count >= 2 else {
            throw ActionError.actionFailed("Merging requires at least two PDF files.")
        }
        
        let mergedDocument = PDFDocument()
        var totalPageIndex = 0
        
        for url in urls {
            guard let doc = PDFDocument(url: url) else {
                throw ActionError.pdfLoadFailed("Could not open PDF file: \(url.lastPathComponent)")
            }
            
            for pageIndex in 0..<doc.pageCount {
                guard let page = doc.page(at: pageIndex) else {
                    continue
                }
                mergedDocument.insert(page, at: totalPageIndex)
                totalPageIndex += 1
            }
        }
        
        guard mergedDocument.pageCount > 0 else {
            throw ActionError.pdfLoadFailed("No valid pages found to merge.")
        }
        
        let tempURL = FileUtilities.makeTempFileURL(prefix: "merged", fileExtension: "pdf")
        guard mergedDocument.write(to: tempURL) else {
            throw ActionError.actionFailed("Failed to save merged PDF file.")
        }
        
        return .pdf(tempURL)
    }
}
