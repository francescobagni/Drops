import UIKit

class LocalContrast {
    /// Computes the local contrast for a given pixel in a CGImage by comparing its intensity with its neighboring pixels.
    static func compute(at point: CGPoint, in cgImage: CGImage) -> CGFloat {
        if let storedMap = Persistence.shared.retrieveContrastMap() {
            return pixelIntensity(at: point, in: storedMap.cgImage!)
        }
        
        let neighbors = [
            CGPoint(x: point.x - 1, y: point.y), CGPoint(x: point.x + 1, y: point.y),
            CGPoint(x: point.x, y: point.y - 1), CGPoint(x: point.x, y: point.y + 1)
        ]

        let centerIntensity = pixelIntensity(at: point, in: cgImage)
        var totalDifference: CGFloat = 0
        var count: CGFloat = 0

        for neighbor in neighbors {
            let neighborIntensity = pixelIntensity(at: neighbor, in: cgImage)
            totalDifference += abs(centerIntensity - neighborIntensity)
            count += 1
        }

        return count > 0 ? totalDifference / count : 0
    }

    /// Computes the local contrast for a given cluster (rectangular area) in a CGImage.
    static func compute(forCluster rect: CGRect, in cgImage: CGImage) -> CGFloat {
        let centerIntensity = averageIntensity(in: rect, cgImage: cgImage)

        let neighbors = [
            CGRect(x: rect.origin.x - rect.width, y: rect.origin.y, width: rect.width, height: rect.height),
            CGRect(x: rect.origin.x + rect.width, y: rect.origin.y, width: rect.width, height: rect.height),
            CGRect(x: rect.origin.x, y: rect.origin.y - rect.height, width: rect.width, height: rect.height),
            CGRect(x: rect.origin.x, y: rect.origin.y + rect.height, width: rect.width, height: rect.height)
        ]

        var totalDifference: CGFloat = 0
        var count: CGFloat = 0

        for neighbor in neighbors {
            let neighborIntensity = averageIntensity(in: neighbor, cgImage: cgImage)
            totalDifference += abs(centerIntensity - neighborIntensity)
            count += 1
        }

        let contrastMap = generateContrastMap(from: cgImage)
        Persistence.shared.storeContrastMap(contrastMap)

      
        return count > 0 ? totalDifference / count : 0
    }

    /// Generates a contrast map from a CGImage.
    static func generateContrastMap(from cgImage: CGImage) -> UIImage {
        
        // Placeholder for contrast map generation logic
        return UIImage(cgImage: cgImage)
    }

    /// Computes the average intensity for a given rectangular area (cluster) in a CGImage.
    static func averageIntensity(in rect: CGRect, cgImage: CGImage) -> CGFloat {
        let width = Int(rect.width)
        let height = Int(rect.height)
        let startX = Int(rect.origin.x)
        let startY = Int(rect.origin.y)

        var totalIntensity: CGFloat = 0
        var pixelCount: CGFloat = 0

        for y in startY..<startY + height {
            for x in startX..<startX + width {
                let intensity = pixelIntensity(at: CGPoint(x: x, y: y), in: cgImage)
                totalIntensity += intensity
                pixelCount += 1
            }
        }

        return pixelCount > 0 ? totalIntensity / pixelCount : 0
    }

    /// Retrieves the intensity of a pixel at a given point in a CGImage.
    private static func pixelIntensity(at point: CGPoint, in cgImage: CGImage) -> CGFloat {
        let width = cgImage.width
        let height = cgImage.height

        guard point.x >= 0, point.x < CGFloat(width), point.y >= 0, point.y < CGFloat(height) else {
            return 0
        }

        let colorSpace = CGColorSpaceCreateDeviceGray()
        var pixelData = [UInt8](repeating: 0, count: 1)

        let bytesPerPixel = 1
        let bytesPerRow = bytesPerPixel * width

        guard let context = CGContext(
            data: &pixelData,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return 0
        }

        context.draw(cgImage, in: CGRect(x: -point.x, y: -point.y, width: CGFloat(width), height: CGFloat(height)))

        return CGFloat(pixelData[0]) / 255.0
    }
}
