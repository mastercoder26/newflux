import Foundation

public final class ActionRegistry: @unchecked Sendable {
    public static let shared: ActionRegistry = {
        let registry = ActionRegistry()
        registry.registerDefaults()
        return registry
    }()
    
    private let lock = NSLock()
    private var actions: [ActionKind: any FluxAction] = [:]
    private var descriptors: [ActionKind: ActionDescriptor] = [:]
    
    public init() {}
    
    public func registerDefaults() {
        // Text Actions
        register(
            CleanWhitespaceAction(),
            descriptor: ActionDescriptor(
                kind: .cleanWhitespace,
                title: "Clean Whitespace",
                subtitle: "Trim lines and normalize spacing",
                systemImage: "wand.and.stars",
                acceptedKinds: [.text, .json]
            )
        )
        
        register(
            RemoveBlankLinesAction(),
            descriptor: ActionDescriptor(
                kind: .removeBlankLines,
                title: "Remove Blank Lines",
                subtitle: "Collapse 3+ empty lines",
                systemImage: "arrow.up.and.down.text.horizontal",
                acceptedKinds: [.text, .json]
            )
        )
        
        register(
            CaseAction(),
            descriptor: ActionDescriptor(
                kind: .convertCase,
                title: "Change Case",
                subtitle: "Convert to uppercase, lowercase, or title case",
                systemImage: "textformat",
                acceptedKinds: [.text],
                parameters: [
                    ActionParameterDescriptor(
                        key: "caseType",
                        label: "Target Case",
                        type: .selection(["Uppercase", "Lowercase", "Title Case"]),
                        defaultValue: "Uppercase"
                    )
                ]
            )
        )
        
        register(
            Base64Action(),
            descriptor: ActionDescriptor(
                kind: .base64Encode,
                title: "Base64 Encode / Decode",
                subtitle: "Encode text to or decode from Base64",
                systemImage: "squaregrid.2x2",
                acceptedKinds: [.text],
                parameters: [
                    ActionParameterDescriptor(
                        key: "mode",
                        label: "Mode",
                        type: .selection(["Encode", "Decode"]),
                        defaultValue: "Encode"
                    )
                ]
            )
        )

        register(
            URLEncodeAction(),
            descriptor: ActionDescriptor(
                kind: .urlEncode,
                title: "URL Encode / Decode",
                subtitle: "Percent-encode or decode URLs and text",
                systemImage: "link.circle",
                acceptedKinds: [.text, .url],
                parameters: [
                    ActionParameterDescriptor(
                        key: "mode",
                        label: "Mode",
                        type: .selection(["Encode", "Decode"]),
                        defaultValue: "Encode"
                    )
                ]
            )
        )

        register(
            SortLinesAction(),
            descriptor: ActionDescriptor(
                kind: .sortLines,
                title: "Sort Lines",
                subtitle: "Sort lines ascending or descending",
                systemImage: "text.line.first.and.arrowtriangle.forward",
                acceptedKinds: [.text],
                parameters: [
                    ActionParameterDescriptor(
                        key: "order",
                        label: "Order",
                        type: .selection(["Ascending", "Descending"]),
                        defaultValue: "Ascending"
                    ),
                    ActionParameterDescriptor(
                        key: "trim",
                        label: "Trim Each Line",
                        type: .boolean,
                        defaultValue: "false"
                    )
                ]
            )
        )

        register(
            ReverseTextAction(),
            descriptor: ActionDescriptor(
                kind: .reverseText,
                title: "Reverse Text",
                subtitle: "Reverse characters or line-by-line",
                systemImage: "arrow.left.arrow.right",
                acceptedKinds: [.text],
                parameters: [
                    ActionParameterDescriptor(
                        key: "byLine",
                        label: "Reverse Per Line",
                        type: .boolean,
                        defaultValue: "false"
                    )
                ]
            )
        )

        register(
            SlugifyAction(),
            descriptor: ActionDescriptor(
                kind: .slugify,
                title: "Slugify",
                subtitle: "Convert text to a URL-safe slug",
                systemImage: "number",
                acceptedKinds: [.text],
                parameters: [
                    ActionParameterDescriptor(
                        key: "separator",
                        label: "Separator",
                        type: .string,
                        defaultValue: "-"
                    )
                ]
            )
        )

        // JSON Actions
        register(
            PrettyJSONAction(),
            descriptor: ActionDescriptor(
                kind: .prettyJSON,
                title: "Format JSON",
                subtitle: "Format and indent JSON data",
                systemImage: "curlybraces",
                acceptedKinds: [.json, .text]
            )
        )
        
        register(
            MinifyJSONAction(),
            descriptor: ActionDescriptor(
                kind: .minifyJSON,
                title: "Minify JSON",
                subtitle: "Remove spaces and compact JSON",
                systemImage: "arrow.right.arrow.left",
                acceptedKinds: [.json, .text]
            )
        )
        
        // URL Actions
        register(
            CleanURLAction(),
            descriptor: ActionDescriptor(
                kind: .cleanURL,
                title: "Clean URL",
                subtitle: "Remove tracking and marketing parameters",
                systemImage: "link.badge.plus",
                acceptedKinds: [.url]
            )
        )
        
        register(
            GenerateQRCodeAction(),
            descriptor: ActionDescriptor(
                kind: .generateQRCode,
                title: "Generate QR Code",
                subtitle: "Create sharp QR code image",
                systemImage: "qrcode",
                acceptedKinds: [.url, .text]
            )
        )
        
        register(
            MarkdownURLAction(),
            descriptor: ActionDescriptor(
                kind: .markdownURL,
                title: "Markdown Link",
                subtitle: "Format as [domain](url)",
                systemImage: "link",
                acceptedKinds: [.url]
            )
        )
        
        // Image Actions
        register(
            ResizeImageAction(),
            descriptor: ActionDescriptor(
                kind: .resizeImage,
                title: "Resize Image",
                subtitle: "Scale image dimensions",
                systemImage: "aspectratio",
                acceptedKinds: [.image],
                parameters: [
                    ActionParameterDescriptor(
                        key: "width",
                        label: "Width (px)",
                        type: .integer(min: 50, max: 8000),
                        defaultValue: "1200"
                    ),
                    ActionParameterDescriptor(
                        key: "preserveAspectRatio",
                        label: "Preserve Aspect Ratio",
                        type: .boolean,
                        defaultValue: "true"
                    )
                ]
            )
        )
        
        register(
            ConvertToPNGAction(),
            descriptor: ActionDescriptor(
                kind: .convertToPNG,
                title: "Convert to PNG",
                subtitle: "Lossless PNG format",
                systemImage: "photo",
                acceptedKinds: [.image]
            )
        )
        
        register(
            ConvertToJPEGAction(),
            descriptor: ActionDescriptor(
                kind: .convertToJPEG,
                title: "Convert to JPEG",
                subtitle: "Standard JPEG output",
                systemImage: "photo.fill",
                acceptedKinds: [.image],
                parameters: [
                    ActionParameterDescriptor(
                        key: "quality",
                        label: "Quality",
                        type: .double(min: 0.1, max: 1.0, step: 0.05),
                        defaultValue: "0.85"
                    )
                ]
            )
        )
        
        register(
            CompressJPEGAction(),
            descriptor: ActionDescriptor(
                kind: .compressJPEG,
                title: "Compress JPEG",
                subtitle: "Reduce file size with configurable quality",
                systemImage: "arrow.down.right.and.arrow.up.left",
                acceptedKinds: [.image],
                parameters: [
                    ActionParameterDescriptor(
                        key: "quality",
                        label: "Quality",
                        type: .double(min: 0.1, max: 1.0, step: 0.05),
                        defaultValue: "0.75"
                    )
                ]
            )
        )
        
        register(
            OCRAction(),
            descriptor: ActionDescriptor(
                kind: .ocr,
                title: "Extract Text (OCR)",
                subtitle: "Recognize text in image using Apple Vision",
                systemImage: "text.viewfinder",
                acceptedKinds: [.image]
            )
        )
        
        // PDF Actions
        register(
            MergePDFsAction(),
            descriptor: ActionDescriptor(
                kind: .mergePDFs,
                title: "Merge PDFs",
                subtitle: "Combine multiple PDF documents into one",
                systemImage: "doc.on.doc.fill",
                acceptedKinds: [.multiplePDFs, .multipleFiles]
            )
        )
        
        register(
            ExtractPDFPagesAction(),
            descriptor: ActionDescriptor(
                kind: .extractPDFPages,
                title: "Extract Pages",
                subtitle: "Extract page range (e.g. 1-3, 5)",
                systemImage: "doc.badge.gearshape",
                acceptedKinds: [.pdf],
                parameters: [
                    ActionParameterDescriptor(
                        key: "pages",
                        label: "Pages (e.g. 1-3, 5)",
                        type: .string,
                        defaultValue: "1"
                    )
                ]
            )
        )
        
        // File Actions
        register(
            CalculateHashAction(),
            descriptor: ActionDescriptor(
                kind: .calculateHash,
                title: "Calculate SHA-256",
                subtitle: "Compute cryptographic checksum",
                systemImage: "number",
                acceptedKinds: [.file, .image, .pdf, .text, .json]
            )
        )
    }
    
