import UIKit

class CircleRasterization {
    
    private static var lastProgressValue: Double = 0.0
    
    func generateDotPattern(
        for image: UIImage,
        targetSize: CGSize,
        dotSize: CGFloat,
        spacing: CGFloat,
        intensityAcceleration: CGFloat,
        colorAcceleration: ColorAcceleration,
        dotSizeFactor: CGFloat,
        layerIndex: Int,
        totalLayers: Int,
        mask: UIImage? = nil,
        dotColor: UIColor,
        clusterSize: Int,
        intensityMap: [[CGFloat]],
        gammaValue: CGFloat,
        useMulticolor: Bool, // Added parameter for multicolor mode
        // NEW: Add an optional progress callback
        progressCallback: ((Double) -> Void)? = nil
    ) -> UIImage? {
        
        let targetSize = CGSize(width: image.size.width, height: image.size.height) // Use original size
        guard let resizedImage = image.resized(to: max(targetSize.width, targetSize.height)),
              let cgImage = resizedImage.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        
        // PROGRESS BAR info calculation
        let totalClustersX = width / clusterSize
        let totalClustersY = height / clusterSize
        let totalClusters = totalClustersX * totalClustersY
        var clustersProcessed = 0

        //UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 1.0)
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // Optional mask handling
        var maskData: [UInt8]? = nil
        if let maskCgImage = mask?.cgImage {
            maskData = extractMaskData(from: maskCgImage, targetSize: CGSize(width: width, height: height))
        }

        var dotIndex = 0
        var minDotSize: CGFloat = CGFloat.infinity
        var maxDotSize: CGFloat = 0.0

        // Iterate over clusters
        for clusterY in stride(from: 0, to: height, by: clusterSize) {
            for clusterX in stride(from: 0, to: width, by: clusterSize) {
                let clusterRect = CGRect(x: clusterX, y: clusterY, width: clusterSize, height: clusterSize)

                let clusterIntensity = LocalIntensity.intensity(atX: clusterX, y: clusterY, in: intensityMap)

                // Determine number of dots based on intensity variation
                let numDots = max(1, Int((1.0 - clusterIntensity) * 3)) // Step 1: Increase Dot Density Within Clusters

                for _ in 0..<numDots {
                    // Generate random offsets within the cluster
                    let offsetX = CGFloat.random(in: -CGFloat(clusterSize) / 2...CGFloat(clusterSize) / 2)
                    let offsetY = CGFloat.random(in: -CGFloat(clusterSize) / 2...CGFloat(clusterSize) / 2)

                    let adjustedClusterX = clusterX + Int(offsetX)
                    let adjustedClusterY = clusterY + Int(offsetY)

                    // Sample local intensity for finer dot size control (Step 2)
                    let subClusterIntensity = LocalIntensity.intensity(
                        atX: adjustedClusterX,
                        y: adjustedClusterY,
                        in: intensityMap
                    )

                    let correctedIntensity = pow(subClusterIntensity, gammaValue)
                    let adjustedDotSize = max(1.0, dotSize * (1.0 + intensityAcceleration * (dotSizeFactor - correctedIntensity)))

                    if clusterX % 5000 == 0 && clusterY % 5000 == 0 {  // ✅ Prints once per 5000 dots
                        print("🔍 Dot Size Calculation - Adjusted Size:", adjustedDotSize, " SubCluster Intensity:", subClusterIntensity)
                        print("🔎 Dot Size Sample - Min:", minDotSize, "Max:", maxDotSize, " Current:", adjustedDotSize)
                    }

                    // Track min/max dot sizes
                    minDotSize = min(minDotSize, adjustedDotSize)
                    maxDotSize = max(maxDotSize, adjustedDotSize)

                    // Skip clusters outside the mask
                    if let maskData = maskData, !isClusterVisible(clusterRect, maskData: maskData, width: width) {
                        continue
                    }

                    // Compute the dot position within the cluster
                    let clusterCenterX = CGFloat(clusterX) + CGFloat(clusterSize) / 2
                    let clusterCenterY = CGFloat(clusterY) + CGFloat(clusterSize) / 2

                    // Apply random jitter to break rigid grid effect (Step 3)
                    let jitterX = CGFloat.random(in: -adjustedDotSize * 0.3...adjustedDotSize * 0.3)
                    let jitterY = CGFloat.random(in: -adjustedDotSize * 0.3...adjustedDotSize * 0.3)

                    let finalX = clusterCenterX + offsetX + jitterX
                    let finalY = clusterCenterY + offsetY + jitterY

                    // Adjust color brightness based on intensity
                    let baseColor = dotColor // ✅ Always use passed-in dotColor for Monochrome
                    let adjustedColor: UIColor
                    
                    if useMulticolor {
                        adjustedColor = getPixelColor(atX: adjustedClusterX, y: adjustedClusterY, from: cgImage)
                    } else {
                        adjustedColor = baseColor // ✅ Use dotColor as-is in Monochrome mode
                    }

                    let finalColor = adjustedColor.withAlphaComponent(max(0.1, CGFloat(1.0 - subClusterIntensity)))

                    // Draw the dot
                    let rect = CGRect(
                        x: finalX - adjustedDotSize / 2,
                        y: finalY - adjustedDotSize / 2,
                        width: adjustedDotSize,
                        height: adjustedDotSize
                    )

                    context.setFillColor(finalColor.cgColor)
                    context.fillEllipse(in: rect)

                    dotIndex += 1
                    
                    // PROGRESS BAR UPDATE At the end of each cluster
                            clustersProcessed += 1

                            // Only update progress every N clusters to avoid spamming the main queue
                          /*  if clustersProcessed % 500 == 0 {
                                let fraction = Double(clustersProcessed) / Double(totalClusters)*0.8
                                // e.g. if we want the entire dot-rasterization to represent progress from 0.3 -> 0.9, do:
                                let mappedProgress = 0.1 + fraction // 0.6
                                DispatchQueue.main.async {
                                    let newVal = mappedProgress
                                            let finalVal = max(viewModel.progress, newVal)
                                            viewModel.progress = finalVal
                                            progressCallback?(finalVal)
                                }
                            } */
                    if clustersProcessed % 500 == 0 {
                       // let fraction = Double(clustersProcessed) / Double(totalClusters)*0.8
                    // let mappedProgress = 0.1 + fraction
                        let fraction = Double(clustersProcessed) / Double(totalClusters)
                        let partial = min(1.0, fraction * 0.8)
                        let mappedProgress = 0.1 + partial

                        DispatchQueue.main.async {
                            // 1) Compare mappedProgress with the stored lastProgressValue
                            let oldProgress = CircleRasterization.lastProgressValue
                            let finalProgress = max(oldProgress, mappedProgress)

                            // 2) Update the static property
                            CircleRasterization.lastProgressValue = finalProgress

                            // 3) Send out finalProgress
                            progressCallback?(finalProgress)
                        } 
                    }
                }
            }
        }

        let rasterizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        CircleRasterization.lastProgressValue = 0.0
        return rasterizedImage
    }

