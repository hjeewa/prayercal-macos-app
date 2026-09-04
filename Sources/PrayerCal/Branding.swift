import AppKit
import SwiftUI

struct PrayerCalBrand: View {
    var compact = false
    var scale: CGFloat = 1

    var body: some View {
        HStack(spacing: (compact ? 8 : 12) * scale) {
            brandIcon
                .frame(width: (compact ? 30 : 48) * scale, height: (compact ? 30 : 48) * scale)

            VStack(alignment: .leading, spacing: 0) {
                Text("PrayerCal")
                    .font(compact ? .headline : .system(size: 20 * scale, weight: .bold))
                if !compact {
                    Text("Organise your day around your prayers")
                        .font(.system(size: 12 * scale))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var brandIcon: some View {
        if let url = Bundle.main.url(forResource: "PrayerCalIcon", withExtension: "svg"),
           let image = NSImage(contentsOf: url) {
            Image(nsImage: image).resizable().scaledToFit()
        } else {
            RoundedRectangle(cornerRadius: compact ? 8 : 13)
                .fill(Color(red: 0.584, green: 0.271, blue: 0.820))
        }
    }
}
