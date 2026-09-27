import SwiftUI

public struct WorkflowProgressView: View {
    @ObservedObject var viewModel: PaletteViewModel
    
    public init(viewModel: PaletteViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text(viewModel.runningWorkflowName.map { "Running \($0)" } ?? "Processing...")
                    .font(.system(size: 15, weight: .semibold))
                
                Spacer()
                
                if viewModel.isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.bottom, 4)
            
            Divider()
            
            if let progress = viewModel.workflowProgress {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        statusIcon(for: progress.status)
                            .font(.system(size: 16))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(progress.actionTitle)
                                .font(.system(size: 14, weight: .medium))
                            
                            Text("Step \(progress.stepNumber) of \(progress.totalSteps)")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                    )
                }
            }
            
            if let error = viewModel.errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.octagon.fill")
                            .foregroundColor(.red)
                        Text("Execution Failed")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.red)
                    }
                    
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.08))
                )
            }
            
            Spacer()
            
            if !viewModel.isProcessing {
                HStack {
                    Button("Back") {
                        viewModel.back()
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                }
            }
        }
        .padding(20)
    }
    
    @ViewBuilder
    private func statusIcon(for status: WorkflowStepStatus) -> some View {
        switch status {
        case .pending:
            Image(systemName: "circle")
                .foregroundColor(.secondary)
        case .running:
            Image(systemName: "circle.dotted")
                .foregroundColor(.accentColor)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
        }
    }
}
