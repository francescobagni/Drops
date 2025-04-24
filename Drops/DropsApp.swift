
import SwiftUI
struct TouchPoint: Identifiable {
   let id = UUID()
   let location: CGPoint
   var opacity: Double = 1.0
   var scale: CGFloat = 1.0
}

struct TouchFeedbackOverlay: View {
   @Binding var touchPoints: [TouchPoint]

   var body: some View {
       ZStack {
           ForEach(touchPoints) { point in
               Circle()
                   .fill(Color.white.opacity(0.3))
                   .frame(width: 80, height: 80)
                   .position(point.location)
                   .scaleEffect(point.scale, anchor: .center)
                   .opacity(point.opacity)
                   .animation(.easeOut(duration: 0.5), value: point.opacity)
           }
       }
       .allowsHitTesting(false)
   }
}

struct TouchOverlayContainer<Content: View>: View {
   @State private var touchPoints: [TouchPoint] = []
   let content: () -> Content

   var body: some View {
       ZStack {
           content()
               .simultaneousGesture(
                   DragGesture(minimumDistance: 0)
                       .onEnded { value in
                           let newPoint = TouchPoint(location: value.location)
                           touchPoints.append(newPoint)
                           DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                               if let index = touchPoints.firstIndex(where: { $0.id == newPoint.id }) {
                                   withAnimation(.easeOut(duration: 0.15)) {
                                       touchPoints[index].opacity = 0.0
                                       touchPoints[index].scale = 1.0
                                   }
                                   DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                       if let finalIndex = touchPoints.firstIndex(where: { $0.id == newPoint.id }) {
                                           touchPoints.remove(at: finalIndex)
                                       }
                                   }
                               }
                           }
                       }
               )
           TouchFeedbackOverlay(touchPoints: $touchPoints)
       }
   }
}

@main
struct DropsApp: App {
    let persistenceController = Persistence.shared // Updated reference

    var body: some Scene {
        WindowGroup {
          /*  TouchOverlayContainer {
                AppUI()
                    .environmentObject(persistenceController)
                    .preferredColorScheme(.dark)
            } */
            AppUI()
                .environmentObject(persistenceController)
                .preferredColorScheme(.dark)
        }
    }
}