    public func register(_ action: any FluxAction, descriptor: ActionDescriptor? = nil) {
        lock.lock()
        defer { lock.unlock() }
        actions[action.id] = action
        if let descriptor = descriptor {
            descriptors[action.id] = descriptor
        }
    }
    
    public func action(for kind: ActionKind) -> (any FluxAction)? {
        lock.lock()
        defer { lock.unlock() }
        return actions[kind]
    }
    
    public func descriptor(for kind: ActionKind) -> ActionDescriptor? {
        lock.lock()
        defer { lock.unlock() }
        return descriptors[kind]
    }
    
    public func compatibleActions(for content: FluxContent) -> [any FluxAction] {
        lock.lock()
        let all = Array(actions.values)
        lock.unlock()
        
        return all
            .filter { $0.accepts(content) }
            .sorted { $0.id.displayName < $1.id.displayName }
    }
    
    public func compatibleActions(for kind: ContentKind) -> [any FluxAction] {
        lock.lock()
        let all = Array(actions.values)
        lock.unlock()
        
        return all
            .filter { $0.acceptedKinds.contains(kind) }
            .sorted { $0.id.displayName < $1.id.displayName }
    }
    
    public func allActions() -> [any FluxAction] {
        lock.lock()
        defer { lock.unlock() }
        return Array(actions.values).sorted { $0.id.displayName < $1.id.displayName }
    }
}
