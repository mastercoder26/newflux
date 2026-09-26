import Foundation

public enum ActionKind: String, Codable, CaseIterable, Identifiable, Sendable {
    // Text
    case cleanWhitespace
    case removeBlankLines
    case convertCase
    case base64Encode
    case urlEncode
    
    // JSON
    case prettyJSON
    case minifyJSON
    
    // URL
    case cleanURL
    case generateQRCode
    case markdownURL
    
    // Image
    case resizeImage
    case convertToPNG
    case convertToJPEG
    case compressJPEG
    case ocr
    
    // PDF
    case mergePDFs
    case extractPDFPages
    
    // File
    case calculateHash
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .cleanWhitespace: return "Clean Whitespace"
        case .removeBlankLines: return "Remove Blank Lines"
        case .convertCase: return "Change Case"
        case .base64Encode: return "Base64 Encode / Decode"
        case .urlEncode: return "URL Encode / Decode"
        case .prettyJSON: return "Format JSON"
        case .minifyJSON: return "Minify JSON"
        case .cleanURL: return "Clean URL"
        case .generateQRCode: return "Generate QR Code"
        case .markdownURL: return "Markdown Link"
        case .resizeImage: return "Resize Image"
        case .convertToPNG: return "Convert to PNG"
        case .convertToJPEG: return "Convert to JPEG"
        case .compressJPEG: return "Compress JPEG"
        case .ocr: return "Extract Text (OCR)"
        case .mergePDFs: return "Merge PDFs"
        case .extractPDFPages: return "Extract Pages"
        case .calculateHash: return "Calculate SHA-256"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .cleanWhitespace: return "wand.and.stars"
        case .removeBlankLines: return "arrow.up.and.down.text.horizontal"
        case .convertCase: return "textformat"
        case .base64Encode: return "squaregrid.2x2"
        case .urlEncode: return "link.circle"
        case .prettyJSON: return "curlybraces"
        case .minifyJSON: return "arrow.right.arrow.left"
        case .cleanURL: return "link.badge.plus"
        case .generateQRCode: return "qrcode"
        case .markdownURL: return "link"
        case .resizeImage: return "aspectratio"
        case .convertToPNG: return "photo"
        case .convertToJPEG: return "photo.fill"
        case .compressJPEG: return "arrow.down.right.and.arrow.up.left"
        case .ocr: return "text.viewfinder"
        case .mergePDFs: return "doc.on.doc.fill"
        case .extractPDFPages: return "doc.badge.gearshape"
        case .calculateHash: return "number"
        }
    }
}
