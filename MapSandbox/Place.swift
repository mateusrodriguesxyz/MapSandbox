import MapKit

struct Place: Identifiable {
    let id: Int
    let location: CLLocationCoordinate2D
}

extension Place: Equatable {
    static func == (lhs: Place, rhs: Place) -> Bool {
        lhs.id == rhs.id
    }
}

extension Place: MapLocationClusterable { }
