import UIKit

class RegionManager {
    func recombineRegions(_ rasterizedRegions: [UIImage], fullSize: CGSize, normalizeOrientation: Bool = false) -> UIImage? {
        guard !rasterizedRegions.isEmpty else {
            print("Error: No rasterized regions provided for recombination.")
            return nil
        }

        let layerCount = rasterizedRegions.count
        print("Recombining \(layerCount) layers...")

        let size = rasterizedRegions.first?.size ?? fullSize
        let resolvedScale = UIScreen.main.scale
        print("🟡 Using Scale Factor: \(resolvedScale)")

        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else {
            print("Error: Failed to create drawing context.")
            return nil
        }

        // Iterate over layers and blend them with intensity preservation
        for (index, layer) in rasterizedRegions.enumerated() {
            var finalLayer = layer

            if normalizeOrientation {
                finalLayer = normalizeImageOrientation(finalLayer)
            }

            let rect = CGRect(origin: .zero, size: size)

            // 🔹 Introduce Opacity Control (Ensuring Layer Contribution Varies)
            let layerOpacity = CGFloat(layerCount - index) / CGFloat(layerCount) * 0.8 + 0.2 // Ensures last layers contribute less

            // 🔹 Apply Multiplicative Blending (Better Contrast Preservation)
            context.setAlpha(0.75)
            context.setBlendMode(.multiply)
            context.setAlpha(layerOpacity)
            finalLayer.draw(in: rect)

            print("🟡 Applied Layer \(index + 1) with Opacity: \(layerOpacity)")
        }

        guard let combinedImage = UIGraphicsGetImageFromCurrentImageContext() else {
            print("Error: Failed to create combined image.")
            return nil
        }

        print("✅ Final Combined Image Size: \(combinedImage.size.width) x \(combinedImage.size.height)")
        return combinedImage
    }

    private func normalizeImageOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }

        UIGraphicsBeginImageContext(image.size)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        if let normalized = normalizedImage {
            print("Image normalized successfully.")
            return normalized
        } else {
            print("Error: Failed to normalize image. Returning original.")
            return image
        }
    }
}
