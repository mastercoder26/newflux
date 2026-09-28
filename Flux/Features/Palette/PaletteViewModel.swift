import Foundation
import SwiftUI
import AppKit
import UniformTypeIdentifiers

public enum PaletteMode: Equatable {
    case empty
    case content
    case configuring(ActionKind)
    case processing
    case result
    case workflowBuilder
    case history
}

@MainActor
public final class PaletteViewModel: ObservableObject {
    @Published public var mode: PaletteMode = .empty
    @Published public var content: FluxContent?
    @Published public var metadata: ContentMetadata?
    @Published public var compatibleActions: [any FluxAction] = []
    
    @Published public var selectedAction: (any FluxAction)?
    @Published public var actionConfiguration: ActionConfiguration = ActionConfiguration()
    @Published public var selectedDescriptor: ActionDescriptor?
    
    @Published public var isProcessing: Bool = false
    @Published public var workflowProgress: WorkflowProgress?
    @Published public var runningWorkflowName: String?
    
    @Published public var resultContent: FluxContent?
    @Published public var resultMetadata: ContentMetadata?
    @Published public var initialFileSize: Int64?
    @Published public var resultFileSize: Int64?
    @Published public var lastExportedURL: URL?
    
    @Published public var errorMessage: String?
    @Published public var manualTextInput: String = ""
    @Published public var isTargetedForDrop: Bool = false
    
    @Published public var savedWorkflows: [Workflow] = []
    @Published public var historyEntries: [HistoryEntry] = []
    
    private let registry = ActionRegistry.shared
    private let workflowStore = WorkflowStore.shared
    private let historyStore = HistoryStore.shared
    private let clipboardService = ClipboardService.shared
    private let detector = ContentDetector()
    
    public init() {
        refreshWorkflows()
        refreshHistory()
    }
    
    public func refreshWorkflows() {
        savedWorkflows = workflowStore.all()
    }
    
    public func refreshHistory() {
        historyEntries = historyStore.all()
    }
    
    public func loadContent(_ result: ContentDetectionResult) {
        self.content = result.content
        self.metadata = result.metadata
        self.initialFileSize = result.metadata.fileSize
        self.compatibleActions = registry.compatibleActions(for: result.content)
        self.errorMessage = nil
        self.resultContent = nil
        self.resultMetadata = nil
        self.mode = .content
    }
    
    public func pasteClipboard() {
        if let result = clipboardService.readContent() {
            loadContent(result)
        } else {
            errorMessage = "No compatible content found in clipboard."
        }
    }
    
    public func submitManualText() {
        let trimmed = manualTextInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let result = detector.detect(text: manualTextInput)
        manualTextInput = ""
        loadContent(result)
    }
    
    public func handleFileDrop(urls: [URL]) {
        guard !urls.isEmpty else { return }
        let result = detector.detect(urls: urls)
        loadContent(result)
    }
    
