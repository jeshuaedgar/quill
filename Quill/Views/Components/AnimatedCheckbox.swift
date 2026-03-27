import SwiftUI

struct AnimatedCheckbox: View {
    let isChecked: Bool
    let priority: Priority
    let onToggle: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 0.8
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.2
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.0
                }
            }
            
            if !isChecked {
                HapticManager.shared.success()
            } else {
                HapticManager.shared.lightImpact()
            }
            
            onToggle()
            
        } label: {
            ZStack {
                Circle()
                    .stroke(
                        isChecked ? Color.green : priorityColor,
                        lineWidth: 2
                    )
                    .frame(width: 28, height: 28)
                
                if isChecked {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 28, height: 28)
                        .transition(.scale.combined(with: .opacity))
                    
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .scaleEffect(scale)
        }
        .buttonStyle(.plain)
    }
    
    private var priorityColor: Color {
        switch priority {
        case .none: return Color(.systemGray3)
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        AnimatedCheckbox(isChecked: false, priority: .none, onToggle: {})
        AnimatedCheckbox(isChecked: true, priority: .none, onToggle: {})
        AnimatedCheckbox(isChecked: false, priority: .urgent, onToggle: {})
    }
    .padding()
}
