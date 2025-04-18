import SwiftUI

struct ArcSlider: View {
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>
    let step: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let size = UIScreen.main.bounds.height * 0.5  // ✅ Maintain fixed size

            ZStack {
                // ✅ Background ArcShape remains interactive
                ArcShape()
                    .stroke(.ultraThinMaterial, style: StrokeStyle(lineWidth: 12, lineCap: .round)) // ✅ New material-based background
                    .shadow(color: AppDesign.ShadowStyles.slider.color!, radius: AppDesign.ShadowStyles.slider.radius)

                // ✅ Add thin radial accent lines for steps
                let visualStep: CGFloat = max(step, 0.03)
                let totalSteps = Int((range.upperBound - range.lowerBound) / visualStep)
                ForEach(0...totalSteps, id: \.self) { i in
                    let fraction = CGFloat(i) / CGFloat(totalSteps)
                    let angleDeg = -90.0 + (180.0 * fraction)
                    let angleRad = CGFloat(Angle(degrees: angleDeg).radians)

                    let radius = size / 2
                    let innerRadius = radius - 2.5
                    let outerRadius = radius + 2.5

                    let x1 = radius + innerRadius * cos(angleRad)
                    let y1 = radius + innerRadius * sin(angleRad)
                    let x2 = radius + outerRadius * cos(angleRad)
                    let y2 = radius + outerRadius * sin(angleRad)

                    Path { path in
                        path.move(to: CGPoint(x: x1, y: y1))
                        path.addLine(to: CGPoint(x: x2, y: y2))
                    }
                    .stroke(AppDesign.Colors.accent.opacity(0.7), lineWidth: 1)
                }


                // ✅ Active Value ArcShape
                ArcShape()
                    .trim(from: 0, to: CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)))
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 12, lineCap: .round)) // ✅ Rounded ends
                    .shadow(color: AppDesign.ShadowStyles.slider.color!, radius: AppDesign.ShadowStyles.slider.radius)

                // ✅ Invisible Interaction Layer (Ensures touch detection at full value)
                ArcShape()
                    .stroke(Color.clear, lineWidth: 40) // ✅ Fully transparent but captures touches
                    .contentShape(Rectangle()) // ✅ Ensures tap & drag gestures work
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                let newValue = mapGestureToValue(gesture, in: range, size: size)
                                let stepped = (newValue / step).rounded() * step
                                value = min(max(stepped, range.lowerBound), range.upperBound)
                            }
                    )
            }
            .frame(width: size, height: size)
            .frame(maxHeight: .infinity)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2) // ✅ Ensure centered position
        }
    }

    private func mapGestureToValue(_ gesture: DragGesture.Value, in range: ClosedRange<CGFloat>, size: CGFloat) -> CGFloat {
        let angle = atan2(gesture.location.y - size / 2, gesture.location.x - size / 2)
        let progress = (angle + .pi / 2) / .pi
        return range.lowerBound + (progress * (range.upperBound - range.lowerBound))
    }
}

struct ArcShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                    radius: rect.width / 2,
                    startAngle: Angle(degrees: -90),
                    endAngle: Angle(degrees: 90),
                    clockwise: false)
        return path
    }
}
