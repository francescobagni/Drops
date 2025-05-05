import SwiftUI
import UIKit

public struct SheetController {
    public static let smallestSheetDetent: CGFloat = 65 // ✅ Make this public so AppUI can access it
}

public struct SheetControllerConstants {
    public static let smallDetent = 65
    public static let sheetBackgroundColor = AppDesign.Colors.neutralB
}

struct CustomSheetView<Content: View>: UIViewControllerRepresentable {
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear

        controller.addChild(hostingController)
        controller.view.addSubview(hostingController.view)
        hostingController.didMove(toParent: controller)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: controller.view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor)
        ])

        controller.modalPresentationStyle = .automatic

        if let sheetPresentationController = controller.presentationController as? UISheetPresentationController {
            sheetPresentationController.largestUndimmedDetentIdentifier = .large
            sheetPresentationController.prefersGrabberVisible = true
            sheetPresentationController.prefersScrollingExpandsWhenScrolledToEdge = true
            sheetPresentationController.prefersEdgeAttachedInCompactHeight = false
            sheetPresentationController.widthFollowsPreferredContentSizeWhenEdgeAttached = true
            controller.isModalInPresentation = false

            sheetPresentationController.detents = [
                .custom(identifier: .init("smallDetent"), resolver: { _ in SheetController.smallestSheetDetent }),
                .medium()
            ]

            DispatchQueue.main.async {
                sheetPresentationController.selectedDetentIdentifier = .medium
            }
        }

        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleDrag))
        controller.view.addGestureRecognizer(panGesture)

        return controller
    }
    
    class Coordinator: NSObject {
        @objc func handleDrag(gesture: UIPanGestureRecognizer) {
            if gesture.state == .changed {
                print("🟢 Dragging the Sheet")
            }
        }
    }
    

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
}

struct CustomSheetContent: View {
    @Binding var useMulticolor: Bool
    @Binding var maxSize: Int
    @Binding var clusterSize: Int
    @Binding var useGrayscale: Bool
    @Binding var dotColor: Color
    @Binding var intensityAcceleration: CGFloat
    @Binding var dotSizeFactor: CGFloat
    @Binding var gamma: CGFloat
    @Binding var layers: Int
    @Binding var framedExport: Bool // New state variable for Framed Export
    @Binding var invertColor: Bool // Added binding for invertColor
    
    @State private var isGrainPickerExpanded: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // ✅ Detect taps outside the Sheet to collapse it
                Color.clear
                    .contentShape(Rectangle()) // ✅ Ensures tap detection
                    .onTapGesture {
                        withAnimation {
                            // Assuming you have a way to access the sheetDetent state
                            // sheetDetent = .height(SheetController.smallestSheetDetent) // ✅ Collapse sheet
                        }
                    }

                VStack(alignment: .leading, spacing: 6) {
                    Spacer().frame(height: 12)
                    // ✅ Title Row with Info Icon
        
                    ZStack {
                        Text("Image Options")
                            .font(.subheadline)
                            .foregroundColor(AppDesign.Colors.accent)
                            .frame(maxWidth: .infinity, alignment: .center) // ✅ Perfect center alignment

                        HStack {
                            Spacer() // ✅ Push the icon to the right
                            Image(systemName: "info.circle")
                                .foregroundColor(AppDesign.Colors.accent.opacity(0.0))
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing) // ✅ Aligns only the icon to the right
                    }
                    .padding(.top, 6)
                    .padding(.horizontal)

                    Spacer().frame(height: 6)
                    
                    // ✅ Organize Tiles in Rows of 3
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                        
                        
                        // Multicolor Parameter
                        VStack {
                            Text("Multicolor")
                                .font(.subheadline)
                                .foregroundColor(AppDesign.Colors.accent2)

                            Button(action: {
                                useMulticolor.toggle() // ✅ Toggle the multicolor mode
                            }) {
                                Image(systemName: "lightspectrum.horizontal")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 32, height: 32)
                                    .symbolRenderingMode(.palette) // ✅ Enables multicolor rendering
                                    .foregroundStyle(
                                        useMulticolor ? LinearGradient(
                                            gradient: Gradient(colors: [Color.yellow, Color.orange, Color.red, Color.purple, Color.blue, Color.green]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.gray, Color.gray]), // ✅ Matches type to avoid mismatching error
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    ) // ✅ Multicolor when active, gray when inactive
                                    .padding(12)
                                    .background(useMulticolor ? AppDesign.Colors.accent.opacity(0.2) : AppDesign.Colors.neutral.opacity(0.2))
                                    .clipShape(Circle())
                            }
                        }
                        .frame(height: 116) // ✅ Ensures uniform height
                        .frame(maxWidth: .infinity)
                        .background(AppDesign.Colors.neutralB) // ✅ Ensures same background as other tiles
                        .cornerRadius(10) // ✅ Matches the standard tile styling
                        .transaction { $0.animation = nil }
                        
