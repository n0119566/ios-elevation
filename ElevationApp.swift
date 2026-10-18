import SwiftUI

@main
struct ElevationApp: App {
    // Single source of truth for location, injected into the environment.
    @State private var locationService = LocationService()
    @AppStorage("appearance") private var appearance = "light"

    var body: some Scene {
        WindowGroup {
            ElevationView()
                .environment(locationService)
                .preferredColorScheme(appearance == "dark" ? .dark : .light)
        }
    }
}
