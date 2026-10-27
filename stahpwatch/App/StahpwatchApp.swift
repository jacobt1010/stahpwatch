import SwiftUI

@main
struct StahpwatchApp: App {
    @State private var model = StopwatchModel.shared
    @State private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(model)
                .environment(settings)
        }
    }
}
