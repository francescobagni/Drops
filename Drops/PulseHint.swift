import SwiftUI

class PulseHintViewModel: ObservableObject {
    @Published var show: Bool = false
    @Published var shouldPulse: Bool = false
}

struct PulseHint: View {
    @ObservedObject var vm: PulseHintViewModel

    @State private var scale: CGFloat = 0.4
    @State private var opacity: Double = 0.55
    @State private var centerScale: CGFloat = 0.7
    @State private var centerOpacity: Double = 0.70

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    AppDesign.PulseHintStyle.strokeColor.opacity(opacity),
                    lineWidth: AppDesign.PulseHintStyle.lineWidth
                )
                .frame(width: 80, height: 80)
                .scaleEffect(scale)

            Circle()
                .fill(
                    AppDesign.PulseHintStyle.fillColor.opacity(centerOpacity)
                )
                .frame(width: 60, height: 60)
                .scaleEffect(centerScale)
        }
        .opacity(vm.show ? 1 : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .zIndex(999)
        .allowsHitTesting(false)
        .onChange(of: vm.shouldPulse) { newValue in
            print("🟡 DEBUG: vm.shouldPulse changed to:", newValue)
            if newValue {
                print("🚀 PulseHint: startAnimation triggered via .onChange")
                centerScale = 0.7
                centerOpacity = 0.0
                startAnimation()
            }
        }
        .onAppear {
            print("🟢 [DEBUG] PulseHint view appeared on screen. vm.show = \(vm.show)")
        }
    }

    private func startAnimation() {

        // Reset to initial state
        scale = 0.4
        opacity = 0.0
        centerScale = 0.7
        centerOpacity = 0.0

        // Outer circle - the FingerLens hint
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 1) Animate to scale 2.0
            withAnimation(Animation.easeOut(duration: 0.15)) {
                scale = 2.0
                opacity = 1.0
            }
            // 2) Optionally hold at 2.0 for 0.5s
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.00) {
                // 3) Then either fade it out or move to the next scale:
                withAnimation(Animation.easeOut(duration: 0.55)) {
                    scale = 1.9 // or 3.0 if you want it bigger
                    opacity = 0.0
                }
            }
        }
            
        // Inner solid circle - the Tap hint
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {
            // 1) Animate to scale 2.0
            withAnimation(Animation.easeOut(duration: 0.5)) {
                centerScale = 1.0
                centerOpacity = 1.0
            }
            // 2) Optionally hold at 2.0 for 0.5s
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // 3) Then either fade it out or move to the next scale:
                withAnimation(Animation.easeOut(duration: 0.25)) {
                    centerScale = 1.15
                    centerOpacity = 0.0
                }
            }
        }
    }
}

