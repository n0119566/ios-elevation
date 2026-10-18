import SwiftUI

@main
struct ElevationApp: App {
    // Single source of truth for location, injected into the environment.
    @State private var locationService = LocationService()

    var body: some Scene {
        WindowGroup {
            ElevationView()
                .environment(locationService)
        }
    }
}
