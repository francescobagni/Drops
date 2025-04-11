import SwiftUI

struct FingerLens: View {
    let image: UIImage
    let location: CGPoint
    private let zoom: CGFloat = 6.0
    private let diameter: CGFloat = UIScreen.main.bounds.width / 1.2

    var body: some View {
        GeometryReader { geometry in
            let (fingerX, fingerY, fittedSize) = computeLensLayout(in: geometry.size)

            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: fittedSize.width, height: fittedSize.height)
                    .scaleEffect(zoom, anchor: .topLeading)
                    .offset(
                        x: -fingerX * (zoom - 1),
                        y: -fingerY * (zoom - 1)
                    )
            }
            .frame(width: diameter, height: diameter)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 2))
            .position(x: location.x, y: location.y)
            .shadow(radius: 10)
            .allowsHitTesting(false)
        }
        .zIndex(100)
    }
    
    private func computeLensLayout(in canvasSize: CGSize) -> (relativeX: CGFloat, relativeY: CGFloat, fittedSize: CGSize) {
        let (originX, originY, w, h) = ImageLayoutUtil.fittedRect(
            imageSize: image.size,
            canvasSize: canvasSize
        )
        let fittedSize = CGSize(width: w, height: h)
        
        let fingerX = location.x - originX
        let fingerY = location.y - originY
        
        return (fingerX, fingerY, fittedSize)
    }
    
}
