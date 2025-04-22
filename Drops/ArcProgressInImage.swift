import SwiftUI

struct ArcProgressInImage: View {
    let progress: CGFloat       // 0.0 → 1.0
    let lineWidth: CGFloat
    let accentColor: Color
    let neutral = Color(hex: "#000000") // Black
   // let neutralB = Color(hex: "#413E3E").opacity(0.45)
    
    // The displayed image's bounding rectangle (in parent coordinate space).
    // If nil or zero-sized, we fallback to a generic center position.
    let boundingRect: CGRect?
    
    private func topPadding(for rect: CGRect) -> CGFloat {
        let aspectRatio = rect.width / rect.height
        switch aspectRatio {
        case 1.7...1.9: return 144  // landscape 16:9
        case 1.3...1.6: return 114  // landscape 4:3 tested
        case 0.9...1.1: return 144  // square tested
        case 0.7...0.89: return 94 // portrait 4:3 tested
        case 0.5...0.69: return 84 // portrait 16:9 tested
        default: return 94
        }
    }

    var body: some View {
        GeometryReader { geo in
            if let rect = boundingRect, rect.width > 0, rect.height > 0 {
                // 1) The “valid rect” code
                let diameter = rect.height * 4.75
                let radius   = diameter / 2.0

                let topEdgeY = rect.origin.y
                let centerY  = rect.origin.y //topEdgeY //+ radius

                let minX    = (rect.minX)+(rect.maxX/3.75)
                let maxX    = rect.maxX
                let clamped = min(max(progress, 0.0), 1.0)
                // 4) Desired right edge = minX + clamped * (maxX - minX)
                //    so circle center = that right edge - radius
                let rightEdgeX = minX + clamped * (maxX - minX)
                let centerX    = rightEdgeX - radius

                let topPadding = topPadding(for: rect)

                let bottomRightX = rect.origin.x + rect.width - 48
                let bottomRightY = rect.origin.y + rect.height - 48

                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .stroke(accentColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                        .frame(width: diameter, height: diameter)

                    Circle()
                        .trim(from: 0.0, to: progress)
                        .stroke(accentColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                        .frame(width: diameter, height: diameter)
                        .rotationEffect(.degrees(180))

                    /*
                    Text("\(Int(progress * 100))%")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(accentColor.opacity(0.75))
                        .position(x: bottomRightX, y: bottomRightY)
                        .zIndex(10)
                    */

                    Rectangle()
                        .stroke(Color.red, lineWidth: 2)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                }
                .position(x: centerX, y: centerY)
                .clipShape(
                 Rectangle().path(in: rect)
                )

                    /*
                    Text("\(Int(progress * 100))%")
                        .font(.title2)
                        .fontWeight(.regular)
                        .foregroundColor(accentColor.opacity(1.0))
                        .shadow(color: .black.opacity(1.00), radius: 12, x: 0, y: 0)
                    */
                GeometryReader { innerGeo in
                    ZStack(alignment: .topLeading) {
                        HStack(spacing: 0) {
                           // Text("\(Int(progress * 100) / 100)") // hundreds digit
                             //   .frame(width: 24, alignment: .trailing)

                            Text("\(Int(progress * 100) / 10 % 10)") // tens digit
                                .frame(width: 26, alignment: .trailing)
                                .font(.system(size: 48, weight: .thin, design: .rounded))

                            Text("\(Int(progress * 100) % 10)") // units digit
                                .frame(width: 26, alignment: .trailing)
                                .font(.system(size: 48, weight: .thin, design: .rounded))

                            Text("%")
                                .frame(width: 26, alignment: .trailing)
                                .baselineOffset(12)
                                .font(.system(size: 28, weight: .thin, design: .rounded))
                        }
                       // .font(.system(size: 48, weight: .thin, design: .rounded))
                        .foregroundColor(.white.opacity(1.0))
                        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 0)
                        .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 6)
                        .shadow(color: .black.opacity(0.25), radius: 32, x: 0, y: 6)
                        .fixedSize()
                        .padding(.top, topPadding)
                        .padding(.leading, 20)
                    }
                    .frame(width: innerGeo.size.width, height: innerGeo.size.height, alignment: .topLeading)
                }
                .frame(width: rect.width, height: rect.height)
               // .position(x: rect.midX, y: rect.midY)

            } else {
                // 2) The “fallback” code for when boundingRect is nil/invalid
                let fallbackDiameter = min(geo.size.width, geo.size.height) * 0.3
                let fallbackRadius   = fallbackDiameter / 2

                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: fallbackDiameter, height: fallbackDiameter)

                    Circle()
                        .trim(from: 0.0, to: progress)
                        .stroke(accentColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                        .frame(width: fallbackDiameter, height: fallbackDiameter)
                        .rotationEffect(.degrees(180))

                    Text("\(Int(progress * 100))%")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(accentColor)
                        .offset(x: fallbackRadius * 0.4)
                }
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                .clipShape(Rectangle().path(in: CGRect(origin: .zero, size: geo.size)))
            }
        }
    }
    
}