    private func getPixelColor(atX x: Int, y: Int, from cgImage: CGImage) -> UIColor {
        let width = cgImage.width
        let height = cgImage.height

        guard x >= 0, x < width, y >= 0, y < height else {
            return .black // Default to black if out of bounds
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixelData = [UInt8](repeating: 0, count: 4)

        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width

        guard let context = CGContext(
            data: &pixelData,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return .black
        }

        // ✅ Fix Y-coordinate flipping to prevent mirroring
        let correctedY = height - y - 1

        // ✅ Extract color from the correct pixel location
        context.draw(cgImage, in: CGRect(x: -CGFloat(x), y: -CGFloat(correctedY), width: CGFloat(width), height: CGFloat(height)))

        let red = CGFloat(pixelData[0]) / 255.0
        let green = CGFloat(pixelData[1]) / 255.0
        let blue = CGFloat(pixelData[2]) / 255.0
        let alpha = CGFloat(pixelData[3]) / 255.0

        // ✅ Ensure colors are not affected by premultiplied alpha but retain vibrancy
        if alpha > 0 {
            return UIColor(red: red, green: green, blue: blue, alpha: alpha)
        } else {
            return UIColor(red: red, green: green, blue: blue, alpha: 1.0) // Ensure full opacity
        }
    }

    // End of generateDotPattern
    
    private func isClusterVisible(_ rect: CGRect, maskData: [UInt8], width: Int) -> Bool {
        let startX = Int(rect.origin.x)
        let startY = Int(rect.origin.y)
        let endX = min(startX + Int(rect.width), width)
        let endY = min(startY + Int(rect.height), maskData.count / width)

        for y in startY..<endY {
            for x in startX..<endX {
                let index = y * width + x
                if maskData[index] > 0 { return true } // At least one pixel in the cluster is visible
            }
        }
        return false
    }

    private func pixelIntensity(at point: CGPoint, in cgImage: CGImage) -> CGFloat {
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

        // Draw a 1x1 area at the target point to extract pixel intensity
        context.draw(cgImage, in: CGRect(x: -point.x, y: -point.y, width: CGFloat(width), height: CGFloat(height)))

        return CGFloat(pixelData[0]) / 255.0
    }

    private func extractMaskData(from cgImage: CGImage, targetSize: CGSize) -> [UInt8] {
        let width = Int(targetSize.width)
        let height = Int(targetSize.height)

        let bytesPerPixel = 1
        let bytesPerRow = bytesPerPixel * width
        var maskData = [UInt8](repeating: 0, count: width * height)

        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let context = CGContext(
            data: &maskData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return maskData
        }

        let targetRect = CGRect(origin: .zero, size: targetSize)
        context.draw(cgImage, in: targetRect)

        return maskData
    }
}
