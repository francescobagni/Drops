import UIKit

class RegionHighlight {
    func overlayColors(on image: UIImage, regions: [UIImage]) -> UIImage? {
        guard let baseCGImage = image.cgImage else { return nil }
        let width = baseCGImage.width
        let height = baseCGImage.height

        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, image.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // Flip the context vertically to align with UIKit's coordinate system
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1.0, y: -1.0)

        // Draw the original image as the base
        context.draw(baseCGImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))

        // Define distinct colors for each region
        let colors: [UIColor] = [
            .red, .green, .blue, .yellow, .magenta, .cyan, .orange, .purple, .brown, .gray
        ]

        for (index, region) in regions.enumerated() {
            guard let cgRegion = region.cgImage else { continue }

            // Set a semi-transparent color for the overlay
            let color = colors[index % colors.count].withAlphaComponent(0.5)
            context.setBlendMode(.normal)
            context.setFillColor(color.cgColor)

            // Draw the region image as a mask
            context.clip(to: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)), mask: cgRegion)
            context.fill(CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))

            // Reset the clipping path
            context.resetClip()
        }

        // Generate the final highlighted image
        let highlightedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        // Normalize the highlighted image to correct orientation
        return highlightedImage?.normalized()
    }
}
