//
//  ContentView.swift
//  MapSandbox
//
//  Created by Mateus Rodrigues on 21/11/23.
//

import SwiftUI
import MapKit
import Combine

//struct MapClusterizer<Content: View, Item>: View where Item: MapLocationClusterable {
//    
//    @Binding var coordinateRegion: MKCoordinateRegion
//    
//    let annotationItems: [Item]
//    
//    @ViewBuilder var content: (Binding<[MapLocationCluster<Item>]>) -> Content
//    
//    @State private var clusters: [MapLocationCluster<Item>] = []
//    
//    private let mapSpanLatitudeDeltaDidChange = PassthroughSubject<CLLocationDegrees, Never>()
//   
//    var body: some View {
//        content($clusters)
//            .onChange(of: coordinateRegion.span.latitudeDelta) { _ in
//                mapSpanLatitudeDeltaDidChange.send(coordinateRegion.span.latitudeDelta)
//            }
//            .onReceive(mapSpanLatitudeDeltaDidChange.debounce(for: 0.1, scheduler: RunLoop.main)) { newValue in
//                clusters = annotationItems.clusterize(region: coordinateRegion)
//            }
//            .onAppear {
//                clusters = annotationItems.clusterize(region: coordinateRegion)
//            }
//    }
//    
//}

struct ContentView: View {
    
    @StateObject var locationManager = ObservableLocationManager()
    
    @State var places: [Place] = [
        Place(id: 0, location: CLLocationCoordinate2D(latitude: 51.46835549272785, longitude: -0.03750000000003133)),
        Place(id: 1, location: CLLocationCoordinate2D(latitude: 51.457013659530155, longitude: -0.14905556233727052)),
        Place(id: 2, location: CLLocationCoordinate2D(latitude: 51.44401205914533, longitude: -0.005055562337271016)),
        Place(id: 3, location: CLLocationCoordinate2D(latitude: 51.4276908863969, longitude: -0.10683333333336441)),
        Place(id: 4, location: CLLocationCoordinate2D(latitude: 51.29601501405658, longitude: -0.22550000000003068)),
    ]
    
    @State var clusters: [MapLocationCluster<Place>] = []
    
    @State var mapSpanDistance: Double = 0
        
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
    
    let mapSpanLatitudeDeltaDidChange = PassthroughSubject<CLLocationDegrees, Never>()
    
    var body: some View {
        
        Map(coordinateRegion: $region, annotationItems: clusters) { cluster in
            MapAnnotation(coordinate: cluster.center) {
                Circle()
                    .fill(.orange)
                    .frame(width: 30, height: 30)
                    .overlay {
                        if cluster.values.count > 1 {
                            Text(cluster.values.count.formatted())
                                .bold()
                        }
                    }
                    .onTapGesture {
                        withAnimation {
                            region.center = cluster.center
                            region.span = .init(latitudeDelta: region.span.latitudeDelta/2, longitudeDelta: region.span.longitudeDelta/2)
                        }
                    }
            }
        }
        .modifier(
            OnMapTapGesture(region: region) { location in
                places.append(.init(id: places.count, location: location))
                clusters = places.clusterize(region: region)
            }
        )
        .onChange(of: region.span.latitudeDelta) { _ in
            mapSpanLatitudeDeltaDidChange.send(region.span.latitudeDelta)
        }
        .onReceive(mapSpanLatitudeDeltaDidChange.debounce(for: 0.1, scheduler: RunLoop.main)) { newValue in
            clusters = places.clusterize(region: region)
        }
        .onAppear {
            clusters = places.clusterize(region: region)
        }
        .ignoresSafeArea(.container, edges: .top)
    }
    
}

#Preview {
    ContentView()
}
