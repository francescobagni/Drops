import SwiftUI

struct ProgressIndicator: View {
    var progress: CGFloat
    var color: Color = AppDesign.Colors.accent // ✅ Default to accent color

    var body: some View {
        if progress > 0.0 && progress < 1.0 {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(.ultraThinMaterial) // ✅ Apply `.ultraThinMaterial` as background
                    .frame(height: 4)

                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: color)) // ✅ Apply custom progress color
                    // .padding(.horizontal, 4)
            }
            .frame(width: 100, height: 10) // ✅ Ensure consistent size
        }
    }
}
