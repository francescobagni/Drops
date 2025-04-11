import UIKit

class RegionSubdivision {
    func extractRegions(from image: UIImage, layers: Int) -> [UIImage] {
        print("🟡 DEBUG: extractRegions() is running - Checking if grayscale levels are intact.")
        if let storedRegions = Persistence.shared.retrieveRegions() {
            print("🔎 DEBUG: Checking if input image is already posterized before extraction...")
            return storedRegions
        }
        
        print("🟡 DEBUG 1: Original Input Image Size Before Processing: \(image.size.width) x \(image.size.height)")
        
        guard let cgImage = image.cgImage else { return [] }
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        print("🟡 Initial Image Size: \(image.size.width) x \(image.size.height)")
        print("🟡 Target Extraction Size: \(width) x \(height)")

        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: colorSpace, bitmapInfo: bitmapInfo.rawValue),
              let data = context.data else { return [] }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        print("🟡 Image Drawn in Context: \(width) x \(height)")

        let pixelBuffer = data.bindMemory(to: UInt8.self, capacity: width * height)
    
        print("🔎 DEBUG: Checking grayscale levels in input image...")
        
        // Pixels debug start
        var sampledPixelValues = Set<UInt8>()
        let sampleSize = 10 // Number of pixels to check

        for _ in 0..<sampleSize {
            let x = Int.random(in: 0..<width)
            let y = Int.random(in: 0..<height)
            let offset = y * width + x
            let intensity = pixelBuffer[offset]
            sampledPixelValues.insert(intensity)
        }

        // Debugging printout for verification
        print("🔎 DEBUG: Sampled pixel values in posterized image: \(sampledPixelValues.sorted())")
       
        let step = 255 / (layers - 1)
        let uniqueGrayscaleLevels = (0..<layers).map { UInt8($0 * step) } // Replace this with dynamic extraction if needed

        print("🔎 DEBUG: Expected grayscale levels from posterization: \(uniqueGrayscaleLevels)")

        // Cross-check expected vs. actual
        if !sampledPixelValues.isSubset(of: Set(uniqueGrayscaleLevels)) {
            print("⚠️ WARNING: Unexpected grayscale levels detected in posterized image!")
        }
        // Pixels debug end
        
        var printedCount = 0 // Counter to limit the number of prints

        for y in 0..<height where y % 1000 == 0 {
            for x in 0..<width where x % 1000 == 0 {
                if printedCount < 3 {  // Limit to first 5 pixels
                    let offset = y * width + x
                    let pixelValue = pixelBuffer[offset]
                    print("🔎 DEBUG: Pixel at (\(x), \(y)) has intensity \(pixelValue)")
                    printedCount += 1
                }
            }
        }

        var regionImages: [UIImage] = []
       
        
        for (index, level) in uniqueGrayscaleLevels.enumerated() {
            print("🔎 DEBUG: Mask level \(level) is being applied.")
            
            let maskBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: width * height)
            defer { maskBuffer.deallocate() }

            print("🟡 DEBUG 2: Extracting Region - Input Size: \(image.size.width) x \(image.size.height)")
            
            var nonZeroCount = 0

            for y in 0..<height {
                for x in 0..<width {
                    let offset = y * width + x
                    let intensity = pixelBuffer[offset]
                    
                    // let tolerance: UInt8 = 100  // Allow a small tolerance for grayscale matching
                    // Compute the contrast range from posterized image
                    let minIntensity = uniqueGrayscaleLevels.min() ?? 0
                    let maxIntensity = uniqueGrayscaleLevels.max() ?? 255
                    let contrastRange = maxIntensity - minIntensity

                    // Dynamic tolerance based on contrast range
                    let tolerance = max(UInt8(5), UInt8(Int(contrastRange) / (layers * 2))) // Minimum tolerance of 5
                    if y % 5000 == 0 && x % 500 == 0 { // Print only every 500x500 pixels
                        print("🔎 DEBUG: Dynamic tolerance set to \(tolerance) based on contrast range \(contrastRange) at pixel (\(x), \(y))")
                    }
                    
                    if abs(Int(intensity) - Int(level)) <= Int(tolerance) {
                        maskBuffer[offset] = 255
                    } else {
                        maskBuffer[offset] = 0
                    }
                    
                    // Print only once every 5000 pixels
                    var printLimit = 5  // Limit the debug prints to 5 times per level
                    if offset % 85000 == 0 && printLimit > 0 {
                        print("🔎 DEBUG: Non-zero pixels in mask for level \(level): \(nonZeroCount)")
                        printLimit -= 1  // Decrease the print count after each print
                    }
                }
            }

            print("🟡 Region Masking Step - Target Size: \(width) x \(height)")
            guard let maskData = CFDataCreate(nil, maskBuffer, width * height),
                  let provider = CGDataProvider(data: maskData),
                  let maskCGImage = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: width, space: colorSpace, bitmapInfo: bitmapInfo, provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent) else {
                continue
            }

            print("🟡 CGImage Created Size: \(maskCGImage.width) x \(maskCGImage.height)")
            let regionImage = UIImage(cgImage: maskCGImage, scale: 1.0, orientation: .up)
            print("🟡 Extracted Region \(index + 1) Size: \(regionImage.size.width) x \(regionImage.size.height)")
            if let regionCGImage = regionImage.cgImage, let regionData = regionCGImage.dataProvider?.data {
                let regionBuffer = CFDataGetBytePtr(regionData)
                let uniqueLevelsInRegion = Set(UnsafeBufferPointer(start: regionBuffer, count: width * height))
                print("🔎 DEBUG: Unique grayscale levels in extracted region \(index + 1): \(uniqueLevelsInRegion.sorted())")
            }
            regionImages.append(regionImage)
        }
        
        print("🟡 Extracted Region Sizes Before Returning:")
        regionImages.forEach { print(" - \($0.size.width) x \($0.size.height)") }
        
        print("🔎 DEBUG: Expected grayscale levels from posterization: \(uniqueGrayscaleLevels)")
        
        for (index, region) in regionImages.enumerated() {
            guard let cgImage = region.cgImage, let data = cgImage.dataProvider?.data else { continue }
            let pixelBuffer = CFDataGetBytePtr(data)
            let uniqueValues = Set(UnsafeBufferPointer(start: pixelBuffer, count: width * height))
            
            print("🔎 Region \(index + 1) - Unique grayscale levels detected:", uniqueValues.count)
            print("🔎 DEBUG: Intensity values in Region \(index + 1):", uniqueValues.sorted())
        }
        
        print("🔎 DEBUG: Expected grayscale levels from posterization: \(uniqueGrayscaleLevels)")
        
        for (index, region) in regionImages.enumerated() {
            guard let cgImage = region.cgImage, let data = cgImage.dataProvider?.data else { continue }
            let pixelBuffer = CFDataGetBytePtr(data)
            let uniqueValues = Set(UnsafeBufferPointer(start: pixelBuffer, count: width * height))
            print("🔎 Region \(index + 1) - Unique grayscale levels detected:", uniqueValues.count)
            print("🔎 DEBUG: Actual grayscale levels found in region \(index + 1): \(uniqueValues.sorted())")
        }
        
        print("🔎 DEBUG: Extracted regions count: \(regionImages.count). Unique levels used: \(uniqueGrayscaleLevels)")
        Persistence.shared.storeRegions(regionImages)
        return regionImages
    }
}
