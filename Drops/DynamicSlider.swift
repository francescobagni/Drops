import SwiftUI

struct DynamicSlider: View {
    @Binding var value: CGFloat
    let label: String
    let range: ClosedRange<CGFloat>
    let step: CGFloat
    @Binding var selectedSlider: String?
    @Binding var sheetDetent: PresentationDetent // ✅ Use SwiftUI's built-in PresentationDetent
    
    // ✅ Closure-based approach to call `hasParametersChanged()` and `applyProcessing()`
    var onParametersChanged: () -> Bool
    var onApplyProcessing: () -> Void
    
    var isExpanded: Bool {
        selectedSlider == label
    }

    var progress: CGFloat {
        (value - range.lowerBound) / (range.upperBound - range.lowerBound) // ✅ Normalize value for Arc representation
    }

    var body: some View {
        ZStack {
            // ✅ Background to detect taps outside
            if isExpanded {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            selectedSlider = nil
                            sheetDetent = .height(SheetController.smallestSheetDetent)
                        }
                    }
            }

            Button(action: {
                withAnimation {
                    if selectedSlider == label {
                        selectedSlider = nil // ✅ Collapse on second tap
                       // sheetDetent = .height(SheetController.smallestSheetDetent)
                    } else {
                        selectedSlider = label // ✅ Expand on first tap
                        sheetDetent = .height(SheetController.smallestSheetDetent)
                    }
                }
            }) {
                ZStack {
                    // ✅ Keep background the same for both states
                    Circle()
                        .fill(AppDesign.ComponentStates.dynamicParameterDefault.background) // ✅ Match default background
                        .frame(width: 44, height: 44)
                        .shadow(color: AppDesign.ComponentStates.dynamicParameterDefault.shadow.color!,
                                radius: AppDesign.ComponentStates.dynamicParameterDefault.shadow.radius) // ✅ Match default shadow

                    // ✅ White ArcShape Representation of Value (Mimics ArcSlider)
                    ArcShape()
                        .trim(from: 0, to: progress) // ✅ Correct way to map progress to arc
                        .stroke(Color.white, lineWidth: 2) // ✅ Thin white arc
                        .frame(width: 40, height: 40) // ✅ Slightly smaller than the circle
                        .rotationEffect(.degrees(0)) // ✅ Align with ArcSlider

                    // ✅ Icon in Default State, Numeric Value in Expanded State
                    if isExpanded {
                        if label == "Layers" {
                            Text("\(Int(value))")
                                .font(.headline)
                                .foregroundColor(AppDesign.Colors.accent)
                        } else if label == "Focus" || label == "Contrast" {
                            let fullValue = String(format: "%.2f", value)
                            let basePart = String(fullValue.prefix(3)) // e.g., "0.05"
                            let lastDigit = String(fullValue.suffix(1)) // e.g., "5"

                            HStack(alignment: .top, spacing: 0) {
                                Text(basePart)
                                    .font(.headline)
                                Text(lastDigit)
                                    .font(.caption2)
                                    .baselineOffset(5)
                            }
                            .foregroundColor(AppDesign.Colors.accent)
                        } else {
                            Text(String(format: "%.1f", value))
                                .font(.headline)
                                .foregroundColor(AppDesign.Colors.accent)
                        }
                    } else {
                        Image(systemName: iconForParameter(label)) // ✅ Show icon when collapsed
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(AppDesign.Colors.accent)
                    }
                }
            }
            .zIndex(1)
        }
       .frame(width: 64, height: 54)
        
       .onChange(of: selectedSlider) { newValue in
           if newValue == nil { // ✅ Detect when exiting expanded state
               print("🟡 DEBUG: Dynamic Slider collapsed - Checking parameter changes")
               if onParametersChanged() {
                   print("🟡 DEBUG: Parameters changed, triggering applyProcessing()")
                   onApplyProcessing()
               } else {
                   print("🟢 DEBUG: No parameter changes detected, skipping reprocessing")
               }
           }
       }
        
        .opacity(selectedSlider == nil || selectedSlider == label ? 1.0 : 0.35)
        .animation(Animation.easeInOut(duration: 0.1), value: selectedSlider)
    }
    
    private func iconForParameter(_ label: String) -> String {
        switch label {
        case "Shadow":
            return "swirl.circle.righthalf.filled"
        case "Drops Size":
            return "circle.circle" //smallcircle.filled.circle.fill"
        case "Contrast":
            return "circle.righthalf.filled"
        case "Layers":
            return "square.3.layers.3d.down.forward"
        default:
            return "circle"
        }
    }
}
