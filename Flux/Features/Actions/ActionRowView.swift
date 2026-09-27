import SwiftUI

public struct ActionRowView: View {
    let action: any FluxAction
    let descriptor: ActionDescriptor?
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    public init(action: any FluxAction, descriptor: ActionDescriptor?, onSelect: @escaping () -> Void) {
        self.action = action
        self.descriptor = descriptor
        self.onSelect = onSelect
    }
    
    public var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: action.systemImage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isHovered ? .accentColor : .primary)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(action.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                    
                    if let subtitle = descriptor?.subtitle {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if descriptor?.hasConfiguration == true {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color(nsColor: .selectedContentBackgroundColor).opacity(0.15) : Color(nsColor: .controlBackgroundColor).opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isHovered ? Color.accentColor.opacity(0.3) : Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
