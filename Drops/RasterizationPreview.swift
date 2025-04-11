/*

import SwiftUI
import PhotosUI

struct RasterizationPreview: View {
    @StateObject private var viewModel = RasterizationPreviewModel()
    @State private var showPicker: Bool = false
    @State private var selectedImage: UIImage? = nil
    @State private var isImagePickerPresented = false
    @State private var dotSize: CGFloat = 10.0
    @State private var spacing: CGFloat = 5.0
    @State private var rotation: CGFloat = 0.0
    @State private var layers: Int = 4
    @State private var intensityAcceleration: CGFloat = 1.0
    @State private var dotColor: Color = .black
    @State private var colorAcceleration: CGFloat = 0.1
    @State private var clusterSize: Int = 14
    @State private var isProcessing = false
    @State private var progressMessage: String = ""
    @State private var dotSizeFactor: CGFloat = 0.1  // Default value
    @State private var maxSize: Int = 1608 // Default max size for images
    @State private var contrastThreshold: CGFloat = 0.015  // Default value
    @State private var useGrayscale: Bool = false
    @State private var gamma: CGFloat = 1.5
    
    
    var body: some View {
        ScrollView {
            VStack {
                
                if let finalImage = viewModel.rasterizedImage {
                    VStack {
                        Text("Rasterized Image Preview")
                            .font(.headline)
                        
                        GeometryReader { geometry in
                            Image(uiImage: finalImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)  // Ensure the full image is shown
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                        
                        .frame(height: 300) // Maintain a reasonable view height
                        
                        Button(action: {
                            saveImageToGallery(finalImage)
                        }) {
                            Text("Export Image")
                                .font(.headline)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.top, 10) // Normal padding like other buttons
                    }
                    
                } else {
                    Text("Select an image to preview rasterization").font(.subheadline).foregroundColor(.gray)
                }
                
                VStack {
                    
                    HStack {
                        Stepper(value: $maxSize, in: 512...3000, step: 24) {
                        Text("Max Size: \(maxSize)")
                            .font(.headline)
                            .frame(alignment: .leading)
                            .padding(.vertical, 5)
                        Spacer()
                        }
                    }
                    
                    HStack {
                        ColorPicker("Choose Dot Color", selection: $dotColor)
                            .font(.headline)
                            .frame(alignment: .leading)
                            .padding(.vertical, 5)
                        Spacer()
                    }
                    
                    HStack {
                        Text("Cluster Size:")
                            .font(.headline)
                            .frame(alignment: .leading)
                            .padding(.vertical, 5)  // Ensures vertical alignment
                        
                        Spacer()
                        
                        Menu {
                            Picker("Cluster Size", selection: $clusterSize) {
                                ForEach(1...50, id: \.self) { value in
                                    Text("\(value)").tag(value)
                                }
                            }
                        } label: {
                            Text("\(clusterSize)")
                                .font(.body)
                                .frame(width: 50, height: 30)
                                .multilineTextAlignment(.center)
                                .background(RoundedRectangle(cornerRadius: 5).fill(Color.gray.opacity(0.2)))
                                .padding(.vertical, 5)  // Matches Dot Color Picker height
                        }
                    }
                    
                    HStack {
                        Toggle("Posterization / Grayscale", isOn: $useGrayscale)
                            .font(.headline)
                            .frame(alignment: .leading)
                            .padding(.vertical, 5)
                        Spacer()
                        
                            .onChange(of: useGrayscale) { newValue in
                                print("🟡 DEBUG: Toggle switched - useGrayscale is now:", newValue)
                            }
                        }
                    
        
                    Text("Gamma Correction: \(String(format: "%.2f", gamma))")
                    Slider(value: $gamma, in: 0.1...16.0, step: 0.1)
                    Text("Dot Size Factor: \(String(format: "%.2f", dotSizeFactor))")
                    Slider(value: $dotSizeFactor, in: 0.0...5.0, step: 0.01)
                    if !useGrayscale {  // ✅ Only show Layers control when Posterization is active
                        Text("Layers: \(layers)")
                        Slider(value: Binding(
                            get: { Double(self.layers) },
                            set: { self.layers = Int($0) }
                        ), in: 2...20, step: 1)
                    }
                    Text("Intensity Acceleration: \(String(format: "%.2f", intensityAcceleration))")
                    Slider(value: $intensityAcceleration, in: 0.0...2.0, step: 0.1)
                }
                .padding()
                
                Button("Choose Image") {
                    isImagePickerPresented = true
                }
                .buttonStyle(.bordered)
                .sheet(isPresented: $isImagePickerPresented) {
                    ImagePickerRepresentable(selectedImage: $selectedImage)
                }
                
                Button("Apply") {
                    if selectedImage == nil {
                        progressMessage = "No image selected!"
                        print("❌ Error: No image selected.") // Debug log
                        return
                    }
                    
                    guard let image = selectedImage else { return }
                    
                    progressMessage = "Processing image..."
                    print("✅ Selected image received: \(image.size)")
                    
                    if let fixedImage = image.normalized().resized(to: CGFloat(maxSize)) {
                        print("✅ Image successfully normalized and resized: \(fixedImage.size)")
                        print("🟡 DEBUG: Passing maxSize to processImage: \(maxSize)")
                        
                        viewModel.processImage(
                            fixedImage,
                            maxSize: maxSize,
                            layerCount: layers,
                            clusterSize: clusterSize,
                            spacing: spacing,
                            intensityAcceleration: intensityAcceleration,
                            colorAcceleration: colorAcceleration,
                            dotSizeFactor: dotSizeFactor,
                            dotColor: UIColor(dotColor),
                            contrastThreshold: contrastThreshold,
                            useGrayscale: useGrayscale,
                            gammaValue: gamma,
                            progressMessage: $progressMessage
                        )
                    } else {
                        progressMessage = "Failed to process image."
                        print("❌ Error: Failed to normalize or resize image.") // Debug log
                    }
                }
                .buttonStyle(.borderedProminent)  // ✅ Makes it use primary colors
                .disabled(isProcessing || viewModel.rasterizedImage == nil)
                .padding()
                
            }
        }
        
        .onChange(of: selectedImage) {
            guard let image = selectedImage else { return }
            
            let screenSize = UIScreen.main.bounds.size
            print("🟡 DEBUG: User-defined maxSize: \(maxSize)")
            
            if let fixedImage = image.normalized().resized(to: CGFloat(maxSize)) {
                print("🟡 DEBUG: `UIScreen.main.bounds.size`: \(screenSize.width) x \(screenSize.height), Calculated maxSize: \(maxSize)")
                
                Persistence.shared.clearStoredData()
                viewModel.processImage(fixedImage, maxSize: maxSize, layerCount: layers, clusterSize: clusterSize, spacing: spacing, intensityAcceleration: intensityAcceleration, colorAcceleration: colorAcceleration, dotSizeFactor: dotSizeFactor, dotColor: UIColor(dotColor), contrastThreshold: contrastThreshold, useGrayscale: useGrayscale, gammaValue: gamma, progressMessage: $progressMessage)
            } else {
                print("Error: Could not resize image")
            }
        }  // <- Ensure this } properly closes the onChange block
        
    }
        
}
    
    struct ImagePickerRepresentable: UIViewControllerRepresentable {
        @Binding var selectedImage: UIImage?
        
        func makeUIViewController(context: Context) -> PHPickerViewController {
            var config = PHPickerConfiguration()
            config.filter = .images
            config.selectionLimit = 1
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = context.coordinator
            return picker
        }
        
        func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        class Coordinator: NSObject, PHPickerViewControllerDelegate {
            var parent: ImagePickerRepresentable
            
            init(_ parent: ImagePickerRepresentable) {
                self.parent = parent
            }
            
            func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
                picker.dismiss(animated: true, completion: nil)
                guard let result = results.first else { return }
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                        DispatchQueue.main.async {
                            self?.parent.selectedImage = image as? UIImage
                        }
                    }
                }
            }
        }
    }
    
    func saveImageToGallery(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    struct RasterizationPreview_Previews: PreviewProvider {
        static var previews: some View {
            RasterizationPreview()
        }
    }

*/
