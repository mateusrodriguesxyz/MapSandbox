//
//  ContentView.swift
//  MapSandbox
//
//  Created by Mateus Rodrigues on 21/11/23.
//

import SwiftUI
import MapKit
import CoreLocation


struct Place: Identifiable {
    
    let id: Int
    let location: CLLocationCoordinate2D
    
    func distance(to other: Place) -> Double {
        let p1 = CLLocation(latitude: self.location.latitude, longitude: self.location.longitude)
        let p2 = CLLocation(latitude: other.location.latitude, longitude: other.location.longitude)
        let distance = p2.distance(from: p1)
        return distance
    }
    
}

extension Place: Equatable {
    static func == (lhs: Place, rhs: Place) -> Bool {
        lhs.id == rhs.id
    }
}

extension Place: MapLocationClusterable { }

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


struct ContentView: View {
    
    @StateObject var locationManager = ObservableLocationManager()
    
    @State var places: [Place] = []
    
    @State var clusters: [MapLocationCluster<Place>] = []
    
    @State var mapCameraDistance: Double = 0
    
    @State private var coordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
            
    var body: some View {
        TabView {
            
            GeometryReader { proxy in
                Map(coordinateRegion: $coordinateRegion, annotationItems: places) { place in
                    MapMarker(coordinate: place.location)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { gesture in
                            let location = convertTap(
                                at: gesture.location,
                                for: proxy.size)
                            places.append(.init(id: places.count, location: location))
                        }
                    
                )
                .highPriorityGesture(DragGesture(minimumDistance: .greatestFiniteMagnitude))
            }
            .ignoresSafeArea(.container, edges: .top)
            .tabItem { Text("iOS 16") }
            
            if #available(iOS 17, *) {
                MapReader { reader in
                    Map(initialPosition: .userLocation(fallback: .automatic)) {
                        
                        if !clusters.isEmpty {
                            ForEach(clusters) { cluster in
                                
                                let center = cluster.center
                                
                                if cluster.values.count == 1 {
                                    Marker("", coordinate: center)
                                } else {
                                    Marker("", monogram: Text("\(cluster.values.count)"), coordinate: center)
                                }
                                
                            }
                        } else {
                            ForEach(places) { place in
                                Marker("", coordinate: place.location)
                            }
                        }
                        
                    }
                    .onMapCameraChange { context in
                
                        let newMapCameraDistance = context.camera.distance
                        
                        
                        if newMapCameraDistance != mapCameraDistance {
                            mapCameraDistance = newMapCameraDistance
                            clusters = places.clusterize(distance: mapCameraDistance/50)
                        }
                        
                        let loc1 = CLLocation(latitude: context.region.center.latitude - context.region.span.latitudeDelta, longitude: context.region.center.longitude)
                        let loc2 = CLLocation(latitude: context.region.center.latitude + context.region.span.latitudeDelta, longitude: context.region.center.longitude)
                        
                        print("span distance:", Measurement(value: loc1.distance(from: loc2), unit: UnitLength.meters).formatted())
                        
                        print("camera distance", Measurement(value: newMapCameraDistance, unit: UnitLength.meters).formatted())

                        
                    }
                    .onTapGesture {
                        if let location = reader.convert($0, from: .local) {
                            places.append(.init(id: places.count, location: location))
                        }
                    }
                }
                .tabItem { Text("iOS 17").background(.red) }
            }
            
            
        }
    }
    
    func convertTap(at point: CGPoint, for mapSize: CGSize) -> CLLocationCoordinate2D {
            
            let lat = coordinateRegion.center.latitude
            let lon = coordinateRegion.center.longitude
            
            let mapCenter = CGPoint(x: mapSize.width/2, y: mapSize.height/2)
            
            // X
            let xValue = (point.x - mapCenter.x) / mapCenter.x
            let xSpan = xValue * coordinateRegion.span.longitudeDelta/2
            
            // Y
            let yValue = (point.y - mapCenter.y) / mapCenter.y
            let ySpan = yValue * coordinateRegion.span.latitudeDelta/2
            
            return CLLocationCoordinate2D(latitude: lat - ySpan, longitude: lon + xSpan)
    }
    
}

#Preview {
    ContentView()
}