                        // Pic Size Parameter
                        VStack {
                            Text("Pic Size")
                                .font(.subheadline)
                                .foregroundColor(AppDesign.Colors.accent2)
                            Picker("", selection: $maxSize) {
                                ForEach([800, 1280, 1440, 1680, 1800, 1920, 2400, 2880, 3360], id: \.self) { value in
                                    Text("\(value)")
                                        .foregroundColor(AppDesign.Colors.accent) // ✅ Override iOS accent color
                                        .tag(value)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .labelsHidden()
                        }
                        .frame(height: 116)
                        .frame(maxWidth: .infinity)
                        .background(AppDesign.Colors.neutralB) // ✅ Use centrally managed color for tile backgrounds
                        .cornerRadius(10)
                        .transaction { $0.animation = nil }

                        // Grain Parameter (Sheet Picker)
                      //  @State var isGrainPickerExpanded: Bool = false

                        VStack {
                            Text("Grain")
                                .font(.subheadline)
                                .foregroundColor(AppDesign.Colors.accent2)

                            Button(action: {
                                isGrainPickerExpanded.toggle()
                            }) {
                                Text("\(clusterSize)")
                                    .font(.headline)
                                    .foregroundColor(AppDesign.Colors.accent)
                                    .padding(12)
                                    .frame(maxWidth: .infinity)
                                   // .background(AppDesign.Colors.neutral.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .sheet(isPresented: $isGrainPickerExpanded) {
                                VStack(spacing: 20) {
                                    Text("Select Grain Value")
                                        .font(.headline)
                                        .padding()

                                    Picker("Grain", selection: $clusterSize) {
                                        ForEach(1...200, id: \.self) { value in
                                            Text("\(value)").tag(value)
                                        }
                                    }
                                    .labelsHidden()
                                    .pickerStyle(WheelPickerStyle())
                                    .frame(maxHeight: 200)

                                    Button("Done") {
                                        isGrainPickerExpanded = false
                                    }
                                    .padding()
                                }
                                .presentationDetents([.fraction(0.35)])
                            }
                        }
                        .frame(height: 116)
                        .frame(maxWidth: .infinity)
                        .background(AppDesign.Colors.neutralB)
                        .cornerRadius(10)
                        .transaction { $0.animation = nil }
                        
                        
                        // Deprecated: Posterize Parameter
                        
                        /*
                        VStack {
                            Text("Posterize")
                                .font(.subheadline)
                                .foregroundColor(AppDesign.Colors.accent2)
                            Toggle("", isOn: Binding(
                                get: { !useGrayscale }, // ✅ Reverse the logic
                                set: { useGrayscale = !$0 } // ✅ Reverse on toggle
                            ))
           Invert                 .labelsHidden()
                        }
                        .frame(height: 116)
                        .frame(maxWidth: .infinity)
                        .background(AppDesign.Colors.neutralB) // ✅ Use centrally managed color for tile backgrounds
                        .cornerRadius(10) */
                        
                        // New Framed Export parameter tile
                        
                    
                        
                        VStack {
                            Text("Invert Color")
                                .font(.subheadline)
                                .foregroundColor(useMulticolor ? AppDesign.Colors.accent2.opacity(0.5) : AppDesign.Colors.accent2)

                            Toggle("", isOn: $invertColor) // Replace with binding when logic is implemented
                                .labelsHidden()
                                .disabled(useMulticolor)
                                .opacity(useMulticolor ? 0.3 : 1.0)
                        }
                        .frame(height: 116)
                        .frame(maxWidth: .infinity)
                        .background(AppDesign.Colors.neutralB.opacity(useMulticolor ? 0.4 : 1.0))
                        .cornerRadius(useMulticolor ? 24 : 10)
                        .transaction { $0.animation = nil }
                        
                        
                        // Drops Color Parameter
                        VStack {
                            Text("Drops Color")
                                .font(.subheadline)
                                .foregroundColor(useMulticolor ? AppDesign.Colors.accent2.opacity(0.5) : AppDesign.Colors.accent2) // ✅ Dim label when disabled

                            ColorPicker("", selection: $dotColor)
                                .labelsHidden()
                                .disabled(useMulticolor) // ✅ Disables when Multicolor mode is active
                                .opacity(useMulticolor ? 0.3 : 1.0) // ✅ Visually indicate when disabled
                        }
                        .frame(height: 116)
                        .frame(maxWidth: .infinity)
                        .background(AppDesign.Colors.neutralB.opacity(useMulticolor ? 0.4 : 1.0)) // ✅ Background fades when disabled
                        .cornerRadius(useMulticolor ? 24 : 10)
                        .transaction { $0.animation = nil }
                        
                        
                        // Print Frame Parameter
                        VStack {
                            Text("Print Frame")
                                .font(.subheadline)
                                .foregroundColor(AppDesign.Colors.accent2)

                            Toggle("", isOn: $framedExport)
                                .labelsHidden()
                        }
                        .frame(height: 116)
                        .frame(maxWidth: .infinity)
                        .background(AppDesign.Colors.neutralB) // ✅ Matches other parameter tiles
                        .cornerRadius(10)
                        .transaction { $0.animation = nil }

                    }
                    .padding(.horizontal)

                    Divider()
                }
                .frame(minHeight: geometry.size.height * 0.9, maxHeight: .infinity, alignment: .top) // ✅ Ensure entire VStack is top-aligned
            }
        }
    }
}
