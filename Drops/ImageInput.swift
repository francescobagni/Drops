import SwiftUI
import PhotosUI

struct ImageInput<ButtonStyleType: ButtonStyle>: View {
    @Binding var selectedImage: UIImage?
    @Binding var isProcessing: Bool
    @Binding var processingProgress: Double // ✅ Bind progress to the actual processing state
    @State private var isPickerPresented = false
    var buttonStyle: ButtonStyleType // ✅ Use a generic button style
    var buttonStyleProvider: () -> ButtonStyleType // ✅ Pass the function reference
    var onApplyProcessing: () -> Void

    var body: some View {
        VStack {
            Button(action: {
                print("📸 Choose Image button tapped!") // ✅ Debug log
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // ✅ Delay to ensure state updates
                    self.isPickerPresented.toggle()
                    print("📸 isPickerPresented toggled to: \(self.isPickerPresented)") // ✅ Debug log
                }
            }) {
                Image(systemName: "photo.fill.on.rectangle.fill") // ✅ SF Symbol for image selection
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24) // ✅ Matches Export button size
                    .padding(4)
                    .foregroundColor(selectedImage != nil ? AppDesign.Colors.accent : AppDesign.Colors.neutral) // Updated text color
            }
            .padding(14)
            .background(selectedImage != nil ? AnyView(Circle().fill(.ultraThinMaterial)) : AnyView(Circle().fill(AppDesign.Colors.accent)))
            .clipShape(Circle()) // ✅ Ensure button remains circular
            
            .accessibility(identifier: "chooseImageButton")

            
            .onChange(of: selectedImage) { newImage in
                DispatchQueue.main.async {
                    if newImage != nil {
                        isProcessing = true
                        onApplyProcessing()
                        print("🟢 DEBUG: Image selected, processing started") // ✅ Add Debug Log
                    } else {
                        print("🔴 DEBUG: No image selected") // ✅ Add Debug Log
                    }
                }
            }
                        
            
            .onAppear {
                    print("🔄 ImageInput View Loaded - isPickerPresented: \(isPickerPresented)")
                }
            
            .sheet(isPresented: $isPickerPresented) {
                PHPickerViewControllerRepresentable(selectedImage: $selectedImage)
                    .onAppear {
                        print("📸 Image Picker is OPENING!") // ✅ Debug log
                    }
            }
        }
    }
}

struct PHPickerViewControllerRepresentable: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: PHPickerViewControllerRepresentable

        init(parent: PHPickerViewControllerRepresentable) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true, completion: nil)
            guard let result = results.first else { return }

            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                DispatchQueue.main.async {
                    if let unwrappedImage = image as? UIImage {
                        // Normalize and resize the image before processing
                        print("🟡 DEBUG 6: Image Size BEFORE Normalization: \(unwrappedImage.size.width) x \(unwrappedImage.size.height)")
                        let normalizedImage = unwrappedImage.normalized()
                        print("🟡 DEBUG 7: Image Size AFTER Normalization: \(normalizedImage.size.width) x \(normalizedImage.size.height)")
                        let resizedImage = normalizedImage //.resized(to: 1024) // Target resolution
                        print("🟡 Initial Imported Image Size: \(unwrappedImage.size.width) x \(unwrappedImage.size.height)")
                        self?.parent.selectedImage = resizedImage
                    }
                }
            }

        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
}

struct ZoomShareButtons: View {
    var isZoomed: Bool
    var isProcessing: Bool
    @Binding var selectedImage: UIImage?
   // var onZoomToggle: () -> Void
    var onShare: () -> Void
    var isShareDisabled: Bool

