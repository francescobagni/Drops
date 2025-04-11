/*
 A. Documentation: Project Objective
 Create an iOS app in Swift for image processing that supports:
 Selecting an image from the gallery.
 Posterizing the image into distinct layers.
 Highlighting extracted regions with unique colors for debugging.
 Recombining processed regions into a final output.
 Ensuring modularity and scalability for future enhancements.

 Files and Responsibilities
 1. ImageInput.swift
 Handles photo gallery input using PHPickerViewController.
 Responsibilities:
 Select an image from the photo library using PHPickerViewController.
 Pass the selected image to the parent view via a @Binding variable selectedImage.
 Key Features:
 Includes NSPhotoLibraryUsageDescription in Info.plist for photo access.
 Implements state management using @State to toggle image picker sheet presentation.

 2. RegionMethod_PosterizedLayers.swift
 Divides an image into regions by applying posterization.
 Responsibilities:
 Posterize an image using manual quantization to ensure the number of unique colors matches the Layers value specified by the user.
 Provide a function posterize(_ image: UIImage, layers: Int) -> UIImage to normalize and quantize the image.
 Current Status:
 Posterization outputs an image with the correct number of layers.
 Unique color detection in posterized images needs further debugging to ensure consistency.

 3. RegionHighlight.swift
 Overlays unique colors on subdivided regions for debugging purposes.
 Responsibilities:
 Highlight image regions with distinct colors using overlayColors(on: UIImage, regions: [UIImage]) -> UIImage?.
 Applies predefined colors with adjustable opacity for visualization.
 Current Status:
 The highlight function works but requires more accurate input from RegionSubdivision.swift.

 4. RegionSubdivision.swift
 Extracts unique regions from the posterized image.
 Responsibilities:
 Extracts unique colors and maps pixels to regions based on those colors.
 Provides a function extractRegions(from: UIImage, layers: Int) -> [UIImage] that returns a list of individual UIImage objects representing regions.
 Current Status:
 Region extraction is functional but inconsistent with posterization outputs. Debugging is ongoing.

 5. RegionManager.swift
 Combines all regions back into a single image.
 Responsibilities:
 Combines individual regions back into a single UIImage using recombineRegions(_ regions: [UIImage]) -> UIImage?.
 Code:
 import UIKit


 class RegionManager {
     func recombineRegions(_ regions: [UIImage]) -> UIImage? {
         guard let firstRegion = regions.first else { return nil }
         UIGraphicsBeginImageContext(firstRegion.size)
         
         for region in regions {
             region.draw(at: .zero)
         }
         
         let combinedImage = UIGraphicsGetImageFromCurrentImageContext()
         UIGraphicsEndImageContext()
         return combinedImage
     }
 }

 Current Status:
 Recombination works correctly but depends on the accuracy of region extraction.

 6. UIImageExtensions.swift
 Provides a utility to normalize images for consistent processing.
 Responsibilities:
 Ensures image orientation issues are resolved using the normalized() method.
 Code:

 import UIKit


 extension UIImage {
     func normalized() -> UIImage {
         if imageOrientation == .up {
             return self
         }
         UIGraphicsBeginImageContextWithOptions(size, false, scale)
         draw(in: CGRect(origin: .zero, size: size))
         let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
         UIGraphicsEndImageContext()
         return normalizedImage ?? self
     }
 }

 Current Status:
 Utility function is complete and functional.

 7. AppUI.swift
 Defines the user interface and integrates all components.
 Responsibilities:
 Displays:
 Posterized image (updated via a slider and confirmation button).
 Highlighted regions image.
 Allows the user to:
 Select an image via the "Choose Image" button (using ImageInput.swift).
 Adjust the Layers slider.
 Trigger posterization and region highlighting with explicit buttons.
 Current Status:
 UI updates are functional and responsive. Further debugging is needed to address inconsistencies in outputs.

 8. InkApp.swift
 Defines the app's entry point.
 Responsibilities:
 Serves as the main entry point for the app using the @main attribute.
 Loads the UI defined in AppUI.swift.
 Code:
 import SwiftUI


 @main
 struct InkApp: App {
     let persistenceController = PersistenceController.shared


     var body: some Scene {
         WindowGroup {
             AppUI() // Replacing ContentView with AppUI
                 .environment(\.managedObjectContext, persistenceController.container.viewContext)
         }
     }
 }

 Current Status:
 Entry point is complete and functional.

 9. Persistence.swift
 Handles Core Data persistence (currently unused in this iteration).
 Responsibilities:
 Provides a shared persistence controller for the app.
 Code:
 import CoreData


 struct PersistenceController {
     static let shared = PersistenceController()


     let container: NSPersistentContainer


     init(inMemory: Bool = false) {
         container = NSPersistentContainer(name: "Ink")
         if inMemory {
             container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
         }
         container.loadPersistentStores { _, error in
             if let error = error as NSError? {
                 fatalError("Unresolved error \(error), \(error.userInfo)")
             }
         }
     }
 }

 Current Status:
 Persistence logic is set up but unused for this project scope.

 10. Manager.swift
 Coordinates all functionalities into a coherent process.
 Responsibilities:
 Serves as a glue layer between UI and processing components.
 Ensures modularity by delegating tasks to relevant files.
 
 11.LocalContrast.swift & LocalIntensity.swift: Used for enhancing local contrast and intensity before rasterization.

 
 B. Documentation: Rasterization Pipeline for the Project
 Overview
 The Rasterization Pipeline processes an input image into rasterized layers using dot patterns, combines them into a final rasterized image, and ensures proper orientation and alignment throughout. The pipeline consists of three key components:
 Image Posterization and Region Extraction
 Rasterization of Individual Layers
 Recombination of Rasterized Layers
 Key Components
 1. Image Posterization and Region Extraction
 The input image is divided into regions based on posterization levels (e.g., grayscale levels or color separations).
 The number of regions is determined dynamically using a slider (layers).
 The extracted regions are passed to the rasterization step as distinct UIImage instances.
 Key File: RegionSubdivision.swift

 2. Rasterization of Individual Layers
 Each extracted region is transformed into a dot pattern image based on user-defined parameters:
 dotSize: Size of individual dots.
 spacing: Distance between dots.
 rotation: Rotational angle applied to the dot grid.
 Fix Implemented: In the function applyRasterization in RasterizationPreview.swift, a duplication issue was found and resolved. The original code was mistakenly processing and appending the same regions multiple times, leading to duplication and mirroring effects in the final recombined image.
 The issue was addressed by ensuring unique processing of regions during rasterization:
 swift
 Copy code
 let uniqueRegions = Array(Set(self.regions)) // Ensure unique regions

 The updated function now processes each unique region only once and outputs correctly rasterized layers.
 Key File: RasterizationPreview.swift

 3. Recombination of Rasterized Layers
 Rasterized layers are recombined into a final composite image.
 The recombination ensures all layers are drawn exactly once with proper orientation and alignment.
 Optional normalizeOrientation logic was added to ensure consistency across layers.
 Key Improvements:
 The recombineRegions function in RegionManager.swift was updated to validate layer count and eliminate any misalignment or mirroring during recombination. Each layer is drawn using the same canvas size and consistent logic:
 swift
 Copy code
 for (index, layer) in rasterizedRegions.enumerated() {
     var finalLayer = layer
     if normalizeOrientation {
         finalLayer = normalizeImageOrientation(finalLayer)
     }
     let rect = CGRect(origin: .zero, size: size)
     finalLayer.draw(in: rect)
 }


 Key File: RegionManager.swift

 Debugging Insights and Key Lessons
 Root Cause of the Issue: The duplication and mirroring issue arose in the applyRasterization function where the same regions were being appended and processed multiple times.
 Solution: Ensure uniqueness in the rasterization process by verifying and filtering the regions array:
 swift
 Copy code
 let uniqueRegions = Array(Set(self.regions))
 Verification: The updated pipeline was verified using the RasterPreview2.swift file to inspect individual rasterized layers before recombination. Each layer displayed correctly without duplication or mirroring.

 Updated Rasterization Workflow
 Processing Flow:
 Image Input: The user selects an image.
 Region Extraction: The input image is divided into unique grayscale layers (posterized regions).
 Layer Rasterization: Each unique region is rasterized into a dot pattern based on user settings.
 Recombination: All rasterized layers are combined into a single output image.
 Key Files:
 RasterizationPreview.swift: Main UI file for rasterization controls and recombination.
 RasterPreview2.swift: Layer-by-layer debugging UI to visualize individual rasterized layers.
 RegionManager.swift: Handles recombination of rasterized layers.
 RegionSubdivision.swift: Extracts posterized regions from the input image.
 
 ### Rasterization Pipeline - Project Documentation

 #### **Overview**
 The project processes input images into rasterized layers using dot patterns, allowing users to customize parameters and preview results interactively. The system ensures extracted regions and processing maps persist correctly while enabling efficient recomputation when needed.

 ---

 ## ** Recent Updates & Fixes**
 ### Improved UI & Button Interaction**
 Implemented **iOS-standard button styles**:
    - 'Choose Image' → **Secondary button**
    - 'Apply Rasterization' → **Primary button**
 Ensured buttons **respond properly** to user taps and remain inactive during processing.
 Fixed **button reusability** (previously unresponsive after first tap).

 ### ** Progress Feedback & Debugging**
 Introduced a **progress message below buttons** that dynamically updates:
    - `"Processing image..."` when rasterization starts.
    - `"Processing complete!"` when it actually finishes.
 Integrated **debug logs** (`print` statements) to track execution flow.
 >>> STILL TO FIX: Ensured progress message updates align with actual processing time.

 ### ** Sliders & Customization Fixes**
 **Intensity Acceleration slider now correctly affects output rasterization**.
 **Color Acceleration has a subtle but visible effect on dot colors**.
 **Ensured all sliders properly pass their values through processing layers**.
 **Fixed missing variable definitions (`layerDotSize`, `layerSpacing`, etc.) in `RasterPreview2.swift` to allow per-layer customizations**.
 
 ### ** Dot Color Selector Fix**
 **Dot Color selector now correctly applies user-selected colors** instead of defaulting to black.
  **Fixed `dotColor` not being passed properly through `RasterizationPreviewModel.swift` and `CircleRasterization.swift`**.
  **Dots now appear in the correct user-selected color in the final rasterized image**.
 
 ### **5. Dot Size & Spacing Fixes**
 ✅ **Dot Size is now fully user-controllable via `dotSizeFactor`.**
 ✅ **Added `dotSizeFactor` slider to UI for direct control of dot scaling.**
 ✅ **Spacing slider now correctly affects the spacing between dots.**
 ✅ **Passed `spacing` through `processImage()`, `applyRasterization()`, and `generateDotPattern()`.**
 ✅ **Updated `generateDotPattern()` in `CircleRasterization.swift` to apply spacing when placing dots.**
 ✅ **Now adjusting Spacing visibly changes the distance between rasterized dots.**

 ### **6. Rotation Removal**
 ✅ **Rotation slider removed from UI as it had no meaningful impact.**
 ✅ **Rotation calculations removed from `generateDotPattern()` in `CircleRasterization.swift`.**
 ✅ **Ensured correct dot placement without rotation transformation.**
 
 ### **7. Cluster Size Picker Implementation**
 ✅ **Replaced text input with a user-friendly Number Picker.**
 ✅ **Cluster Size picker is now aligned with Dot Color selection for a uniform UI.**
 ✅ **Picker only expands when tapped, keeping UI clean and minimal.**
 ✅ **Cluster Size is passed properly through `processImage()`, `applyRasterization()`, and `generateDotPattern()`.**
 ✅ **Users can now adjust Cluster Size dynamically and see immediate rasterization changes.**
 
 ### **8. Export Functionality**
 ✅ **Added an 'Export Image' button below the rasterized image.**
 ✅ **Ensured the button only appears when an image is available.**
 ✅ **Implemented `saveImageToGallery(_:)` to allow users to save the output image to their device.**
 ✅ **Tested and confirmed functionality in the iOS Photos app.**

 ### **9. Full Image Rendering Issue (Ongoing Investigation)**
 ✅ **Issue:** On **Xcode editor preview, images appear correctly**, but on **iPhone SE 2020 (iOS 18.2), the processed image is cropped** (only showing the top-left area).
 ✅ **Current Fix Attempts:**
    - **Ensured `applyRasterization()` passes `inputImage.size` to `recombineRegions()`.**
    - **Updated `recombineRegions()` in `RegionManager.swift` to use the full image size.**
    - **Verified that `generateDotPattern()` constrains dot placement within valid coordinates.**
 ✅ **Issue Persists:** Cropping still occurs on the physical device but not in Xcode testing.
 🚀 **Next Steps:** Investigate how iOS 18.2 handles `UIGraphicsBeginImageContextWithOptions()` and verify if additional scaling adjustments are needed.



 ### Progress Feedback & Debugging**
Introduced a **progress message below buttons** that dynamically updates:
    - `"Processing image..."` when rasterization starts.
    - `"Processing complete!"` when it actually finishes.
Integrated **debug logs** (`print` statements) to track execution flow.

 ###  Processing Flow Corrections**
**Ensured stored data clears when selecting a new image**, avoiding reusing old regions/maps unintentionally.
**Fixed processing order:** Now rasterization starts **only after** regions and maps are fully extracted.
**Removed artificial delays**—the system now operates at full efficiency.


 Future Considerations
 Efficiency:
 - Optimize the rasterization process for large images or higher layer counts.
 - Investigate further downscaling or multi-threading options for performance improvements.
 
 Additional Debugging:
 - Add runtime logs and visual overlays to validate correct alignment of layers during recombination.
 
 ---

 ## **Updated Rasterization Workflow**
 ### **1️⃣ Image Selection & Preprocessing**
 - User selects an image using the **'Choose Image'** button.
 - System clears previous **regions & processing maps** to avoid using outdated data.
 - Image is divided into **grayscale-based or color-separated layers**.

 ### **2️⃣ Rasterization & Processing**
 - User adjusts **dot size, dot size factor, spacing, rotation, intensity acceleration, color acceleration, and layer count**.
 - System **applies dot pattern rasterization** based on extracted image regions.
 - Progress is displayed in the UI **as text feedback**.
 - Rasterization now **accurately applies intensity & color acceleration settings**.
 - **Dot color selection now correctly updates rasterized output.**
 - **Dot Size Factor now dynamically affects final dot size.**

 ### **3️⃣ Result Preview & Refinement**
 - User previews the **rasterized image**.
 - User can modify parameters and **reapply rasterization dynamically**.
 - If needed, a new image can be selected to restart the process.

 ---

 ## **Key Files & Their Roles**
 📌 **`RasterizationPreview.swift`** → UI logic & user interaction
 📌 **`RasterizationPreviewModel.swift`** → Image processing & rasterization logic
 📌 **`Persistence.swift`** → Stores & retrieves processing maps
 📌 **`RegionSubdivision.swift`** → Extracts image regions for rasterization
 📌 **`LocalContrast.swift` & `LocalIntensity.swift`** → Compute image contrast & intensity
 📌 **`CircleRasterization.swift`** → Applies dot pattern rasterization (now using color acceleration, dot color selection, and dot size factor)
 📌 **`RegionManager.swift`** → Combines rasterized layers into a final image
 📌 **`ColorAcceleration.swift`** → Adjusts color variations per layer

 ---
 
 ## **Next Steps & Improvements**
 🚀 **Investigate why images are cropped on physical iPhone but not in Xcode.**
 🚀 **Test alternative image rendering methods for iOS 18.2 compatibility.**
 


*/
