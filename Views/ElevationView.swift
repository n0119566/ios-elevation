import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Root screen. Switches presentation on `LocationService.state`.
struct ElevationView: View {
    @Environment(LocationService.self) private var location
    @State private var unit: ElevationUnit = .localeDefault
    @AppStorage("appearance") private var appearance = "light"

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            content
            Spacer()
            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .overlay(alignment: .topTrailing) {
            appearanceToggle
                .padding(20)
        }
        .onAppear { location.start() }
    }

    @ViewBuilder
    private var content: some View {
        switch location.state {
        case .active, .acquiring, .idle, .requestingPermission:
            // Show a reading as soon as we have one, regardless of the exact phase;
            // otherwise show the acquiring indicator.
            if let reading = location.latestReading {
                self.reading(reading)
            } else {
                acquiring
            }
        case .denied:
            message(
                title: "Location Access Needed",
                body: "Enable location access in Settings to see your elevation and coordinates.",
                showSettings: true
            )
        case .restricted:
            message(
                title: "Location Restricted",
                body: "Location access is restricted on this device.",
                showSettings: false
            )
        case .unavailable:
            message(
                title: "Location Unavailable",
                body: "Location services aren't available right now.",
                showSettings: false
            )
        }
    }

    @ViewBuilder
    private func reading(_ reading: ElevationReading) -> some View {
        VStack(spacing: 20) {
            BigNumberView(
                valueText: Formatters.elevationValue(meters: reading.altitudeMeters, unit: unit),
                unitLabel: unit.shortLabel
            )
            CoordinateRow(coordinate: reading.coordinate)
        }
        .contentShape(Rectangle())
        .onTapGesture { toggleUnit() }
    }

    private var acquiring: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Locating…")
                .font(.system(.title3, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    private func message(title: String, body: String, showSettings: Bool) -> some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.system(.title2, design: .rounded).weight(.semibold))
            Text(body)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if showSettings {
                Button("Open Settings") { openSettings() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal, 40)
    }

    private var footer: some View {
        Text("Tap to switch units")
            .font(.caption2)
            .foregroundStyle(.quaternary)
            .padding(.bottom, 12)
            .opacity(location.latestReading == nil ? 0 : 1)
    }

    private var appearanceToggle: some View {
        Button {
            appearance = appearance == "dark" ? "light" : "dark"
        } label: {
            Image(systemName: appearance == "dark" ? "sun.max.fill" : "moon.fill")
                .frame(width: 20, height: 20)
        }
        .buttonStyle(.bordered)
        .clipShape(Circle())
        .accessibilityLabel(appearance == "dark" ? "Switch to light mode" : "Switch to dark mode")
    }

    private func toggleUnit() {
        unit = (unit == .feet) ? .meters : .feet
    }

    private func openSettings() {
        #if canImport(UIKit)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }
}

#Preview {
    ElevationView()
        .environment(LocationService())
}
