// ArcProgressInImage.swift
import SwiftUI

struct ArcProgressInImage: View {
    let progress: CGFloat       // 0.0 → 1.0
    let lineWidth: CGFloat
    let accentColor: Color
   // let neutralB = Color(hex: "#413E3E").opacity(0.45)
    
    // The displayed image's bounding rectangle (in parent coordinate space).
    // If nil or zero-sized, we fallback to a generic center position.
    let boundingRect: CGRect?

    var body: some View {
        GeometryReader { geo in
            if let rect = boundingRect, rect.width > 0, rect.height > 0 {
                // 1) The “valid rect” code
                let diameter = rect.height * 5.75
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
                    let bottomRightX = rect.origin.x + rect.width - 48
                    let bottomRightY = rect.origin.y + rect.height - 48

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
                        .position(
                            x: rect.origin.x + rect.width - 36,
                            y: rect.origin.y + rect.height - 36
                        )
                    */
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.35))
                            .frame(width: 54, height: 54)
                            .blur(radius: 6)

                        Text("\(Int(progress * 100))%")
                            .font(.title2)
                            .fontWeight(.regular)
                            .foregroundColor(accentColor.opacity(1.0))
                            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 1)
                    }
                    .position(
                        x: rect.origin.x + rect.width - 36,
                        y: rect.origin.y + rect.height - 36
                    )

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
