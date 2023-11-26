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

struct MKMarkerAnnotationViewRepresentable: UIViewRepresentable {
    
    var glyphText: String?
    
    func makeUIView(context: Context) -> MKMarkerAnnotationView {
        let uiView = MKMarkerAnnotationView(annotation: nil, reuseIdentifier: nil)
        uiView.glyphText = glyphText
        return uiView
    }
    
    func updateUIView(_ uiView: MKMarkerAnnotationView, context: Context) {
        uiView.glyphText = glyphText
        DispatchQueue.main.async {
            print(uiView.frame)
            uiView.frame.origin = .init(x: 0, y: -uiView.frame.midY/2)
        }

    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: MKMarkerAnnotationView, context: Context) -> CGSize? {
        uiView.frame.size
    }
        
}

import Combine

struct OnMapTapGesture: ViewModifier {
    
    let region: MKCoordinateRegion
    
    let perform: (CLLocationCoordinate2D) -> Void
    
    func body(content: Content) -> some View {
        GeometryReader { proxy in
            content
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.25)
                        .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
                        .onEnded { value in
                            switch value {
                                case .second(true, let gesture):
                                    let location = mapLocation(at: gesture?.location ?? .zero, for: proxy.size)
                                    perform(location)
                                default:
                                    break
                            }
                            
                        }
                )
                .highPriorityGesture(
                    DragGesture(minimumDistance: .greatestFiniteMagnitude)
                )
        }
    }
    
    private func mapLocation(at point: CGPoint, for mapSize: CGSize) -> CLLocationCoordinate2D {
        
        let lat = region.center.latitude
        let lon = region.center.longitude
        
        let mapCenter = CGPoint(x: mapSize.width/2, y: mapSize.height/2)
        
        let xValue = (point.x - mapCenter.x) / mapCenter.x
        let xSpan = xValue * region.span.longitudeDelta/2
        
        let yValue = (point.y - mapCenter.y) / mapCenter.y
        let ySpan = yValue * region.span.latitudeDelta/2
        
        return CLLocationCoordinate2D(latitude: lat - ySpan, longitude: lon + xSpan)
    }
    
}

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
        TabView {
            NavigationStack {
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
            }
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
            .tabItem {
                Text("iOS 16")
            }
            
            if #available(iOS 17, *) {
                MapReader { reader in
                    Map(initialPosition: .userLocation(fallback: .automatic)) {
                        ForEach(clusters) { cluster in
                            if cluster.values.count == 1 {
                                Marker("", coordinate: cluster.center)
                            } else {
                                Marker("", monogram: Text("\(cluster.values.count)"), coordinate: cluster.center)
                            }
                        }
                    }
                    .onMapCameraChange { context in
                        clusters = places.clusterize(region: context.region)
                    }
                    .onTapGesture(count: 2) {
                        if let location = reader.convert($0, from: .local) {
                            places.append(.init(id: places.count, location: location))
                            clusters = places.clusterize(distance: mapSpanDistance/50)
                        }
                    }
                }
                .tabItem {
                    Text("iOS 17")
                }
            }
            
            
        }
    }
    
}

#Preview {
    ContentView()
}
