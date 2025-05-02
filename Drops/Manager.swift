import SwiftUI
import UIKit

class Manager {
    private let regionProcessor = PosterizationMethod()
    private let regionSubdivider = RegionSubdivision()
    private let regionHighlighter = RegionHighlight()
    private var activityViewController: UIActivityViewController? // ✅ Store persistent reference

    func processImage(_ image: UIImage, layers: Int) -> (posterized: UIImage?, highlighted: UIImage?) {
        // Step 1: Posterize the image
        guard let posterizedImage = regionProcessor.posterize(image, layers: layers) else {
            print("Error: Posterization failed.")
            return (nil, nil)
        }

        return (posterizedImage, posterizedImage)
    }
    
    func shareImage(
        _ image: UIImage,
        framedExport: Bool,
        dotColor: UIColor,
        useGrayscale: Bool,
        invertColor: Bool,
        includeDebugInfo: Bool,
        gamma: CGFloat,
        dotSizeFactor: CGFloat,
        intensityAcceleration: CGFloat,
        layers: Int,
        clusterSize: Int,
        dismissSheet: @escaping () -> Void,
        restoreSheet: @escaping () -> Void
    ) {
            DispatchQueue.main.async {
                dismissSheet() // ✅ First, dismiss the SwiftUI Sheet

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // ✅ Ensure a delay before presenting Share Sheet
                    let majorDimension = max(image.size.width, image.size.height)
                    let padding = majorDimension / 24
               /*     let shouldUseDotColor = useGrayscale // Extend later for Invert
                    let backgroundColor = shouldUseDotColor ? dotColor : .white */
                    let backgroundColor = (invertColor && useGrayscale)
                        ? dotColor
                        : .white
                    let usedDotColor = (invertColor && useGrayscale)
                        ? UIColor.white
                        : dotColor
                    var finalImage = framedExport
                        ? image.withPrintFrame(
                              top: padding,
                              left: padding,
                              right: padding,
                              bottom: padding,
                              backgroundColor: backgroundColor
                          )
                        : image.addBackground(color: Color(backgroundColor))
                    
                    
                    // Debug Info rendering
                    if includeDebugInfo {
                        let debugText = """
                        Max Size: \(Int(image.size.width))
                        Cluster Size: \(clusterSize)
                        Shadow: \(gamma)
                        Drop Size: \(dotSizeFactor)
                        Contrast: \(intensityAcceleration)
                        """
                        finalImage = finalImage.overlayedWithText(debugText)
                    }
                    
                    //   Layers: \(layers)\(framedExport ? "\nPrint Frame: On" : "")
                    
                    self.activityViewController = UIActivityViewController(activityItems: [finalImage], applicationActivities: nil) // ✅ Store reference

                    if let windowScene = UIApplication.shared.connectedScenes
                        .filter({ $0.activationState == .foregroundActive })
                        .first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                        
                        self.activityViewController?.completionWithItemsHandler = { _, _, _, _ in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                print("✅ Share Sheet Dismissed - Restoring Parameters Sheet")
                                restoreSheet() // ✅ Restore parameters Sheet after Share Sheet is dismissed
                                self.activityViewController = nil // ✅ Clear reference
                            }
                        }

                        rootViewController.present(self.activityViewController!, animated: true) // ✅ Remove unnecessary completion block
                    } else {
                        print("❌ Error: Unable to find rootViewController to present Share Sheet.")
                    }
                    
                }
            }
        }
    }

extension UIImage {
    func overlayedWithText(_ text: String) -> UIImage {
        let font = UIFont.systemFont(ofSize: 48, weight: .semibold)
        let padding: CGFloat = 8

        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        self.draw(at: .zero)

        let maxTextWidth: CGFloat = 400
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]

        let boundingRect = NSString(string: text).boundingRect(
            with: CGSize(width: maxTextWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )

        let textRect = CGRect(
            x: self.size.width - maxTextWidth - padding,
            y: self.size.height - boundingRect.height - padding,
            width: maxTextWidth,
            height: boundingRect.height
        )

        let backgroundPath = UIBezierPath(roundedRect: textRect.insetBy(dx: -12, dy: -12), cornerRadius: 6)
        UIColor.white.withAlphaComponent(0.8).setFill()
        backgroundPath.fill()

        text.draw(in: textRect, withAttributes: attributes)
        let result = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        return result
    }
}
    