    public func handleDrop(providers: [NSItemProvider]) -> Bool {
        var foundURLs: [URL] = []
        let group = DispatchGroup()
        
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    defer { group.leave() }
                    if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        foundURLs.append(url)
                    } else if let url = item as? URL {
                        foundURLs.append(url)
                    }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                    defer { group.leave() }
                    if let string = item as? String {
                        Task { @MainActor in
                            self.loadContent(ContentDetector().detect(text: string))
                        }
                    }
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            if !foundURLs.isEmpty {
                self?.handleFileDrop(urls: foundURLs)
            }
        }
        return true
    }
    
    public func selectAction(_ action: any FluxAction) {
        guard content != nil else { return }
        guard !isProcessing else { return }
        
        self.selectedAction = action
        if let desc = registry.descriptor(for: action.id), desc.hasConfiguration {
            self.selectedDescriptor = desc
            self.actionConfiguration = desc.defaultConfiguration()
            self.mode = .configuring(action.id)
        } else {
            self.actionConfiguration = ActionConfiguration()
            executeAction(action, configuration: actionConfiguration)
        }
    }
    
    public func confirmActionConfiguration() {
        guard let action = selectedAction else { return }
        executeAction(action, configuration: actionConfiguration)
    }
    
    public func executeAction(_ action: any FluxAction, configuration: ActionConfiguration) {
        guard let inputContent = content, let inputMetadata = metadata else { return }
        guard !isProcessing else { return }
        
        isProcessing = true
        mode = .processing
        errorMessage = nil
        workflowProgress = WorkflowProgress(stepIndex: 0, totalSteps: 1, actionTitle: action.title, status: .running)
        
        Task {
            do {
                let output = try await action.execute(inputContent, configuration: configuration)
                let outputResult = self.detectorResult(for: output)
                
                let outSize: Int64?
                if let singleURL = output.singleFileURL {
                    outSize = (try? FileManager.default.attributesOfItem(atPath: singleURL.path)[.size] as? NSNumber)?.int64Value
                } else if case .text(let str) = output {
                    outSize = Int64(str.utf8.count)
                } else {
                    outSize = outputResult.metadata.fileSize
                }
                
                let summary: String
                switch output {
                case .text(let str):
                    let preview = str.trimmingCharacters(in: .whitespacesAndNewlines)
                    summary = preview.count > 50 ? String(preview.prefix(47)) + "..." : preview
                case .url(let u):
                    summary = u.absoluteString
                case .image(let img, _):
                    summary = "\(Int(img.size.width)) × \(Int(img.size.height)) px"
                case .pdf(let u), .file(let u):
                    summary = u.lastPathComponent
                case .files(let urls):
                    summary = "\(urls.count) files"
                }
                
                let historyEntry = HistoryEntry(
                    inputKind: inputMetadata.kind,
                    actionName: action.title,
                    workflowName: nil,
                    outputKind: outputResult.metadata.kind,
                    summary: summary
                )
                self.historyStore.add(historyEntry)
                self.refreshHistory()
                
                self.resultContent = output
                self.resultMetadata = outputResult.metadata
                self.resultFileSize = outSize
                self.isProcessing = false
                self.workflowProgress = WorkflowProgress(stepIndex: 0, totalSteps: 1, actionTitle: action.title, status: .completed)
                self.mode = .result
            } catch {
                self.isProcessing = false
                self.errorMessage = error.localizedDescription
                self.workflowProgress = WorkflowProgress(stepIndex: 0, totalSteps: 1, actionTitle: action.title, status: .failed(error.localizedDescription))
                self.mode = .content
            }
        }
    }
    
    public func runWorkflow(_ workflow: Workflow) {
        guard let inputContent = content, let inputMetadata = metadata else { return }
        guard !isProcessing else { return }
        
        let validator = WorkflowValidator(registry: registry)
        let validation = validator.validate(workflow: workflow, for: inputMetadata.kind)
        guard validation.isValid else {
            self.errorMessage = validation.errorMessage ?? "Incompatible workflow."
            return
        }
        
        self.isProcessing = true
        self.runningWorkflowName = workflow.name
        self.mode = .processing
        self.errorMessage = nil
        
        let runner = WorkflowRunner(registry: registry)
        Task {
            do {
                let output = try await runner.run(workflow: workflow, initialContent: inputContent) { progress in
                    Task { @MainActor in
                        self.workflowProgress = progress
                    }
                }
                
                let outputResult = self.detectorResult(for: output)
                let outSize: Int64?
                if let singleURL = output.singleFileURL {
                    outSize = (try? FileManager.default.attributesOfItem(atPath: singleURL.path)[.size] as? NSNumber)?.int64Value
                } else if case .text(let str) = output {
                    outSize = Int64(str.utf8.count)
                } else {
                    outSize = outputResult.metadata.fileSize
                }
                
                let summary: String
                switch output {
                case .text(let str):
                    let preview = str.trimmingCharacters(in: .whitespacesAndNewlines)
                    summary = preview.count > 50 ? String(preview.prefix(47)) + "..." : preview
                case .url(let u):
                    summary = u.absoluteString
                case .image(let img, _):
                    summary = "\(Int(img.size.width)) × \(Int(img.size.height)) px"
                case .pdf(let u), .file(let u):
                    summary = u.lastPathComponent
                case .files(let urls):
                    summary = "\(urls.count) files"
                }
                
                let historyEntry = HistoryEntry(
                    inputKind: inputMetadata.kind,
                    actionName: workflow.name,
                    workflowName: workflow.name,
                    outputKind: outputResult.metadata.kind,
                    summary: summary
                )
                self.historyStore.add(historyEntry)
                self.refreshHistory()
                
                self.resultContent = output
                self.resultMetadata = outputResult.metadata
                self.resultFileSize = outSize
                self.isProcessing = false
                self.mode = .result
            } catch {
                self.isProcessing = false
                self.errorMessage = error.localizedDescription
                self.mode = .content
            }
        }
    }
    
    public func copyResult() {
        guard let result = resultContent else { return }
        _ = clipboardService.copy(content: result)
    }
    
    public func exportResult(window: NSWindow? = nil) {
        guard let result = resultContent else { return }
        
        var suggested: String? = nil
        if let singleURL = result.singleFileURL {
            suggested = singleURL.lastPathComponent
        } else if case .text = result {
            suggested = "output.txt"
        } else if case .url = result {
            suggested = "link.txt"
        }
        
        Task {
            do {
                let savedURL = try await ExportService.shared.export(content: result, suggestedName: suggested, from: window)
                self.lastExportedURL = savedURL
            } catch {
                if let actionErr = error as? ActionError, case .exportFailed = actionErr {
                    // Cancelled, do nothing
                } else {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    public func revealLastExportedInFinder() {
        if let url = lastExportedURL {
            ExportService.shared.revealInFinder(url: url)
        } else if let url = resultContent?.singleFileURL {
            ExportService.shared.revealInFinder(url: url)
        }
    }
    
    public func continueWithResult() {
        guard let result = resultContent else { return }
        let res = detectorResult(for: result)
        loadContent(res)
    }
    
    public func resetToEmpty() {
        mode = .empty
        content = nil
        metadata = nil
        selectedAction = nil
        selectedDescriptor = nil
        resultContent = nil
        resultMetadata = nil
        initialFileSize = nil
        resultFileSize = nil
        lastExportedURL = nil
        errorMessage = nil
        workflowProgress = nil
        runningWorkflowName = nil
    }
    
    public func back() {
        switch mode {
        case .configuring:
            mode = .content
        case .processing:
            if !isProcessing {
                mode = .content
            }
        case .result:
            mode = .content
        case .workflowBuilder, .history:
            mode = content != nil ? .content : .empty
        default:
            resetToEmpty()
        }
    }
    
    public func clearHistory() {
        historyStore.clear()
        refreshHistory()
    }
    
    private func detectorResult(for content: FluxContent) -> ContentDetectionResult {
        switch content {
        case .text(let str):
            return detector.detect(text: str)
        case .url(let u):
            return detector.detect(url: u)
        case .image(let img, let src):
            let details: [String: String] = ["dimensions": "\(Int(img.size.width)) × \(Int(img.size.height))"]
            let sz = src.flatMap { (try? FileManager.default.attributesOfItem(atPath: $0.path)[.size] as? NSNumber)?.int64Value }
            let metadata = ContentMetadata(
                kind: .image,
                displayName: src?.lastPathComponent ?? "Image",
                fileSize: sz,
                utiIdentifier: "public.image",
                details: details
            )
            return ContentDetectionResult(content: content, metadata: metadata)
        case .pdf(let u):
            return detector.detect(fileURL: u)
        case .file(let u):
            return detector.detect(fileURL: u)
        case .files(let urls):
            return detector.detect(urls: urls)
        }
    }
}
