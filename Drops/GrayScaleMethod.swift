import UIKit

class GrayScaleMethod {
    static func applyGrayscale(to image: UIImage) -> UIImage? {
    //    print("🟡 DEBUG: GrayScaleMethod.applyGrayscale() called.")
        let context = CIContext()
        guard let currentFilter = CIFilter(name: "CIPhotoEffectMono") else {
                    print("❌ ERROR: Grayscale filter not found!")
                    return nil
                }
        let ciImage = CIImage(image: image)
        currentFilter.setValue(ciImage, forKey: kCIInputImageKey)
        
        guard let outputImage = currentFilter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            print("❌ ERROR: Grayscale conversion failed!")
            return nil
        }
      //  print("✅ DEBUG: Grayscale image successfully generated.")
        return UIImage(cgImage: cgImage)
    }
}
