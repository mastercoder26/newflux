import SwiftUI

public struct WorkflowStepView: View {
    let index: Int
    @Binding var step: WorkflowStep
    let onDelete: () -> Void
    
    public init(index: Int, step: Binding<WorkflowStep>, onDelete: @escaping () -> Void) {
        self.index = index
        self._step = step
        self.onDelete = onDelete
    }
    
    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index + 1)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.primary.opacity(0.08)))
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: step.actionKind.systemImage)
                        .font(.system(size: 13))
                        .foregroundColor(.accentColor)
                    
                    Text(step.actionKind.displayName)
                        .font(.system(size: 13, weight: .medium))
                    
                    Spacer()
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                // Show brief parameters summary if any
                if !step.configuration.values.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(step.configuration.values.keys.sorted()), id: \.self) { key in
                            if let val = step.configuration[key] {
                                Text("\(key): \(val)")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}
