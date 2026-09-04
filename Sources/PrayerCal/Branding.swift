import SwiftUI

struct PrayerCalBrand: View {
    var compact = false

    var body: some View {
        HStack(spacing: compact ? 8 : 12) {
            ZStack {
                RoundedRectangle(cornerRadius: compact ? 8 : 13)
                    .fill(LinearGradient(colors: [Color(red: 0.55, green: 0.35, blue: 0.86), Color(red: 0.32, green: 0.23, blue: 0.66)], startPoint: .topLeading, endPoint: .bottomTrailing))
                Image(systemName: "moon.stars.fill")
                    .foregroundStyle(.white)
                    .font(compact ? .body : .title)
            }
            .frame(width: compact ? 30 : 48, height: compact ? 30 : 48)

            VStack(alignment: .leading, spacing: 0) {
                Text("PrayerCal")
                    .font(compact ? .headline : .title2.weight(.bold))
                if !compact {
                    Text("Organise your day around your prayers")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
