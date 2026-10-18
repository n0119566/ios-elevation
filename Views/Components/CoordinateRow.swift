import CoreLocation
import SwiftUI

/// Latitude / longitude shown beneath the elevation.
struct CoordinateRow: View {
    let coordinate: CLLocationCoordinate2D

    var body: some View {
        HStack(spacing: 20) {
            Text(Formatters.latitude(coordinate))
            Text(Formatters.longitude(coordinate))
        }
        .font(.system(.body, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Latitude \(Formatters.latitude(coordinate)), longitude \(Formatters.longitude(coordinate))"
        )
    }
}

#Preview {
    CoordinateRow(coordinate: .init(latitude: 37.7749, longitude: -122.4194))
}
