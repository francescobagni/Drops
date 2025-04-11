import UIKit
import SwiftUI

class RasterizationPreviewModel: ObservableObject {
    @Published var rasterizedImage: UIImage?
    @Published var progress: Double = 0.0  // ✅ Ensure progress is a published state
    
    private var extractedRegions: [UIImage] = []
    private let rasterizer = CircleRasterization()
    private let regionManager = RegionManager()
    
    
    func processImage(
        _ inputImage: UIImage, maxSize: Int, layerCount: Int, clusterSize: Int, spacing: CGFloat,
        intensityAcceleration: CGFloat, colorAcceleration: CGFloat, dotSizeFactor: CGFloat,
        dotColor: UIColor, contrastThreshold: CGFloat, useGrayscale: Bool, useMulticolor: Bool, gammaValue: CGFloat, progressMessage: Binding<String>, completion: @escaping () -> Void, // NEW: define a closure that takes a Double
        progressCallback: @escaping (Double) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                self.progress = 0.0
                progressCallback(0.0)
            }

            // Step 1 (resize done)
            DispatchQueue.main.async {
                self.updateProgressMonotonically(0.1, progressCallback)

                // Begin artificial increments if progress remains stuck at 0.1
                self.artificiallyIncrementProgressIfNeeded(progressCallback: progressCallback)
            }
            
            guard let resizedImage = inputImage.resized(to:  CGFloat(maxSize))?.normalized() else {
                return
            }
           
            Persistence.shared.clearStoredData()
            self.extractedRegions.removeAll()

            var processedImageToUse: UIImage?

            if useMulticolor {
                print("🟡 DEBUG: Using original image (Multicolor Mode enabled).")
                processedImageToUse = resizedImage // ✅ Use original colors
            } else if useGrayscale {
                print("🟡 DEBUG: Applying grayscale conversion.")
                processedImageToUse = GrayScaleMethod.applyGrayscale(to: resizedImage) ?? PosterizationMethod().posterize(resizedImage, layers: layerCount)
            } else {
                print("🟡 DEBUG: Applying posterization with \(layerCount) layers.")
                processedImageToUse = PosterizationMethod().posterize(resizedImage, layers: layerCount)
            }

            guard let finalImage = processedImageToUse else {
                print("❌ Error: Image processing failed, skipping rasterization.")
                return
            }

            print("✅ Image processing successful! Using processed image.")
            self.extractedRegions = [finalImage]

            // 🔹 Step 3: Rasterization
            guard let rasterizedImage = self.applyRasterization(
                using: self.extractedRegions,
                contrastMap: nil,
                intensityMap: nil,
                clusterSize: clusterSize,
                spacing: spacing,
                intensityAcceleration: intensityAcceleration,
                colorAcceleration: colorAcceleration,
                dotSizeFactor: dotSizeFactor,
                dotColor: dotColor,
                contrastThreshold: contrastThreshold,
                fullSize: resizedImage.size,
                gammaValue: gammaValue,
                useMulticolor: useMulticolor,
                progressCallback: progressCallback
            ) else {
                DispatchQueue.main.async {
                    progressMessage.wrappedValue = "Processing failed."
                }
                print("❌ Error: Rasterization failed.")
                return
            }

