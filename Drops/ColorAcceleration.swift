import UIKit

struct ColorAcceleration {
    let baseColor: UIColor
    let acceleration: CGFloat // Controls brightness variation across layers

    
    func apply(to color: UIColor, layerIndex: Int, totalLayers: Int) -> UIColor {
        let adjustmentFactor = CGFloat(layerIndex + 1) / CGFloat(totalLayers) * acceleration
        let adjustedColor = color.withAlphaComponent(min(1.0, color.cgColor.alpha + adjustmentFactor))


        return adjustedColor
    }
    
    func color(forLayer index: Int, totalLayers: Int) -> UIColor {
        // Adjust brightness based on layer index
    // let brightnessFactor = 1.0 - (CGFloat(index) * acceleration / CGFloat(totalLayers))
        let brightnessFactor = pow(1.0 - (CGFloat(index) * acceleration / CGFloat(totalLayers)), 2.0)
      //  let brightnessFactor = pow(1.0 - (CGFloat(index) * acceleration / CGFloat(totalLayers)), 1.5)
        print("🔎 Color Acceleration - Layer:", index, "Brightness Factor:", brightnessFactor)
        
        // Extract RGB components and adjust brightness
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        baseColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        // Apply brightness adjustment (clamped to valid range)
        red = min(max(red * brightnessFactor, 0), 1)
        green = min(max(green * brightnessFactor, 0), 1)
        blue = min(max(blue * brightnessFactor, 0), 1)
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
       
    }
}
