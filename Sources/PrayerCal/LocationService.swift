@preconcurrency import CoreLocation
import Foundation
import Observation

@MainActor
@Observable
final class LocationService: NSObject, @preconcurrency CLLocationManagerDelegate {
    var isLocating = false
    var errorMessage: String?
    private let manager = CLLocationManager()
    private var prayerStore: PrayerStore?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func locate(for store: PrayerStore) {
        prayerStore = store
        errorMessage = nil
        isLocating = true
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func selectCity(_ query: String, for store: PrayerStore) {
        let city = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !city.isEmpty else {
            errorMessage = "Enter a city or town."
            return
        }
        errorMessage = nil
        isLocating = true
        Task {
            do {
                guard let placemark = try await CLGeocoder().geocodeAddressString(city).first,
                      let location = placemark.location else {
                    throw CLError(.geocodeFoundNoResult)
                }
                let placeParts = [placemark.locality, placemark.administrativeArea, placemark.country]
                    .compactMap { $0 }
                    .reduce(into: [String]()) { result, part in
                        if !result.contains(part) { result.append(part) }
                    }
                store.setLocation(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    name: placeParts.isEmpty ? city : placeParts.joined(separator: ", "),
                    timeZone: placemark.timeZone
                )
                isLocating = false
            } catch {
                isLocating = false
                errorMessage = "That city could not be found. Try including the country."
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        isLocating = false
        Task {
            let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first
            let placeParts = [placemark?.locality, placemark?.country].compactMap { $0 }
            prayerStore?.setLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                name: placeParts.isEmpty ? "Current location" : placeParts.joined(separator: ", "),
                timeZone: placemark?.timeZone
            )
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLocating = false
        errorMessage = "Location could not be determined. Search for your city instead."
    }
}
