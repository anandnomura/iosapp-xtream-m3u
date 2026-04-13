import SwiftUI

@main
struct OneXtreamM3UApp: App {
    var body: some Scene {
        WindowGroup {
            RootView(viewModel: RootViewModel())
                .preferredColorScheme(.dark)
                .tint(Color(red: 0.33, green: 0.96, blue: 0.86))
        }
    }
}
