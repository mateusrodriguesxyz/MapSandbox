//
//  ObservableLocationManager.swift
//  MapSandbox
//
//  Created by Mateus Rodrigues on 26/11/23.
//

import MapKit

final class ObservableLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private let locationManager = CLLocationManager()
    
    static let defaultDistance: CLLocationDistance = 1000000
    
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 42.0422448, longitude: -102.0079053),
        latitudinalMeters: ObservableLocationManager.defaultDistance,
        longitudinalMeters: ObservableLocationManager.defaultDistance
    )
    
    override init() {
        super.init()
        
        locationManager.delegate = self
    }
    
    func updateLocation() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        DispatchQueue.main.async {
            self.region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: Self.defaultDistance,
                longitudinalMeters: Self.defaultDistance
            )
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}
