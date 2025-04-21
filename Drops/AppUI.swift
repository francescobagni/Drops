import SwiftUI
import UIKit
private let showLiveInvertPreview: Bool = false

struct AppUI: View {
    @StateObject private var viewModel = RasterizationPreviewModel()
    @State private var selectedImage: UIImage? = nil
    @State private var isSheetPresented: Bool = true
    @State private var isImagePickerPresented = false
    @State private var isProcessing: Bool = false
    @State private var progressMessage: String = ""
    @State private var sheetDetent: PresentationDetent = .medium
    @State private var lastSheetDetent: PresentationDetent = .medium
    @State private var zoomState: CGFloat = 1.0
    @State private var isZoomed: Bool = false // Track fullscreen mode
    private let smallDetent: CGFloat = 55
    @State private var maxSize: Int = 1800
    @State private var layers: Int = 4
    @State private var clusterSize: Int = 14
    @State private var dotSizeFactor: CGFloat = 0.5
    @State private var spacing: CGFloat = 5.0
    @State private var intensityAcceleration: CGFloat = 1.0
    @State private var dotColor: Color = .black
    @State private var useGrayscale: Bool = true
    @State private var gamma: CGFloat = 1.5
    @State private var processingProgress: Double = 0.0
    @State private var manager = Manager()
    @State private var selectedSlider: String? = nil
    @AppStorage("fingerLensPulseShown") private var fingerLensPulseShown: Bool = false
    @State private var showPulseHint: Bool = true
    @State private var hasTappedImageInFullscreen: Bool = false
  //  @State private var pulseAnimationID = UUID()
    @State private var showFingerLens = false
    @State private var lensLocation: CGPoint = .zero
    @State private var lensScale: CGFloat = 0.0
    @State private var fingerLensTimerID = UUID()
    
    @State private var lastAppliedMaxSize: Int = 1680
    @State private var lastAppliedLayers: Int = 4
    @State private var lastAppliedClusterSize: Int = 14
    @State private var lastAppliedDotSizeFactor: CGFloat = 0.1
    @State private var lastAppliedSpacing: CGFloat = 5.0
    @State private var lastAppliedIntensityAcceleration: CGFloat = 1.0
    @State private var lastAppliedDotColor: Color = .black
    @State private var lastAppliedUseGrayscale: Bool = true
    @State private var lastAppliedGamma: CGFloat = 1.5
    @State private var lastAppliedUseMulticolor: Bool = false
    @State private var lastAppliedFramedExport: Bool = false
    @State private var lastAppliedInvertColor: Bool = false
    
    @State private var useMulticolor: Bool = true
    @State private var framedExport: Bool = false
    @State private var invertColor: Bool = false
    @StateObject private var pulseHintVM = PulseHintViewModel()
                 init() {
                     fingerLensPulseShown = false // Force it to false each launch
                 }
    private var canShowPulseHint: Bool {
        return showPulseHint
            && !hasTappedImageInFullscreen
            && selectedSlider == nil
            && (viewModel.progress >= 1.0)
    }
    
    private var effectiveDotColor: UIColor {
        if useMulticolor {
            return .black
        }
        let isInverted = invertColor
        return (useGrayscale && isInverted) ? .white : UIColor(dotColor)
    }

    private var effectiveBackgroundColor: UIColor {
        let isInverted = showLiveInvertPreview ? invertColor : lastAppliedInvertColor
        return (useGrayscale && isInverted) ? UIColor(dotColor) : .white
    }

