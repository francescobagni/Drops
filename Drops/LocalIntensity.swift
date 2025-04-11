import UIKit

class LocalIntensity {
    /// Precomputes a 2D intensity map for an image, using stored data if available.
    static func precomputeIntensityMap(for cgImage: CGImage, contrastThreshold: CGFloat) -> [[CGFloat]] {
        if let storedMap = Persistence.shared.retrieveIntensityMap(), let storedCgImage = storedMap.cgImage {
            return generateIntensityMap(from: storedCgImage, contrastThreshold: contrastThreshold)
        }
        
        let intensityMap = generateIntensityMap(from: cgImage, contrastThreshold: contrastThreshold)
        Persistence.shared.storeIntensityMap(UIImage(cgImage: cgImage))
        return intensityMap
    }
    
    /// Retrieves the intensity value from a precomputed intensity map for a specific pixel.
        static func intensity(atX x: Int, y: Int, in intensityMap: [[CGFloat]]) -> CGFloat {
            guard y >= 0, y < intensityMap.count, x >= 0, x < intensityMap[0].count else {
                return 0.0  // Return minimum intensity for out-of-bounds pixels
            }
            
            return intensityMap[y][x]
        }

    /// Generates a 2D intensity map from a CGImage with contrast enhancement and gamma correction.
    private static func generateIntensityMap(from cgImage: CGImage, contrastThreshold: CGFloat) -> [[CGFloat]] {
        let width = cgImage.width
        let height = cgImage.height
        var intensityMap: [[CGFloat]] = Array(repeating: Array(repeating: 0.0, count: width), count: height)

        let colorSpace = CGColorSpaceCreateDeviceGray()
        var pixelData = [UInt8](repeating: 0, count: width * height)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return intensityMap
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))

        // Compute histogram and contrast adjustment
        var histogram = [Int](repeating: 0, count: 256)
        var minIntensity: CGFloat = 1.0
        var maxIntensity: CGFloat = 0.0

        for y in 0..<height {
            for x in 0..<width {
                let intensity = CGFloat(pixelData[y * width + x]) / 255.0
                minIntensity = min(minIntensity, intensity)
                maxIntensity = max(maxIntensity, intensity)
                histogram[Int(intensity * 255)] += 1
            }
        }

        // Adaptive contrast stretch: ensure minIntensity isn't too high and maxIntensity isn't too low
        let adjustedMin = max(0.05, minIntensity * (1.0 - contrastThreshold))  // Expand lower range
        let adjustedMax = min(1.0, maxIntensity * (1.0 + contrastThreshold * 2.0))  // Expand upper range
        minIntensity = adjustedMin
        maxIntensity = adjustedMax

        print("🔎 Adjusted Intensity Map Range - Min:", minIntensity, "Max:", maxIntensity)

        for y in 0..<height {
            for x in 0..<width {
                var normalizedIntensity = (CGFloat(pixelData[y * width + x]) / 255.0 - minIntensity) / (maxIntensity - minIntensity + 0.0001)
                
                // Apply contrast stretching
                normalizedIntensity = min(max(normalizedIntensity, 0.0), 1.0)

                // Apply gamma correction
                let gamma: CGFloat = 1.2
                intensityMap[y][x] = pow(normalizedIntensity, gamma)
            }
        }
        
        print("🔎 Intensity Map - Min:", minIntensity, "Max:", maxIntensity)

        return intensityMap
    }
}
