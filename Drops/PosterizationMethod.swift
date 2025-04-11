import UIKit
import CoreImage

class PosterizationMethod {
    func posterize(_ image: UIImage, layers: Int) -> UIImage? {
        print("🟡 DEBUG: Posterization function called with layers:", layers)
        guard let cgImage = image.cgImage else { return nil }
        
        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceGray()
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ), let data = context.data else {
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))

        let pixelBuffer = data.bindMemory(to: UInt8.self, capacity: width * height)

        // Apply adaptive contrast enhancement before quantization
        let contrastFactor: CGFloat = 1.5
        var minIntensity: CGFloat = 1.0
        var maxIntensity: CGFloat = 0.0
        
        // Gamma correction
        let gamma: CGFloat = 1.2 // Adjust for more or less midtone contrast
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * width + x
                let normalized = CGFloat(pixelBuffer[offset]) / 255.0
                let corrected = pow(normalized, gamma) * 255.0
                pixelBuffer[offset] = UInt8(min(255, max(0, corrected)))
            }
        }

        for y in 0..<height {
            for x in 0..<width {
                let offset = y * width + x
                let intensity = CGFloat(pixelBuffer[offset]) / 255.0
                minIntensity = min(minIntensity, intensity)
                maxIntensity = max(maxIntensity, intensity)
            }
        }
        

        let contrastRange = maxIntensity - minIntensity
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * width + x
                var normalizedIntensity = (CGFloat(pixelBuffer[offset]) / 255.0 - minIntensity) / (contrastRange + 0.0001)
                
                normalizedIntensity = ((normalizedIntensity - 0.5) * (contrastFactor + 0.3 * (1.0 - normalizedIntensity))) + 0.5
                normalizedIntensity = min(max(normalizedIntensity, 0.0), 1.0)
                
                let step = 1.0 / CGFloat(layers)
                pixelBuffer[offset] = UInt8((normalizedIntensity / step).rounded() * step * 255)
            }
        }

        guard let outputCGImage = context.makeImage() else { return nil }
        print("🔎 DEBUG: Posterization completed - Checking grayscale levels before returning.")
        // grayscale levels check
        print("🔎 DEBUG X: Posterized image - Checking grayscale distribution...")

        var uniqueGrayscaleLevels = Set<UInt8>()
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * width + x
                uniqueGrayscaleLevels.insert(pixelBuffer[offset])
            }
        }

        print("🔎 DEBUG Y: Unique grayscale levels found in posterized image: \(uniqueGrayscaleLevels.count)")
        print("🔎 DEBUG: Sample grayscale values: \(Array(uniqueGrayscaleLevels.prefix(10)))") // Print first 10 values for reference
        // grayscale levels check end
        
        return UIImage(cgImage: outputCGImage)
        
    }

    private func refinePosterization(_ image: UIImage, layers: Int) -> UIImage? {
        print("🟡 DEBUG: refinePosterization() is being executed.")
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height

        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: colorSpace, bitmapInfo: bitmapInfo.rawValue),
              let data = context.data else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        
        // Bind memory safely to UInt8
        let pixelBuffer = data.bindMemory(to: UInt8.self, capacity: width * height)

        // Compute histogram to determine adaptive binning
        var histogram = [Int](repeating: 0, count: 256)
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * width + x
                histogram[Int(pixelBuffer[offset])] += 1
            }
        }

        // Find peaks and distribute bins dynamically
        // let maxBins = min(layers, 256)
        let maxBins = max(min(layers * 3, 256), 16)  // Ensure at least 16 grayscale steps
        var binEdges = [Int]()
        let totalPixels = width * height
        var accumulated = 0

        for i in 0..<256 {
            accumulated += histogram[i]
            if accumulated > (totalPixels / maxBins) * binEdges.count {
                binEdges.append(i)
            }
        }

        // Apply new binning
        for y in 0..<height {
            for x in 0..<width {
                let offset = y * width + x
                let intensity = pixelBuffer[offset]

                // Find closest bin
                /* var closestBin = 0
                for bin in binEdges {
                    if abs(bin - Int(intensity)) < abs(binEdges[closestBin] - Int(intensity)) {
                        closestBin = binEdges.firstIndex(of: bin) ?? 0
                    }
                } */
                var closestBin = binEdges.min(by: { abs($0 - Int(intensity)) < abs($1 - Int(intensity)) }) ?? 0
                
                // Ensure midtones get more bins
                if intensity > 80 && intensity < 180 {
                    closestBin = min(closestBin + 5, 255)  // Push midtones into more varied levels
                }

                pixelBuffer[offset] = UInt8(binEdges[closestBin])
            }
        }
        
        let uniqueValues = Set(UnsafeBufferPointer(start: pixelBuffer, count: width * height))
        print("🔎 After Fix - Unique grayscale levels used:", uniqueValues.count)

        if uniqueValues.count < 10 {
            print("❌ Warning: Posterization might still be too aggressive. Review contrast or gamma settings.")
        }

        // Create the refined posterized image
        guard let outputCGImage = context.makeImage() else { return nil }

        let basePosterizedImage = UIImage(cgImage: outputCGImage)
        print("🔎 DEBUG: Posterization completed - Checking grayscale levels before returning.")

        // Call refinePosterization for further improvement
        if let refinedImage = refinePosterization(basePosterizedImage, layers: layers) {
            print("🔎 DEBUG: Using refined posterization results.")
            return refinedImage
        } else {
            print("⚠️ Warning: refinePosterization() failed, returning base posterization result.")
            return basePosterizedImage
        }
        
     //   return UIImage(cgImage: outputCGImage)
        
    }
    
}
