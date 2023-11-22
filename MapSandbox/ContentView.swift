//
//  ContentView.swift
//  MapSandbox
//
//  Created by Mateus Rodrigues on 21/11/23.
//

import SwiftUI
import MapKit

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

struct ContentView: View {
    
    @State var places: [Place] = []
    
    var body: some View {
        NavigationStack {
            MapReader { reader in
                Map {
                    ForEach(places) { place in
                        Marker(place.id.formatted(), coordinate: place.location)
                    }
                }
                .onMapCameraChange{ context in
//                    print(context.region.span)
                }
                .onTapGesture {
                    if let location = reader.convert($0, from: .local) {
                        places.append(.init(id: places.count, location: location))
                    }
                }
                .onChange(of: places.count) {
                    guard places.count > 1 else { return }
                    for place in places {
                        let reference = places[0]
                        let p1 = CLLocation(latitude: reference.location.latitude, longitude: reference.location.longitude)
                        let p2 = CLLocation(latitude: place.location.latitude, longitude: place.location.longitude)
                        let distance = Measurement(value: p2.distance(from: p1), unit: UnitLength.meters)
                        print(distance.formatted())
                        
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button("Group") {
                        
                        let threshold = 50.0
                        
                        var places = self.places
                        
                        var clusters: [[Place]] = []
                        
                        while !places.isEmpty {
                            
                            let p = places.removeFirst()
                            
                            var cluster = [p]
                            
                            for place in places {
                                if place.distance(to: p) < threshold {
                                    cluster.append(place)
                                    if let index = places.firstIndex(where: { $0.id == place.id }) {
                                        places.remove(at: index)
                                    }
                                }
                            }
                            
                            clusters.append(cluster)
                            
                        }
                        
                        print(clusters.count)
                        
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
