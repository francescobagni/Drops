import UIKit
import SwiftUI

extension UIImage {
    func normalized() -> UIImage {
        if imageOrientation == .up {
            return self
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = self.scale
        let renderer = UIGraphicsImageRenderer(size: self.size, format: format)

        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: self.size))
        }
    }
    
    func resized(to maxSize: CGFloat) -> UIImage? {
            let aspectRatio = size.width / size.height
            let newWidth = min(size.width, maxSize)
            let newHeight = newWidth / aspectRatio

            print("🟡 DEBUG: Resizing image from \(size.width)x\(size.height) to \(newWidth)x\(newHeight) (maxSize: \(maxSize))")

            let newSize = CGSize(width: newWidth, height: newHeight)
            UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
            draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return resizedImage
        }
    
    func addBackground(color: Color) -> UIImage {
            let size = self.size
            UIGraphicsBeginImageContextWithOptions(size, false, self.scale)
            let context = UIGraphicsGetCurrentContext()

            // Convert SwiftUI Color to UIColor
            let uiColor = UIColor(color)
            uiColor.setFill()
            context?.fill(CGRect(origin: .zero, size: size))

            // Draw the processed image on top
            self.draw(in: CGRect(origin: .zero, size: size))

            let finalImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return finalImage ?? self
        }
    
    func withPrintFrame(
            top: CGFloat,
            left: CGFloat,
            right: CGFloat,
            bottom: CGFloat,
            backgroundColor: UIColor
        ) -> UIImage {
            let newSize = CGSize(
                width: self.size.width + left + right,
                height: self.size.height + top + bottom
            )

            UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
            guard let context = UIGraphicsGetCurrentContext() else {
                return self
            }

            // Fill the background
            context.setFillColor(backgroundColor.cgColor)
            context.fill(CGRect(origin: .zero, size: newSize))

            // Draw the original image offset by (left, top)
            self.draw(in: CGRect(
                x: left,
                y: top,
                width: self.size.width,
                height: self.size.height
            ))

            let result = UIGraphicsGetImageFromCurrentImageContext() ?? self
            UIGraphicsEndImageContext()
            return result
        }
    
    
}

struct ImageLayoutUtil {
    /// Calculates how an image of `imageSize` fits into
    /// a container of `canvasSize` while preserving aspect ratio.
    ///
    /// - Returns: (originX, originY, fittedWidth, fittedHeight)
    static func fittedRect(
        imageSize: CGSize,
        canvasSize: CGSize
    ) -> (originX: CGFloat, originY: CGFloat, fittedWidth: CGFloat, fittedHeight: CGFloat) {
        
        let imageAspect = imageSize.width / imageSize.height
        let canvasAspect = canvasSize.width / canvasSize.height
        
        let fittedWidth: CGFloat
        let fittedHeight: CGFloat
        
        if imageAspect > canvasAspect {
            // Image is relatively wider than container
            fittedWidth = canvasSize.width
            fittedHeight = fittedWidth / imageAspect
        } else {
            // Image is taller (or same aspect)
            fittedHeight = canvasSize.height
            fittedWidth = fittedHeight * imageAspect
        }
        
        let originX = (canvasSize.width - fittedWidth) / 2
        let originY = (canvasSize.height - fittedHeight) / 2
        
        return (originX, originY, fittedWidth, fittedHeight)
    }
}

//MARK: - Placeholder View for First time User

struct PlaceholderProcessingView: View {
    @Binding var progress: Double
    let imageSize: CGSize

    var body: some View {
        GeometryReader { geo in
            let (originX, originY, fittedWidth, fittedHeight) = ImageLayoutUtil.fittedRect(
                imageSize: imageSize,
                canvasSize: geo.size
            )
            let xPos = (geo.size.width - fittedWidth) / 2
            let yPos = (geo.size.height - fittedHeight) / 2

            let displayedRect = CGRect(
                x: originX,
                y: originY,
                width: fittedWidth,
                height: fittedHeight
            )

            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .frame(width: fittedWidth, height: fittedHeight)
                    .position(x: xPos + fittedWidth / 2, y: yPos + fittedHeight / 2)

                if progress > 0.0 && progress < 1.0 {
                    ArcProgressInImage(
                        progress: CGFloat(progress),
                        lineWidth: 3.0,
                        accentColor: .white,
                        boundingRect: displayedRect
                    )
                    .allowsHitTesting(false)
                }
            }
        }
    }
}

//MARK: - Raw Image View for First time User

struct RawImageView: View {
    let rawImage: UIImage
    @Binding var progress: Double // So we can still show the progress arc
    let isProcessing: Bool        // So we know if we should display the arc

    var body: some View {
        GeometryReader { geo in
            // Fit the user’s raw image to the available geometry
            let (originX, originY, fittedWidth, fittedHeight) = ImageLayoutUtil.fittedRect(
                imageSize: rawImage.size,
                canvasSize: geo.size
            )

            let xPos = (geo.size.width - fittedWidth) / 2
            let yPos = (geo.size.height - fittedHeight) / 2

            let displayedRect = CGRect(
                x: originX,
                y: originY,
                width: fittedWidth,
                height: fittedHeight
            )

            ZStack {
                // Show the raw user-selected image
                Image(uiImage: rawImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: fittedWidth, height: fittedHeight)
                    .position(x: xPos + fittedWidth / 2, y: yPos + fittedHeight / 2)

                // If still processing, show the arc-based progress
                if isProcessing && progress > 0.0 && progress < 1.0 {
                    ArcProgressInImage(
                        progress: CGFloat(progress),
                        lineWidth: 3.0,
                        accentColor: .white,
                        boundingRect: displayedRect
                    )
                    .allowsHitTesting(false)
                }
            }
        }
    }
}

//MARK: - First Time User tappable center

struct CenterImageSelectionCTA: View {
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Select an image to start")
                .foregroundColor(.gray)
                .font(.headline)

            Image(systemName: "photo.on.rectangle")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(.gray)
        }
        .frame(width: 360, height: 280)
        .padding(.top, 0)         // 🔧 Match default image layout
        .padding(.leading, 0)
        .zIndex(2)
        .contentShape(Rectangle())
        .onTapGesture {
            print("🟢 DEBUG: Center CTA tapped")
            onTap()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .zIndex(99)
    }
}
