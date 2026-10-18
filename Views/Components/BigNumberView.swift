import SwiftUI

/// The hero: a very large, bold elevation number with its unit.
struct BigNumberView: View {
    let valueText: String
    let unitLabel: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(valueText)
                .font(.system(size: 120, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.3)
                .lineLimit(1)
                .contentTransition(.numericText())
                .animation(.snappy, value: valueText)

            Text(unitLabel)
                .font(.system(size: 34, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Elevation \(valueText) \(unitLabel)")
    }
}

#Preview {
    BigNumberView(valueText: "1,234", unitLabel: "ft")
}
