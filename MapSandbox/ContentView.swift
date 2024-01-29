import MapClusterizer
import MapKit
import SwiftUI

struct Place: Identifiable {
        let id: Int
  let location: CLLocationCoordinate2D
}

extension Place: Equatable {
  static func == (lhs: Place, rhs: Place) -> Bool {
    lhs.id == rhs.id
  }
}

extension Place: MapClusterable {}

struct ContentView: View {

  @State var places: [Place] = [
    Place(
      id: 0,
      location: CLLocationCoordinate2D(latitude: 51.46835549272785, longitude: -0.03750000000003133)
    ),
    Place(
      id: 1,
      location: CLLocationCoordinate2D(
        latitude: 51.457013659530155, longitude: -0.14905556233727052)),
    Place(
      id: 2,
      location: CLLocationCoordinate2D(
        latitude: 51.44401205914533, longitude: -0.005055562337271016)),
    Place(
      id: 3,
      location: CLLocationCoordinate2D(latitude: 51.4276908863969, longitude: -0.10683333333336441)),
    Place(
      id: 4,
      location: CLLocationCoordinate2D(latitude: 51.29601501405658, longitude: -0.22550000000003068)
    ),
    Place(
      id: 5,
      location: CLLocationCoordinate2D(
        latitude: 51.451230325076104, longitude: -0.05479938667257798)),
    Place(
      id: 6,
      location: CLLocationCoordinate2D(
        latitude: 51.447904923515644, longitude: -0.05848164847878582)),
    Place(
      id: 7,
      location: CLLocationCoordinate2D(
        latitude: 51.44924581124163, longitude: -0.055243032673325906)),
    Place(
      id: 8,
      location: CLLocationCoordinate2D(latitude: 51.4458131386631, longitude: -0.05510993887310153)),
    Place(
      id: 9,
      location: CLLocationCoordinate2D(latitude: 51.44901786032822, longitude: -0.05191568766771642)
    ),
    Place(
      id: 10,
      location: CLLocationCoordinate2D(
        latitude: 51.44636290263075, longitude: -0.050740025765734394)),
    Place(
      id: 11,
      location: CLLocationCoordinate2D(
        latitude: 51.44437838879629, longitude: -0.059368940480281684)),
    Place(
      id: 12,
      location: CLLocationCoordinate2D(
        latitude: 51.46316907203089, longitude: -0.062202315908290694)),
    Place(
      id: 13,
      location: CLLocationCoordinate2D(latitude: 51.46386007767055, longitude: -0.06478694881840592)
    ),
    Place(
      id: 14,
      location: CLLocationCoordinate2D(latitude: 51.45815177021243, longitude: -0.07234202963258891)
    ),
    Place(
      id: 15,
      location: CLLocationCoordinate2D(
        latitude: 51.46118687457209, longitude: -0.010835232459132788)),
    Place(
      id: 16,
      location: CLLocationCoordinate2D(
        latitude: 51.460835639443374, longitude: -0.014281893868182346)),
    Place(
      id: 17,
      location: CLLocationCoordinate2D(latitude: 51.45976796054182, longitude: -0.01281653035998517)
    ),
    Place(
      id: 18,
      location: CLLocationCoordinate2D(
        latitude: 51.45510899806231, longitude: -0.010126685016171179)),
    Place(
      id: 19,
      location: CLLocationCoordinate2D(
        latitude: 51.45394425744243, longitude: -0.010146758488886208)),
    Place(
      id: 20,
      location: CLLocationCoordinate2D(
        latitude: 51.454344637030516, longitude: -0.011893150615093799)),
  ]

  @State private var coordinateRegion = MKCoordinateRegion(
    center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275),
    span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
  )

  @State var selection: Place?

  var body: some View {
    //        MapViewRepresentable(initialRegion: coordinateRegion, data: places, coordinate: \.location) { annotation in
    //            Circle()
    //                .fill(.green)
    //                .frame(width: 30, height: 30)
    //                .overlay {
    //                    switch annotation {
    //                        case .single(let place):
    //                            Color.clear
    //                        case .cluster(let places):
    //                            Text(places.count.formatted())
    //                                .bold()
    //                                .foregroundStyle(.black)
    //                    }
    //                }
    //
    //        } onSelect: { annotation in
    //            switch annotation {
    //                case .single(let place):
    //                    print("place:", place.id.formatted())
    //                    selection = place
    //                case .cluster(let places):
    //                    print("cluster:", places.count.formatted())
    //            }
    //        }
    //        .sheet(item: $selection) { place in
    //            VStack {
    //                Text(place.id.formatted())
    //                Text(place.location.latitude.formatted())
    //                Text(place.location.longitude.formatted())
    //            }
    //        }

    //        Map(coordinateRegion: $coordinateRegion, annotationItems: places) { place in
    //            MapAnnotation(coordinate: place.location) {
    //                PlaceView() { }
    //            }
    //        }
    //        .modifier(OnMapTapGesture(region: coordinateRegion, perform: { location in
    //            places.append(Place(id: places.count, location: location))
    //            places.forEach {
    //                print(" Place(id: \($0.id), location: CLLocationCoordinate2D(latitude: \($0.location.latitude), longitude: \($0.location.longitude))),")
    //            }
    //        }))
    //        .ignoresSafeArea(.container, edges: .top)

    MapClusterizer(coordinateRegion: $coordinateRegion, clusterables: places) { (clusters, proxy) in
      Map(coordinateRegion: $coordinateRegion, annotationItems: clusters) { cluster in
        MapAnnotation(coordinate: cluster.center) {
          ClusterView(cluster: cluster) {
            if cluster.values.count == 1 {
              selection = cluster.values.first
            } else {
              withAnimation {
                proxy.zoom(on: cluster)
              }
            }

          }
        }
      }
    }
    .ignoresSafeArea(.container, edges: .top)
    .sheet(item: $selection) { place in
      VStack {
        Text(place.id.formatted())
        Text(place.location.latitude.formatted())
        Text(place.location.longitude.formatted())
      }
    }

  }

}

struct ClusterView: View {

  let cluster: MapCluster<Place>

  let action: () -> Void

  var body: some View {
    Circle()
      .fill(.orange)
      .frame(width: 30, height: 30)
      .overlay {
        if cluster.values.count > 1 {
          Text(cluster.values.count.formatted())
            .foregroundStyle(.white)
            .bold()
        } else {
          Text(cluster.values.first!.id.formatted())
            .foregroundStyle(.black)
            .bold()
        }
      }
      .onTapGesture(perform: action)
  }
}

struct PlaceView: View {

  let place: Place

  let action: () -> Void

  var body: some View {
    Circle()
      .fill(.green)
      .frame(width: 30, height: 30)
      .onTapGesture(perform: action)
  }
}

#Preview {
  ContentView()
}
