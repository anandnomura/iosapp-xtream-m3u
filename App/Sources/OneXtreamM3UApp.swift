import SwiftUI

@main
struct OneXtreamM3UApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: RootViewModel())
                .preferredColorScheme(.dark)
                .tint(Color(red: 0.33, green: 0.96, blue: 0.86))
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .inactive || newPhase == .background {
                NotificationCenter.default.post(name: .emergencyStopPlayback, object: nil)
            }
        }
    }
}
