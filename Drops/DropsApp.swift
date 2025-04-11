import SwiftUI

@main
struct DropsApp: App {
    let persistenceController = Persistence.shared // Updated reference

    var body: some Scene {
        WindowGroup {
            AppUI() // Use RasterizationPreview as main UI
                .environmentObject(persistenceController)
                .preferredColorScheme(.light) // Force Light Mode
        }
    }
}
