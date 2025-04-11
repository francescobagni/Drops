import UIKit

struct GoldenRatioFrame {
    /// A convenience function to compute top, left, right, and bottom margins
    /// for a golden-ratio-based print border.
    ///
    /// - Parameters:
    ///   - imageSize: The size of the image (width x height).
    ///   - baseDivisor: A suggested divisor to compute base margin from the major dimension.
    ///     e.g., 30 means the base margin is image’s major dimension / 30.
    ///   - useShortSide: If true, base margin is computed from the shorter dimension
    ///     rather than the max dimension. (Optional design choice)
    /// - Returns: (top, left, right, bottom) margins to add around the image
    static func computeMargins(
        for imageSize: CGSize,
        baseDivisor: CGFloat = 4.236/* *1.618 */,
        useShortSide: Bool = false
    ) -> (top: CGFloat, left: CGFloat, right: CGFloat, bottom: CGFloat) {
        let phi: CGFloat = 1.618  // Approx. golden ratio
        let majorDimension = max(imageSize.width, imageSize.height)
        let minorDimension = min(imageSize.width, imageSize.height)
        
        // Decide which dimension to use:
        let dimension = useShortSide ? minorDimension : majorDimension
        
        // Base margin
        let baseMargin = dimension / baseDivisor
        
        // Derive the four margins
        let topMargin = baseMargin
        let leftMargin = baseMargin
        let rightMargin = baseMargin
      //  let bottomMargin = baseMargin * phi
        let bottomMargin = baseMargin
        
        return (topMargin, leftMargin, rightMargin, bottomMargin)
    }
}
