/* import SwiftUI
import UIKit

struct UI_v1: View {
    @StateObject private var viewModel = RasterizationPreviewModel()
    @State private var selectedImage: UIImage? = nil
    @State private var isImagePickerPresented = false
    @State private var sheetDetent: PresentationDetent = .medium
    @State private var zoomState: CGFloat = 1.0
    @State private var dotSize: CGFloat = 10.0
    @State private var spacing: CGFloat = 5.0
    @State private var layers: Int = 4
    @State private var intensityAcceleration: CGFloat = 1.0
    @State private var dotColor: Color = .black
    @State private var clusterSize: Int = 14
    @State private var dotSizeFactor: CGFloat = 0.1
    @State private var maxSize: Int = 1680
    @State private var useGrayscale: Bool = false
    @State private var gamma: CGFloat = 1.5
    @State private var isProcessing = false
    @State private var progressMessage: String = ""
    @State private var isSheetPresented: Bool = true
    @State private var manager = Manager() 
    
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // ✅ Fixed: Button Row at the Top
                HStack {
                    ImageInput(selectedImage: Binding(
                        get: { self.selectedImage },
                        set: { newImage in
                            DispatchQueue.main.async {
                                if let image = newImage {
                                    self.selectedImage = image
                                    print("✅ Image selected: \(image.size)")
                                    self.isProcessing = false
                                }
                            }
                        }
                    ))
                    .zIndex(10) // ✅ Ensures button remains above the Sheet
                    .accessibility(identifier: "chooseImageButton") // ✅ Helps UI testing
                    .allowsHitTesting(true) // ✅ Ensures taps register
                    
                    .onTapGesture {
                        print("📸 Choose Image button tapped!") // ✅ Debug log
                        DispatchQueue.main.async {
                            self.isImagePickerPresented.toggle()
                            print("📸 isImagePickerPresented set to: \(self.isImagePickerPresented)") // ✅ Debug log
                        }
                    }
                    .onChange(of: selectedImage) { newImage in
                        if newImage != nil {
                            print("✅ `selectedImage` updated, enabling Apply button.")
                            self.isProcessing = false
                        }
                    }
                    
                    Spacer()
                    
                    Button("Apply") {
                        guard let image = selectedImage else {
                            progressMessage = "No image selected!"
                            return
                        }
                        
                        progressMessage = "Processing image..."
                        viewModel.processImage(
                            image,
                            maxSize: maxSize,
                            layerCount: layers,
                            clusterSize: clusterSize,
                            spacing: spacing,
                            intensityAcceleration: intensityAcceleration,
                            colorAcceleration: 0.1,
                            dotSizeFactor: dotSizeFactor,
                            dotColor: UIColor(dotColor),
                            contrastThreshold: 0.015,
                            useGrayscale: useGrayscale,
                            gammaValue: gamma,
                            progressMessage: $progressMessage
                        ) {
                            DispatchQueue.main.async {
                                self.isProcessing = false // ✅ Hide progress indicator when done
                                print("✅ Processing fully complete, UI updated.")
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isProcessing || selectedImage == nil)
                    
                    // ✅ Export Button
                    Button(action: {
                        if let image = viewModel.rasterizedImage {
                            manager.shareImage(image, dismissSheet: {
                                isSheetPresented = false // ✅ Hide parameters Sheet before Share Sheet opens
                            }, restoreSheet: {
                                isSheetPresented = true  // ✅ Restore parameters Sheet after Share Sheet is dismissed
                                sheetDetent = .height(150) // ✅ Ensure it comes back at minimum detent
                            })
                        }
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .padding(10)
                    }
                    .buttonStyle(.borderedProminent)
                    .clipShape(Circle())
                    .disabled(viewModel.rasterizedImage == nil)
                }
                .zIndex(5)
                .padding()
                .background(Color.white)
                .frame(maxWidth: .infinity)
                
                Spacer() // ✅ Keeps buttons at the top
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            
            
            VStack {
                if let finalImage = viewModel.rasterizedImage {
                    GeometryReader { geometry in
                        let imageSize = finalImage.size
                        let screenAspectRatio = geometry.size.width / geometry.size.height
                        let imageAspectRatio = imageSize.width / imageSize.height
                        let fitWidth = screenAspectRatio > imageAspectRatio
                        
                        Image(uiImage: finalImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(
                                width: fitWidth ? geometry.size.width * zoomState : nil,
                                height: fitWidth ? nil : geometry.size.height * zoomState
                            )
                            .clipped()
                            .animation(.easeInOut(duration: 0.3), value: zoomState)
                    }
                } else {
                    Text("Select an image to start")
                        .foregroundColor(.gray)
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        
        
   
            .sheet(isPresented: $isSheetPresented) {
                CustomSheetView {
                    CustomSheetContent(
                        maxSize: $maxSize,
                        clusterSize: $clusterSize,
                        useGrayscale: $useGrayscale,
                        dotColor: $dotColor,
                        intensityAcceleration: $intensityAcceleration,
                        dotSizeFactor: $dotSizeFactor,
                        gamma: $gamma,
                        layers: $layers
                    )
                }
                .interactiveDismissDisabled(true) // ✅ Prevent unintended dismissals
                .presentationBackgroundInteraction(.enabled) // ✅ Only allows dragging interactions, prevents conflicts
                .background(Color.clear) // ✅ Ensures touch passthrough
                .frame(maxHeight: UIScreen.main.bounds.height * 0.75) // ✅ Limits Sheet to 3/4 screen height
                .presentationDetents([
                    .height(150), // ✅ Restores minimum detent
                    .medium,
                    .large
                ])
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            let isVerticalDrag = abs(value.translation.height) > abs(value.translation.width)
                            if isVerticalDrag {
                                print("🟢 Dragging Sheet Vertically")
                            } else {
                                print("🟡 Horizontal Scroll Detected")
                            }
                        }
                )
                .zIndex(2)
            }
       
            
        }
        
        
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(false)
        .onAppear {
            DispatchQueue.main.async {
                self.sheetDetent = .medium // 🔹 Force Medium on Start
            }
        }
        .onChange(of: sheetDetent) { newDetent in
            DispatchQueue.main.async {
                if newDetent == .height(150) {
                    // ✅ Prevent full dismissal; keep the sheet at small size
                    self.sheetDetent = .medium
                } else {
                    self.sheetDetent = newDetent
                }
                self.updateZoom(for: self.sheetDetent)
            }
        }
        
    }
    
    
    private func updateZoom(for detent: PresentationDetent) {
        withAnimation {
            switch detent {
            case .large:
                zoomState = 1.2 // Slight zoom-in when sheet is fully expanded
            case .medium:
                zoomState = 1.0 // Default zoom level
            default:
                zoomState = 1.0
            }
        }
    }
    
}
    
    struct UI_v1_Previews: PreviewProvider {
        static var previews: some View {
            UI_v1()
                .previewDisplayName("Main UI Preview")
                .preferredColorScheme(.light)
        }
    }
    
 */