            DispatchQueue.main.async {
                self.progress = 1.0
                self.rasterizedImage = rasterizedImage
                progressMessage.wrappedValue = "Processing complete!"
                completion() // ✅ Notify UI that processing is complete
                print("🎉 Rasterization completed successfully!")
            }
        }
    }
    
    
    func applyRasterization(
        using regions: [UIImage],
        contrastMap: UIImage?,
        intensityMap: [[CGFloat]]?,
        clusterSize: Int,
        spacing: CGFloat,
        intensityAcceleration: CGFloat,
        colorAcceleration: CGFloat,
        dotSizeFactor: CGFloat,
        dotColor: UIColor,
        contrastThreshold: CGFloat,
        fullSize: CGSize,
        gammaValue: CGFloat,
        useMulticolor: Bool,
        progressCallback: @escaping (Double) -> Void
    ) -> UIImage? {
        guard !regions.isEmpty else { return nil }
        
        var rasterizedImages: [UIImage] = []
        let layerCount = regions.count
        
        for (index, region) in regions.enumerated() {
            let validRegion = region  // Keep original rasterized size
            
            let layerDotSize = 10.0 * CGFloat(index + 1) / CGFloat(layerCount)
            let layerSpacing = 5.0 * CGFloat(index + 1) / CGFloat(layerCount)
            
            let colorAcc = ColorAcceleration(baseColor: dotColor, acceleration: colorAcceleration)
            let adjustedColor = UIColor(cgColor: dotColor.cgColor) // force-copies to break possible internal references
            
            print("🟡 DEBUG 18: Before Rasterization - Image Size: \(validRegion.size.width) x \(validRegion.size.height)")
            print("🟡 DEBUG 13: Rasterization Function Called With Size: \(fullSize.width) x \(fullSize.height)")
            
            // ✅ Ensure rasterization happens at the correct size
            let rasterizedImage = rasterizer.generateDotPattern(
                for: validRegion,
                targetSize: fullSize,
                dotSize: layerDotSize,
                spacing: layerSpacing,
                intensityAcceleration: intensityAcceleration,
                colorAcceleration: colorAcc,
                dotSizeFactor: dotSizeFactor,
                layerIndex: index,
                totalLayers: layerCount,
                dotColor: adjustedColor,
                clusterSize: clusterSize,
                intensityMap: intensityMap ?? LocalIntensity.precomputeIntensityMap(for: validRegion.cgImage!, contrastThreshold: contrastThreshold),
                gammaValue: gammaValue,
                useMulticolor: useMulticolor,
                progressCallback: progressCallback
            )
            
            if let rasterized = rasterizedImage {
                rasterizedImages.append(rasterized) // ✅ Use as-is, don't resize
            } else {
                rasterizedImages.append(validRegion)
            }
        }
        
        rasterizedImages.forEach { print(" - \($0.size.width) x \($0.size.height)") } // Debug lines END
        return regionManager.recombineRegions(rasterizedImages, fullSize: fullSize)
    }
    
    
    func addBackground(to image: UIImage) -> UIImage {
        let size = image.size
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        let context = UIGraphicsGetCurrentContext()

        // ✅ Fill with `imageBG` from AppDesign
        let bgColor = UIColor(AppDesign.Colors.imageBG)
        bgColor.setFill()
        context?.fill(CGRect(origin: .zero, size: size))

        // ✅ Draw the processed image on top
        image.draw(in: CGRect(origin: .zero, size: size))

        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return finalImage ?? image
    }

    private func artificiallyIncrementProgressIfNeeded(progressCallback: @escaping (Double) -> Void) {
        // We'll do increments up to 0.2 in 0.01 steps every 2 seconds.
        // This ensures the bar doesn't stay stuck at 0.1.
        let maxProgress: Double = 0.2
        let step: Double = 0.01
        let incrementCount = Int((maxProgress - 0.1) / step) // e.g. 9 steps from 0.1 -> 0.19

        for i in 1...incrementCount {
            let delaySeconds = 2.0 * Double(i)
            DispatchQueue.main.asyncAfter(deadline: .now() + delaySeconds) {
                // If the actual progress is still below 0.2, artificially bump it.
                if self.progress < maxProgress {
                    let newVal = 0.1 + (step * Double(i))
                    if newVal > maxProgress { return }
                    self.updateProgressMonotonically(newVal, progressCallback)
                } else {
                    // Once real progress has moved on, stop increments.
                    return
                }
            }
        }
    }
    
//MARK: - Monotonic progress update
    
     func updateProgressMonotonically(_ newValue: Double, _ progressCallback: @escaping (Double) -> Void) {
        let finalVal = max(self.progress, newValue)
        self.progress = finalVal
        progressCallback(finalVal)
    }
    
}
