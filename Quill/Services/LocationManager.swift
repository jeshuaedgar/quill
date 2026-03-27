import Foundation
import CoreLocation
import SwiftUI

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private let manager = CLLocationManager()
    
    var currentLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    // Search results
    var searchResults: [LocationResult] = []
    var isSearching = false
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }
    
    // MARK: - Permissions
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func requestAlwaysPermission() {
        manager.requestAlwaysAuthorization()
    }
    
    func requestLocation() {
        manager.requestLocation()
    }
    
    // MARK: - Location Monitoring
    
    func startMonitoring(for reminder: Reminder) {
        guard let lat = reminder.locationLatitude,
              let lon = reminder.locationLongitude else { return }
        
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let radius = reminder.locationRadius ?? 100
        let identifier = reminder.id.uuidString
        
        let region = CLCircularRegion(
            center: coordinate,
            radius: radius,
            identifier: identifier
        )
        
        region.notifyOnEntry = reminder.triggerOnArrival
        region.notifyOnExit = !reminder.triggerOnArrival
        
        manager.startMonitoring(for: region)
    }
    
    func stopMonitoring(for reminder: Reminder) {
        let identifier = reminder.id.uuidString
        for region in manager.monitoredRegions {
            if region.identifier == identifier {
                manager.stopMonitoring(for: region)
                break
            }
        }
    }
    
    // MARK: - Search
    
    func searchLocations(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(query) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                self?.isSearching = false
                
                if let placemarks = placemarks {
                    self?.searchResults = placemarks.compactMap { placemark in
                        guard let location = placemark.location else { return nil }
                        
                        let name = [
                            placemark.name,
                            placemark.locality,
                            placemark.administrativeArea
                        ].compactMap { $0 }.joined(separator: ", ")
                        
                        return LocationResult(
                            name: name,
                            coordinate: location.coordinate
                        )
                    }
                } else {
                    self?.searchResults = []
                }
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        triggerLocationNotification(for: region, event: "arrived at")
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        triggerLocationNotification(for: region, event: "left")
    }
    
    // MARK: - Location Notification
    
    private func triggerLocationNotification(for region: CLRegion, event: String) {
        let content = UNMutableNotificationContent()
        content.title = "Quill"
        content.body = "You \(event) a reminder location"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "location-\(region.identifier)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Location Result

struct LocationResult: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    
    static func == (lhs: LocationResult, rhs: LocationResult) -> Bool {
        lhs.id == rhs.id
    }
}
