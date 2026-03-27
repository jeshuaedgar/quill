import SwiftUI

struct TagChip: View {
    let tag: Tag

    var body: some View {
        Text("#\(tag.name)")
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.accentColor.opacity(0.1))
            .foregroundStyle(Color.accentColor)
            .clipShape(Capsule())
    }
}
