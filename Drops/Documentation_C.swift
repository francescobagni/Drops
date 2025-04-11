/*
  
  Updated Documentation: Rasterization Pipeline for Image Processing (March 02 2025)
 
 🔹 High-Level Pipeline Order
     1.    Image Input & Preprocessing
     •    User selects an image.
     •    Image is resized and normalized to match maxSize.
     •    Debugging ensures dimensions are correctly processed.
     2.    Posterization (PosterizationMethod.swift)
     •    Image is reduced to N grayscale levels.
     •    Debugging confirms grayscale levels are correctly retained.
     3.    Region Extraction (Previously RegionSubdivision.swift)
     •    🚫 Now Bypassed: This step used to extract individual grayscale masks.
     •    Current Approach: The posterized image is now directly rasterized as a single region.
     4.    Rasterization (RasterizationPreviewModel.swift → CircleRasterization.swift)
     •    The posterized image (or grayscale image) is processed into dot patterns.
     •    Gamma correction now enhances shadow details while keeping midtones balanced.
     •    Debugging confirms intensity variations are properly preserved.
     5.    Final Output & Recombination (RegionManager.swift)
     •    Rasterized output is compiled into the final image.
     •    Debugging confirms that grayscale variations and dot distribution remain accurate.
 
 🔹 Current Pipeline:
 ✅ Image Input → ✅ Posterization → 🚫 (Bypassed RegionSubdivision) → ✅ Rasterization → ✅ Output

  Overview:
  The rasterization pipeline processes input images into layered dot-pattern images, providing user-defined controls and ensuring correct image processing and output generation.

 🔹 Key Recent Findings & Fixes

 1️⃣ UI & Interaction Enhancements
     •    Created a new SwiftUI file UI_v1.swift to test a new UI pattern while preserving the existing implementation (RasterizationPreview.swift).
     •    Implemented a Bottom Sheet for user parameters:
     •    Default position: Medium detent.
     •    Swiping down maximizes the image (max zoom).
     •    Swiping up returns to default zoom.

 2️⃣ Parameter Refinements & Optimizations
     •    Dot Size parameter was removed in favor of dotSizeFactor, which better controls dot scaling.
     •    Gamma Correction is now a user-adjustable parameter in the UI.
     •    Contrast Threshold was removed because it was only relevant in the region extraction step, which we no longer use.
     •    Layers Parameter is now hidden when Grayscale Mode is selected since it is only relevant in Posterization Mode.

 3️⃣ Rasterization Refinements
     •    Gamma correction was integrated into CircleRasterization.swift:
     •    Improves shadow details and prevents excessive darkening.
     •    Adjustable via UI (gammaValue slider).
     •    Intensity Acceleration & Dot Size Factor were fine-tuned to ensure smoother dot variations.
 
 ✅ **Gamma correction (`CircleRasterization.swift`) now:**
    - Enhances **shadow details** without over-darkening.
    - Adjusts **midtone balance** dynamically.
    - Is **fully user-adjustable via slider**.

 ✅ **Intensity Acceleration & Dot Size Factor were fine-tuned:**
    - **Smoother dot variations** with more accurate scaling.
    - **No more abrupt jumps between dot sizes in darker areas**.

 ✅ **Cluster Size Picker Improvements:**
    - Switched from **text input** to **a more user-friendly Number Picker**.
    - Picker **only expands when tapped**, keeping UI **clean and minimal**.
    - Cluster Size now **dynamically updates** rasterization in real time.
 
4️⃣ Discarded Floating Button above Sheet (Due to not finding correct solution yet)
 **Issue:**
 - The Apply button **was moved outside the Sheet** to match the Apple Maps UI pattern.
 - **This caused multiple Auto Layout and interaction issues**, including:
    - **Conflicts with the Sheet’s detent system (`UISheetPresentationController`).**
    - **Gestures interfering between dragging the Sheet and pressing Apply.**
    - **Auto Layout constraint errors ("no common ancestor").**
 - **Solution:**
    - Reverted back to **keeping the Apply button inside the Sheet**.
    - Ensured **button placement does not interfere with Sheet dragging**.
    - **Prevented Apply from being clipped at smaller detents**.
 
5️⃣ Export Functionality Update
 - **Added an "Export Image" button** below the rasterized image.
 - **Only appears when an image is available.**
 - **Implemented `saveImageToGallery(_:)`** to allow users to save the output image.
 - **Tested and confirmed working in iOS Photos app.**

 🔹 Next Steps & Potential Improvements
     1.    Fine-tune the new UI (UI_v1.swift):
     2.    Further Rasterization Adjustments:
     •    Improve performance on average sized images.
     •    Improve performance on large images.
     3.    Evaluate Region Extraction Reimplementation:
     •    Could reintroducing RegionSubdivision offer better edge definition?
     •    Would adaptive region-based rasterization improve results?
 
 🔹 Key Implementation Files
 ✅ `RasterizationPreviewModel.swift` → Handles **image processing & rasterization**.
 ✅ `CircleRasterization.swift` → **Generates dot pattern rasterization** with gamma correction.
 ✅ `UI_v1.swift` → **Main UI structure** with **image selection, buttons, and Sheet**.
 ✅ `PosterizationMethod.swift` → **Posterization logic (grayscale reduction).**
 ✅ `RegionManager.swift` → **Combines rasterized layers into a final image.**
 ✅ `Persistence.swift` → **Stores & retrieves extracted processing maps.**
 ✅ `Manager.swift` → **Handles sharing/exporting logic**.
 ✅ `SheetController.swift` → **Manages the Bottom Sheet UI interactions**.
 
 
 ## 🚀 **Final Notes**
 - The **floating Apply button attempt has been removed** due to persistent issues.
 - **UI is now stable**, with **rasterization parameters working properly**.
 - Next steps focus on **performance optimization and final UI refinements**.
 
_ _ _ _
 
 Addendum: Current Status (February 22 2025)
 This document provides an updated overview of the rasterization UI project, focusing on the latest UI refinements, current issues, and next steps.
 🛠 Recent Updates & Fixes
 1️⃣ UI Enhancements
 Bottom Sheet Improvements
     •    Converted to UIKit-based CustomSheetView for improved control over detents.
     •    Reorganized UI layout:
     •    Key parameters (Max Size, Dot Color, Cluster Size, Posterization/Grayscale Mode) are now displayed in horizontally scrollable square tiles.
     •    The remaining sliders are kept in a vertical column.
 Bottom Sheet Interactions
     •    Added grabber bar for better usability.

 ### **2️⃣ Functional Fixes**
 ✅ **Restored "Choose Image" Button**
    - Ensured `ImagePickerRepresentable` is correctly implemented.
    - Selecting an image **properly updates `selectedImage`** and triggers processing.

 ✅ **Fixed Parameters Sheet Not Restoring After Sharing**
    - Issue: **After sharing an image, the bottom Sheet disappeared**.
    - Solution:
      - Used `isSheetPresented = true` and `sheetDetent = .height(150)` to **bring it back to the minimum detent**.

 ✅ **Fixed Share Button Not Opening Share Sheet**
    - Issue: On **real devices**, the Share Sheet **opened briefly and then closed**.
    - Solution:
      - Moved `shareImage()` logic to `Manager.swift` for a **cleaner separation of UI logic**.
      - **Ensured `UIActivityViewController` reference persists** so that the Share Sheet does not immediately close.

 ✅ **Fixed Parameters Row Not Scrolling Horizontally**
    - **Ensured `.frame(minWidth: UIScreen.main.bounds.width * 1.2)` allows horizontal scrolling**.
    - **Prevented vertical drags from interfering with Sheet interactions**.
 
 
 🔜 Next Steps
 1️⃣ Fix the Fixed Sheet (Make it Draggable and avoid it snapping to completely out of screen visibility, so that user can still drag it up when needed)
     •    Investigate if CustomSheetView overrides SwiftUI’s drag behavior.
     •    Ensure UISheetPresentationController allows detent switching.
 2️⃣ Prevent the Sheet from Disappearingfull disappearance.
 3️⃣ Fix Xcode Preview Showing Duplicate Buttons
_
 
 Adendum: Current Status (February 23 2025)

 ## **1️⃣ Fixes & Solutions Adopted**
 ### ✅ **Fix: "Choose Image" Button Was Inactive**
 - Issue: The "Choose Image" button was **not tappable when the Sheet was present**.
 - **Solution:**
   - Used `.presentationBackgroundInteraction(.enabled)` to allow interactions behind the Sheet.
   - Ensured `allowsHitTesting(true)` and `.zIndex(10)` kept the button interactive.
   - Moved gesture handling to **prevent tap conflicts with Sheet dragging**.

 ---

 ### ✅ **Fix: Parameters Sheet Not Restoring After Sharing**
 - Issue: The **parameters Sheet disappeared** when the Share button was clicked but **did not return**.
 - **Solution:**
   - Created a **callback to restore the Sheet** once the Share Sheet was dismissed.
   - Used `isSheetPresented = true` and `sheetDetent = .height(150)` to bring it back to minimum detent.

 ---

 ### ✅ **Fix: Share Button Did Not Open Share Sheet**
 - Issue: Clicking **Export (Share button)** did **not open the native Share Sheet** on real devices.
 - **Solution:**
   - Moved `shareImage()` to `Manager.swift` to **keep UI logic clean**.
   - Used a **persistent `UIActivityViewController` reference** to prevent instant closing.
   - Implemented `.completionWithItemsHandler` to detect when the Share Sheet is dismissed.

 ---

 ### ✅ **Fix: Parameters Row Was Not Scrolling Horizontally**
 - Issue: The **scrollable parameters row stopped being scrollable** after other fixes.
 - **Solution:**
   - Ensured `.frame(minWidth: UIScreen.main.bounds.width * 1.2)` forces scrollability.
   - Adjusted `.gesture(DragGesture(minimumDistance: 10))` to **prevent vertical drags from interfering**.

 ---
 
 
 Adendum: Current Status (March 13 2025)
 ⸻

 Project Documentation Update: Ink App - Recent UI and Functional Updates
 
 Since last update, we changed the app's name to Ink, created a new main view file in AppUI.swift, rather than UI_v1.swift, and added visual and functionality updates.

 🛠 Summary of Updates Implemented So Far:

 1️⃣ Button Styling Enhancements:
     •    ‘Choose Image’ button now has an accent background when no image is selected.
     •    It switches to .ultraThinMaterial when an image is selected or processed.
     •    Zoom and Share buttons now match the Choose Image button’s background behavior.

 2️⃣ Processed Image and UI Centering Fixes:
     •    Removed an unwanted black background from the top HStack, which was covering part of the processed image.
     •    The processed image now correctly centers on the screen, regardless of aspect ratio (e.g., 16:9, 4:3).

 3️⃣ Automated Processing Triggers:
     •    Image processing automatically starts when an image is selected (previously required manual Apply button tap).
     •    The Apply button has been removed from the UI, as processing is now triggered by:
        •    Pulling down the Parameters Sheet after changing values.
        •    Closing an expanded Dynamic Slider after adjusting a setting.

 4️⃣ ArcSlider and Dynamic Sliders:
     •    Specific parameters are defined as Dynamic Sliders, and sit on the left side of the screen. These have a default and an expanded state.
     •    In expanded state, the Dynamic Sliders show their current value in numeric text, and an overlay Arc Slider appears over the image for user to edit the value.

 5️⃣ Status Bar Visibility Fix:
     •    Status bar text color was previously blending with the dark background.
     •    Now forced to use .lightContent, ensuring visibility in dark mode.

 ⸻

 🔍 Key Information for Future Work:
     •    Button styles are centralized in chooseImageButtonStyle() in AppUI.swift.
     •    Processing is now fully automated, triggered by sheet detents and slider collapses.
     •    Dynamic Slider behavior and expanded state are controlled via DynamicSlider.swift.
     •    ArcSlider placement logic is inside AppUI.swift using GeometryReader.
     •    Sheet detent logic is defined in SheetController.swift, ensuring dynamic behavior.

 ⸻

 📌 Next Steps / Potential Future Improvements:
     •    Buttons fixes
        -  Zoom and Share buttons should be circular, but we still didn't achieve this.
        -  Zoom and Share buttons should be disabled when no image is selected to ensure clear action states.
        -  Dynamic Sliders alignment should be adjusted so that their center is aligned to Choose Image button's center.
 
     •    Dynamic Slider labels adjustment:
        - The info icon (‘i’) inside the Dynamic Slider label should be inside the same pill background as the text label, for better visibility.
 
     •    Processing Trigger:
        - it now requires one or two repetitions of the Choose Image for the first image to be actually loaded and processed, this should be fixed: image should be loaded and process should be starting at first image selected on Image Picker.
        - when a new image is selected for processing, any previously running processing should be killed, and only the most recent should be allowed to proceed.
 
     •    Status bar text color was blending with the dark background, instead it should be forced to use .lightContent, or in any case to ensure visibility against the dark background. Consider this resource for this https://developer.apple.com/forums/thread/760300
 
     •    Processing performance enhancements.

 ⸻

 📝 This document ensures that another ChatGPT thread can continue the work seamlessly without losing track of the progress achieved so far. 🚀

 After updating Documentation_C.swift with this content, everything will be properly documented for future development! 🚀 Let me know if you need further refinements.

 ⸻

📌 Addendum: Status Update (March 27, 2025)

 ✅ Summary of Major Improvements Since Last Update

 1️⃣ Print Frame Feature
     • Added toggle parameter for "Print Frame" in the Parameters Sheet.
     • When active, the rasterized image is surrounded by a border padding (1/24th of longest side).
     • Automatically uses white or Dot Color (if Invert Color is active) for the background.

 2️⃣ Invert Color Feature
     • New toggle in Parameters Sheet.
     • Only enabled when Monochrome mode is active.
     • When active:
        - Background becomes Dot Color.
        - Dot Color becomes white.
     • Includes real-time preview logic and share/export consistency.

 3️⃣ Rasterization & Processing Logic Refinement
     • Dot color logic is now unified: all processing, preview, and share/export respect Invert Color and Monochrome modes.
     • Clean parameter passing for framedExport, useMulticolor, and invertColor through `RasterizationPreviewModel`.

 4️⃣ Visual Layout Polishing
     • Zoom and Share buttons are now visually consistent with circular layout.
     • Dynamic Slider buttons expanded to 44pt for improved accessibility.
     • ArcSlider now features:
        - Rounded background arc edges.
        - Radial step indicators using accent dots.
        - Digit precision aligned with granularity (e.g., Focus shows 0.01, Contrast 0.05).
     • Top Bar and Parameter Sheet spacing adjusted to avoid crowding with status bar.

 5️⃣ Interaction & Usability Enhancements
     • Tapping on Dynamic Slider’s button now collapses expanded slider (toggle behavior).
     • Bottom Sheet triggers reprocessing when user pulls it down, including for new parameters like Print Frame and Invert Color.
     • Tap anywhere on the onboarding screen now triggers the Image Picker (outside the Sheet).
     • "Drops Size" label replaces "Focus" for clarity.

 6️⃣ Finger Lens Feature (Experimental)
     • Circle magnifier that appears on tap during fullscreen mode.
     • Magnifies rasterized image with fixed zoom factor.
     • Tracks finger position with proper offset and scaling.
     • Initial bug with position mismatch and mirroring was resolved by:
        - Applying coordinate correction.
        - Using scaled offset relative to original image position.
     • Now functional, but background color and resolution refinements ongoing.

 7️⃣ Stability & Debugging Improvements
     • Console logs improved to help track parameter changes and processing logic.
     • Sheet presentation fixed to always restore after Sharing.
     • Processing is prevented from restarting unnecessarily unless parameters truly change.

 ⸻
*/