    var body: some View {
        ZStack {
        AppDesign.Colors.neutral
            .edgesIgnoringSafeArea(.all)

            Color.clear
                .contentShape(Rectangle())
                .zIndex(0)
                .allowsHitTesting(true)
                .onTapGesture {
                    withAnimation {
                        if !isZoomed {
                            let wasExpanded = selectedSlider != nil
                            selectedSlider = nil
                            if wasExpanded && hasParametersChanged() {
                                print("🟢 DEBUG: DynamicSlider dismissed by tap — reapplying processing.")
                                applyProcessing()
                            }
                        }
                    }
                }
            
            VStack(alignment: .leading, spacing: 16) {
                Spacer(minLength: 0) // ✅ Pushes sliders down
                if !isZoomed {
                    HStack {
                        if viewModel.rasterizedImage != nil {
                            VStack(spacing: 16) {
                            DynamicSlider(
                                value: $gamma,
                                label: "Shadow",
                               // range: 0.5...3.0,
                                range: sliderRange(for: "Shadow"),
                                step: sliderStep(for: "Shadow"),
                                selectedSlider: $selectedSlider,
                                sheetDetent: $sheetDetent,
                                onParametersChanged: hasParametersChanged,
                                onApplyProcessing: applyProcessing
                            )
                                DynamicSlider(
                                    value: $dotSizeFactor,
                                    label: "Drops Size",
                                    //range: 0.05...0.5,
                                    range: sliderRange(for: "Drops Size"),
                                    step: sliderStep(for: "Drops Size"),
                                    selectedSlider: $selectedSlider,
                                    sheetDetent: $sheetDetent,
                                    onParametersChanged: hasParametersChanged,
                                    onApplyProcessing: applyProcessing
                                )
                                DynamicSlider(
                                    value: $intensityAcceleration,
                                    label: "Contrast",
                                    //range: 0.5...2.0,
                                    range: sliderRange(for: "Contrast"),
                                    step: sliderStep(for: "Contrast"),
                                    selectedSlider: $selectedSlider,
                                    sheetDetent: $sheetDetent,
                                    onParametersChanged: hasParametersChanged,
                                    onApplyProcessing: applyProcessing
                                )
 
                                // ✅ Only show Layers control when Posterization is active
                                if !useGrayscale {
                                    DynamicSlider(
                                        value: Binding(
                                            get: { CGFloat(self.layers) },
                                            set: { self.layers = Int($0) }
                                        ),
                                        label: "Layers",
                                        //range: 2...20,
                                        range: sliderRange(for: "Layers"),
                                        step: sliderStep(for: "Layers"),
                                        selectedSlider: $selectedSlider,
                                        sheetDetent: $sheetDetent,
                                        onParametersChanged: hasParametersChanged,
                                        onApplyProcessing: applyProcessing
                                    )
                                }
                            }
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.05), value: viewModel.rasterizedImage)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                }
                Spacer(minLength: 0)
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .zIndex(10)
            
            // Arc sliders
            if let selected = selectedSlider, !isZoomed { // ✅ Hide ArcSlider when zoomed
                ZStack {
                    GeometryReader { geometry in
                        let vStackCenter = geometry.size.height / 2
                        ArcSlider(value: sliderValue(for: selected), range: sliderRange(for: selected), step:sliderStep(for: selected))
                            .frame(width: 120, height: 120)
                            .position(x: UIScreen.main.bounds.width / 4, y: vStackCenter)
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.05), value: isZoomed)
                            .onTapGesture {
                                            withAnimation {
                                                selectedSlider = nil // ✅ Collapse on tap
                                            }
                                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(11)
            }

            // Dynamic Sliders Labels
            if let selected = selectedSlider, !isZoomed { // ✅ Hide labels when zoomed
                HStack(spacing: 8) {
                    Text(selected)
                        .font(.subheadline)
                        .foregroundColor(AppDesign.Colors.accent)
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .background(AppDesign.Colors.neutral)
                        .clipShape(Capsule())
                        .shadow(color: AppDesign.ComponentStates.dynamicParameterDefault.shadow.color!,
                                radius: AppDesign.ComponentStates.dynamicParameterDefault.shadow.radius)

                }
                .frame(maxWidth: .none)
                .position(x: UIScreen.main.bounds.width / 2, y: 100)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.05), value: isZoomed) // ✅ Smooth fade-out
                .zIndex(10)
            }
           
            // Image Area
            VStack {
                if let finalImage = viewModel.rasterizedImage {
                    GeometryReader { geometry in
                        let imageSize = finalImage.size
                        let screenAspectRatio = geometry.size.width / geometry.size.height
                        let imageAspectRatio = imageSize.width / imageSize.height
                        let fitWidth = screenAspectRatio > imageAspectRatio
                        
                        // 1) Compute margins using the new GoldenRatioFrame method
                        let margins = GoldenRatioFrame.computeMargins(
                            for: finalImage.size,
                            useShortSide: false
                        )

                        // 2) If `framedExport` is false, we zero out the margins
                        let topMargin = framedExport ? margins.top : 0
                        let leftMargin = framedExport ? margins.left : 0
                        let rightMargin = framedExport ? margins.right : 0
                        let bottomMargin = framedExport ? margins.bottom : 0

                        // 3) Create the final image with custom margins
                        let imageWithBackground = finalImage.withPrintFrame(
                            top: topMargin,
                            left: leftMargin,
                            right: rightMargin,
                            bottom: bottomMargin,
                            backgroundColor: effectiveBackgroundColor
                        )
                        
                        ZStack {
                            if isZoomed && showFingerLens {
                                FingerLens(image: imageWithBackground, location: lensLocation)
                                    .scaleEffect(lensScale)
                            }
                            Image(uiImage: imageWithBackground)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(
                                    width: fitWidth ? geometry.size.width * (isProcessing ? 1.0 : zoomState) : nil,
                                    height: fitWidth ? nil : geometry.size.height * (isProcessing ? 1.0 : zoomState)
                                )
                                .clipped()
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                .animation(nil, value: zoomState)
                                .simultaneousGesture(
                                    DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    lensLocation = value.location
                                    let thisGestureID = UUID()
                                    fingerLensTimerID = thisGestureID
                                    
                                    if !isZoomed {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.175) {
                                            if fingerLensTimerID == thisGestureID && lensLocation == value.location {
                                                withAnimation(.easeIn(duration: 0.175)) {
                                                    isZoomed = true
                                                    showFingerLens = true
                                                    isSheetPresented = false
                                                    selectedSlider = nil
                                                    hasTappedImageInFullscreen = true
                                                    pulseHintVM.show = false
                                                    lensScale = 1.0
                                                }
                                            }
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    fingerLensTimerID = UUID()
                                    if isZoomed {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            isZoomed = false
                                            showFingerLens = false
                                            isSheetPresented = true
                                            lensScale = 0.0
                                        }
                                    }
                                }
                                )
                                .simultaneousGesture(
                                    TapGesture()
                                        .onEnded {
                                            print("🟠 Tap detected in image area")
                                            if isZoomed {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    isZoomed = false
                                                    isSheetPresented = true
                                                    showFingerLens = false
                                                }
                                            } else {
                                                let wasExpanded = selectedSlider != nil
                                                selectedSlider = nil
                                                if wasExpanded && hasParametersChanged() {
                                                    print("🟢 DEBUG: Tap in image area — reapplying processing")
                                                    applyProcessing()
                                                }
                                            }
                                        }
                                )
                            // Progress Indicator
                            if isProcessing && viewModel.progress < 1.0 {
                                // compute how finalImage is displayed
                                let (imageOriginX, imageOriginY, fittedWidth, fittedHeight) = ImageLayoutUtil.fittedRect(
                                    imageSize: imageWithBackground.size,
                                    canvasSize: geometry.size
                                )

                                // build the displayedRect from that:
                                let displayedRect = CGRect(
                                    x: imageOriginX,
                                    y: imageOriginY,
                                    width: fittedWidth,
                                    height: fittedHeight
                                )

                                ArcProgressInImage(
                                    progress: CGFloat(viewModel.progress),
                                    lineWidth: 3.0, //AppDesign.PulseHintStyle.lineWidth, // Non-zero value
                                    accentColor: .white, // AppDesign.PulseHintStyle.strokeColor, // Some visible color
                                    boundingRect: displayedRect
                                )
                                .allowsHitTesting(false)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .zIndex(1)

                } else if let rawImage = selectedImage, isProcessing {
                    RawImageView(
                        rawImage: rawImage,
                        progress: $viewModel.progress,
                        isProcessing: isProcessing
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    CenterImageSelectionCTA {
                        print("🟢 DEBUG: Center CTA tapped (fallback)")
                        openImagePicker()
                    }
                    .contentShape(Rectangle()) // Expand tappable area
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if !isZoomed {
                VStack(spacing: 0) {
                    TopBarView(
                        selectedImage: $selectedImage,
                        isProcessing: $isProcessing,
                        processingProgress: $viewModel.progress,
                        isZoomed: isZoomed,
                        isSheetPresented: isSheetPresented,
                        onChooseImage: openImagePicker,
                        onProcessingComplete: {
                            applyProcessing()
                        },
                        onShare: {
                            if let image = viewModel.rasterizedImage {
                                manager.shareImage(image, framedExport: framedExport, dotColor: UIColor(dotColor), useGrayscale: useGrayscale, invertColor: invertColor, dismissSheet: {
                                    isSheetPresented = false
                                    if !isZoomed {
                                        selectedSlider = nil
                                    }
                                }, restoreSheet: {
                                    isSheetPresented = true
                                    sheetDetent = .height(smallDetent)
                                })
                            }
                        },
                        progressMessage: $progressMessage
                    )
                    
                }
                .safeAreaInset(edge: .top) {
                    Color.clear.frame(height: 12)
                }
                .zIndex(10)
                .allowsHitTesting(true)
                .background(Color.clear)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }

            if pulseHintVM.show {
                PulseHint(vm: pulseHintVM)
                // Whenever these states change, recalculate `pulseHintVM.show`
                    .onChange(of: hasTappedImageInFullscreen) { _ in
                        pulseHintVM.show = canShowPulseHint
                    }
                    .onChange(of: showPulseHint) { _ in
                        pulseHintVM.show = canShowPulseHint
                    }
                    .onChange(of: selectedSlider) { _ in
                        pulseHintVM.show = canShowPulseHint
                    }
                    .onChange(of: isProcessing) { _ in
                        pulseHintVM.show = canShowPulseHint
                    }
                    .onChange(of: viewModel.progress) { _ in
                        pulseHintVM.show = canShowPulseHint
                    }
                   // .opacity(pulseHintVM.show ? 1 : 0)
            }
            
        }
        .onChange(of: useMulticolor) { newValue in
            if newValue {
                dotColor = .black
                invertColor = false
            }

            // Recheck parameter changes after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if hasParametersChanged() {
                    print("🟣 DEBUG: Multicolor toggle triggered parameter change — triggering applyProcessing()")
                    applyProcessing()
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { isSheetPresented && !isZoomed },
            set: { newValue in isSheetPresented = newValue }
        ), onDismiss: {
            if !isZoomed { // ✅ Only collapse selectedSlider if not zoomed
                selectedSlider = nil
            }
        }) {
            GeometryReader { geometry in // ✅ Track sheet height in real time
                let sheetHeight = geometry.size.height
                let screenHeight = UIScreen.main.bounds.height
                let sheetPercentage = sheetHeight / screenHeight // ✅ Get the percentage of screen height

                VStack(alignment: .center) {
                    CustomSheetView {
                        CustomSheetContent(
                            useMulticolor: $useMulticolor,
                            maxSize: $maxSize,
                            clusterSize: $clusterSize,
                            useGrayscale: $useGrayscale,
                            dotColor: $dotColor,
                            intensityAcceleration: $intensityAcceleration,
                            dotSizeFactor: $dotSizeFactor,
                            gamma: $gamma,
                            layers: $layers,
                            framedExport: $framedExport, // ✅ Fix: Added missing parameter
                            invertColor: $invertColor
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .transaction { $0.animation = nil }
                .onChange(of: sheetPercentage) { newPercentage in
                    print("🟡 DEBUG: Sheet percentage changed: \(newPercentage * 100)%")
                    if newPercentage < 0.2 || sheetHeight < 100 {
                        print("🟡 DEBUG: Sheet pulled down - Checking parameter changes")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            if hasParametersChanged() {
                                print("🟡 DEBUG: Parameters changed, triggering applyProcessing()")
                                applyProcessing()
                            } else {
                                print("🟢 DEBUG: No parameter changes detected, skipping reprocessing")
                            }
                        }
                    }
                }
            }
            .presentationDetents([
                .height(smallDetent),
                .medium
            ])
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            .presentationBackground(.ultraThinMaterial)
            .interactiveDismissDisabled(true)
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(32)
            .onDisappear {
                print("🟢 DEBUG: Sheet onDisappear triggered — checking parameter changes")
                if hasParametersChanged() {
                    print("🟢 DEBUG: Changes detected on sheet disappear — triggering applyProcessing()")
                    applyProcessing()
                } else {
                    print("🟢 DEBUG: No changes detected on sheet disappear.")
                }
            }
        }
        .sheet(isPresented: $isImagePickerPresented) {
            PHPickerViewControllerRepresentable(selectedImage: $selectedImage)
        }
        .toolbarColorScheme(.light, for: .navigationBar)
    }
    
    
    private func applyProcessing() {
        print("🟡 DEBUG: applyProcessing() function called")
        
        guard let image = selectedImage else {
            print("🔴 ERROR: No image selected, skipping processing")
            return
        }

        DispatchQueue.main.async {
            self.isProcessing = true
            selectedSlider = nil // ✅ Collapse DynamicSlider when applying processing
        }
        
        print("🏳️‍🌈 DEBUG: useMulticolor is set to:", useMulticolor)

        progressMessage = "Processing image..."
        isSheetPresented = true
        let processingStartTime = CFAbsoluteTimeGetCurrent()
        viewModel.processImage(
            image,
            maxSize: maxSize,
            layerCount: layers,
            clusterSize: clusterSize,
            spacing: spacing,
            intensityAcceleration: intensityAcceleration,
            colorAcceleration: 0.1,
            dotSizeFactor: dotSizeFactor,
            dotColor: effectiveDotColor,
            contrastThreshold: 0.015,
            useGrayscale: useGrayscale,
            useMulticolor: useMulticolor,
            gammaValue: gamma,
            invertColor: invertColor,
            progressMessage: $progressMessage,
            completion: {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    if self.selectedImage == nil { // ✅ Prevent infinite loop
                        self.selectedImage = viewModel.rasterizedImage
                    }
                    lastAppliedMaxSize = maxSize
                    lastAppliedLayers = layers
                    lastAppliedClusterSize = clusterSize
                    lastAppliedDotSizeFactor = dotSizeFactor
                    lastAppliedSpacing = spacing
                    lastAppliedIntensityAcceleration = intensityAcceleration
                    lastAppliedDotColor = dotColor
                    lastAppliedUseGrayscale = useGrayscale
                    lastAppliedGamma = gamma
                    lastAppliedUseMulticolor = useMulticolor
                    lastAppliedInvertColor = invertColor
                }
                let processingEndTime = CFAbsoluteTimeGetCurrent()
                let duration = processingEndTime - processingStartTime
                print("⏱️ Total processing time: \(String(format: "%.2f", duration)) seconds")
                print("🔵 [DEBUG] fingerLensPulseShown =", fingerLensPulseShown)
                if fingerLensPulseShown == false {
                    fingerLensPulseShown = true // or remove it, if you want indefinite pulses every time
                    print("🟣 [DEBUG] Scheduling repeated PulseHint...")
                // The first pulse after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        if self.canShowPulseHint {
                            print("🟣 [DEBUG] Triggering PulseHint after delay")
                            self.pulseHintVM.shouldPulse = false // always reset first
                            self.pulseHintVM.show = true

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                print("🟣 [DEBUG] shouldPulse = true (start animation)")
                                self.pulseHintVM.shouldPulse = true
                                self.schedulePulseHintRepeat()
                            }
                        }
                    }
            }
        },
            progressCallback: { fraction in
                DispatchQueue.main.async {
                    viewModel.updateProgressMonotonically(fraction) { finalVal in
                        // Whatever you want to do with finalVal
                        // Possibly nothing at all if you only need monotonic progress
                        print("Updated progress to", finalVal)
                    }
                }
            }
        )
    }
    
    private func schedulePulseHintRepeat(interval: TimeInterval = 7.5) {
        // Schedule a check in `interval` seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            guard self.viewModel.rasterizedImage != nil else {
                print("🔴 [DEBUG] No rasterizedImage found, skipping repeated PulseHint.")
                return
            }
            // If user STILL hasn't tapped the image or opened a slider, show the pulse
            if !self.hasTappedImageInFullscreen && self.selectedSlider == nil {
                print("🔵 [DEBUG] Re-triggering PulseHint after \(interval)s...")
                self.showPulseHintAgain()
            } else {
                print("⚪ [DEBUG] Not showing pulse: user tapped image or slider changed.")
            }
        }
    }

    private func showPulseHintAgain() {
        if canShowPulseHint {
            self.pulseHintVM.show = true
            self.pulseHintVM.shouldPulse = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.pulseHintVM.shouldPulse = true
            }
            schedulePulseHintRepeat()
        }
    }
    

    private func openImagePicker() {
        isImagePickerPresented.toggle()
    }

    private func hasParametersChanged() -> Bool {
        let hasChanged = maxSize != lastAppliedMaxSize ||
                         layers != lastAppliedLayers ||
                         clusterSize != lastAppliedClusterSize ||
                         dotSizeFactor != lastAppliedDotSizeFactor ||
                         spacing != lastAppliedSpacing ||
                         intensityAcceleration != lastAppliedIntensityAcceleration ||
                         (!useMulticolor && dotColor != lastAppliedDotColor) ||
                         useGrayscale != lastAppliedUseGrayscale ||
                         gamma != lastAppliedGamma ||
                         useMulticolor != lastAppliedUseMulticolor ||
                        // framedExport != lastAppliedFramedExport ||
                         invertColor != lastAppliedInvertColor

        
        return hasChanged
    }

    private func updateZoom(for detent: PresentationDetent) {
        withAnimation {
            switch detent {
            case .large:
                zoomState = isZoomed ? 1.1 : 1.1
            case .medium:
                zoomState = isZoomed ? 1.0 : 1.0
            default:
                zoomState = isZoomed ? 1.0 : 1.0
            }
        }
    }
    
    
    private func chooseImageButtonStyle() -> some ButtonStyle {
        let buttonStyle = AppDesign.chooseImageButtonStyle(imageLoaded: selectedImage != nil)
        
        return CustomButtonStyle(config: ButtonStyleConfiguration(
            background: Color.clear, // ✅ Allow background override
            textColor: AppDesign.Colors.accent,
            shadow: AppDesign.ShadowStyles.defaultState
        ))
    }
    
    private func handleSheetDetentChange(_ newDetent: PresentationDetent) {
        DispatchQueue.main.async {
            if let controller = UIApplication.shared.connectedScenes
                .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController?.presentedViewController?.sheetPresentationController })
                .first, controller.selectedDetentIdentifier == .medium {
                
                if hasParametersChanged() {
                    applyProcessing()
                }
            } else {
                self.sheetDetent = newDetent
            }
            self.updateZoom(for: self.sheetDetent)
        }
    }
    
    private func applyButtonStyle() -> some ButtonStyle {
        let state = (isProcessing || selectedImage == nil)
            ? AppDesign.ButtonStates.inactive
            : AppDesign.ButtonStates.defaultState
        return CustomButtonStyle(config: state)
    }

    private func exportButtonStyle() -> some ButtonStyle {
        let state = viewModel.rasterizedImage == nil ? AppDesign.ButtonStates.inactive : AppDesign.ButtonStates.defaultState
        return CustomButtonStyle(config: state)
    }

    private func sliderRange(for label: String) -> ClosedRange<CGFloat> {
        switch label {
        case "Shadow": return 0.5...3.0
        case "Drops Size": return 0.05...2.0
        case "Contrast": return 0.5...2.0
        case "Layers": return 2...20
        default: return 0...1
        }
    }
    
    private func sliderStep(for label: String) -> CGFloat {
        switch label {
        case "Shadow": return 0.1
        case "Drops Size": return 0.01
        case "Contrast": return 0.05
        case "Layers": return 1
        default: return 0.1
        }
    }

    private func sliderValue(for label: String) -> Binding<CGFloat> {
        switch label {
        case "Shadow": return $gamma
        case "Drops Size": return $dotSizeFactor
        case "Contrast": return $intensityAcceleration
        case "Layers": return Binding(
            get: { CGFloat(self.layers) },
            set: { self.layers = Int($0) }
        )
        default: return .constant(0)
        }
    }
}

struct CustomButtonStyle: ButtonStyle {
    let config: ButtonStyleConfiguration

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(
                            Group {
                                if config.background == Color.clear {
                                    AnyView(Rectangle().fill(.ultraThinMaterial)) // ✅ Correctly apply Material
                                } else {
                                    AnyView(config.background) // ✅ Use standard colors when defined
                                }
                            }
                        )
            .foregroundColor(config.textColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(radius: config.shadow.radius)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

extension AppDesign {
    static func chooseImageButtonStyle(imageLoaded: Bool) -> some ButtonStyle {
        let state = imageLoaded
            ? ButtonStyleConfiguration(
                background: Colors.neutralB.opacity(0.9),
                textColor: Colors.accent,
                shadow: ShadowStyles.defaultState
            )
            : ButtonStyleConfiguration(
                background: Colors.accent,
                textColor: Colors.neutral,
                shadow: ShadowStyles.defaultState
            )
        return CustomButtonStyle(config: state)
    }
}

struct AppUI_Previews: PreviewProvider {
    static var previews: some View {
        AppUI()
            .previewDisplayName("Main UI Preview")
            .preferredColorScheme(.dark)
    }
}
