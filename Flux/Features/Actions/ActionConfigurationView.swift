import SwiftUI

public struct ActionConfigurationView: View {
    @ObservedObject var viewModel: PaletteViewModel
    
    public init(viewModel: PaletteViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            if let action = viewModel.selectedAction, let descriptor = viewModel.selectedDescriptor {
                HStack(spacing: 12) {
                    Image(systemName: action.systemImage)
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(action.title)
                            .font(.system(size: 15, weight: .semibold))
                        
                        Text(descriptor.subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 8)
                
                Divider()
                
                VStack(spacing: 16) {
                    ForEach(descriptor.parameters, id: \.key) { param in
                        parameterRow(param)
                    }
                }
                .padding(.vertical, 8)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Cancel") {
                        viewModel.back()
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.escape, modifiers: [])
                    
                    Spacer()
                    
                    Button("Run Action") {
                        viewModel.confirmActionConfiguration()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return, modifiers: [])
                }
            } else {
                Text("No action selected.")
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
    }
    
    @ViewBuilder
    private func parameterRow(_ param: ActionParameterDescriptor) -> some View {
        HStack {
            Text(param.label)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 140, alignment: .leading)
            
            switch param.type {
            case .string:
                let binding = Binding<String>(
                    get: { viewModel.actionConfiguration.string(for: param.key, default: param.defaultValue) },
                    set: { viewModel.actionConfiguration.set($0, for: param.key) }
                )
                TextField(param.label, text: binding)
                    .textFieldStyle(.roundedBorder)
                
            case .integer(let minVal, let maxVal):
                let binding = Binding<Double>(
                    get: { Double(viewModel.actionConfiguration.int(for: param.key, default: Int(param.defaultValue) ?? minVal)) },
                    set: { viewModel.actionConfiguration.set(Int($0), for: param.key) }
                )
                HStack {
                    Slider(value: binding, in: Double(minVal)...Double(maxVal), step: 50)
                    Text("\(Int(binding.wrappedValue)) px")
                        .font(.system(size: 12, design: .monospaced))
                        .frame(width: 70, alignment: .trailing)
                }
                
            case .double(let minVal, let maxVal, let stepVal):
                let binding = Binding<Double>(
                    get: { viewModel.actionConfiguration.double(for: param.key, default: Double(param.defaultValue) ?? minVal) },
                    set: { viewModel.actionConfiguration.set($0, for: param.key) }
                )
                HStack {
                    Slider(value: binding, in: minVal...maxVal, step: stepVal)
                    Text("\(Int(binding.wrappedValue * 100))%")
                        .font(.system(size: 12, design: .monospaced))
                        .frame(width: 50, alignment: .trailing)
                }
                
            case .boolean:
                let binding = Binding<Bool>(
                    get: { viewModel.actionConfiguration.bool(for: param.key, default: param.defaultValue == "true") },
                    set: { viewModel.actionConfiguration.set($0, for: param.key) }
                )
                Toggle("", isOn: binding)
                    .labelsHidden()
                
            case .selection(let options):
                let binding = Binding<String>(
                    get: { viewModel.actionConfiguration.string(for: param.key, default: param.defaultValue) },
                    set: { viewModel.actionConfiguration.set($0, for: param.key) }
                )
                Picker("", selection: binding) {
                    ForEach(options, id: \.self) { opt in
                        Text(opt).tag(opt)
                    }
                }
                .labelsHidden()
            }
        }
    }
}