    var body: some View {
        if selectedImage != nil {
            HStack(spacing: 16) {
                Spacer()
                
             /*   Button(action: {
                    withAnimation {
                        onZoomToggle()
                    }
                }) {
                    Image(systemName: isZoomed ? "arrow.up.right.and.arrow.down.left" : "arrow.down.left.and.arrow.up.right")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                   // .padding(12)
                    //.background(Circle().fill(.ultraThinMaterial))
                }
                .disabled(selectedImage == nil) // ✅ Only disable when no image is selected
                .opacity(selectedImage == nil ? 0.5 : 1.0)
                .onAppear {
                            print("🔍 DEBUG: ZoomShareButtons Appeared - selectedImage exists:", selectedImage != nil)
                        }
                        .onChange(of: selectedImage) { newValue in
                            print("🔄 DEBUG: ZoomShareButtons detected selectedImage change:", newValue != nil)
                        }
                .frame(width: 40, height: 40)
                .background(Circle().fill(.ultraThinMaterial)) */

                Button(action: {
                    onShare()
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20) // Updated to 44 points
                }
                .disabled(selectedImage == nil) // ✅ Unified behavior with Zoom button
                .opacity(selectedImage == nil ? 0.5 : 1.0)
                .frame(width: 39, height: 39) // Updated to 44 points
                .background(Circle().fill(.ultraThinMaterial))
            }
        }
    }
}


struct TopBarView: View {
    @Binding var selectedImage: UIImage?
    @Binding var isProcessing: Bool
    @Binding var processingProgress: Double // ✅ Bind progress to the actual processing state
    var isZoomed: Bool
    var isSheetPresented: Bool
    var onChooseImage: () -> Void
    var onProcessingComplete: () -> Void
   // var onZoomToggle: () -> Void
    var onShare: () -> Void
    @Binding var progressMessage: String // ✅ Add progressMessage binding

    
    var body: some View {
        HStack {
            if !isZoomed {
                ZStack {
                    ImageInput(selectedImage: $selectedImage,
                               isProcessing: $isProcessing,
                               processingProgress: $processingProgress, // ✅ Pass progress binding down
                               buttonStyle: AppDesign.chooseImageButtonStyle(imageLoaded: selectedImage != nil),
                               buttonStyleProvider: { AppDesign.chooseImageButtonStyle(imageLoaded: selectedImage != nil) },
                               onApplyProcessing: onProcessingComplete
                               )
                        .accessibility(identifier: "chooseImageButton")
                        .onTapGesture {
                            onChooseImage()
                        }
                }
                .frame(width: 80, alignment: .leading)
            }

            Spacer().frame(width: 0) // ✅ Ensures a fixed 20px spacing between Choose Image and Progress Indicator

         /*  ZStack {
                           if isProcessing {
                               ProgressIndicator(progress: processingProgress, color: AppDesign.Colors.accent) // ✅ Use passed binding
                           }
                       }
                       .frame(width: 80, height: 20, alignment: .leading) */
                      
                       
                       .onChange(of: selectedImage) { _ in
                           DispatchQueue.main.async {
                               print("🟢 DEBUG: Image selected, forcing UI refresh for Zoom & Share buttons")
                               isProcessing = false // ✅ Ensure UI refresh
                           }
                       }
            
           .onChange(of: progressMessage) { newMessage in
                DispatchQueue.main.async {
                    if let progressValue = Double(newMessage), progressValue >= 0.0, progressValue <= 1.0 {
                        processingProgress = progressValue // ✅ Directly update from progressMessage
                    } else if newMessage.isEmpty {
                        processingProgress = 0.0 // ✅ Reset when no processing
                    }
                }
            }

            Spacer()
            
            
            // ✅ Ensure Zoom & Share Buttons Align Correctly
            ZoomShareButtons(
                            isZoomed: isZoomed,
                            isProcessing: isProcessing,
                            selectedImage: $selectedImage,
                         //   onZoomToggle: onZoomToggle,   // ✅ Use function passed from `AppUI.swift`
                            onShare: onShare,             // ✅ Use function passed from `AppUI.swift
                            isShareDisabled: selectedImage == nil
                        )
                        .frame(width: 96) // ✅ Keep consistent width
                        .onAppear {
                            print("🔍 DEBUG: TopBarView Appeared - selectedImage exists:", selectedImage != nil)
                        }
                        .onChange(of: selectedImage) { newValue in
                            print("🔄 DEBUG: TopBarView detected selectedImage change:", newValue != nil)
                        }
            
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .frame(height: 50)
        .padding(.leading, 16)  // ✅ Keep left padding unchanged
        .padding(.trailing, 32)
    }
}
