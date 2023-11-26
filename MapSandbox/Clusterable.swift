//
//  Clusterable.swift
//  MapSandbox
//
//  Created by Mateus Rodrigues on 21/11/23.
//

import Foundation

protocol Clusterable: Equatable {
    func distance(to other: Self) -> Double
}

extension Array where Element: Clusterable {
    
    func clusterize(distance: Double) -> [[Element]] {
        let dbscan = DBSCAN(self)
        let (clusters, _) = dbscan(epsilon: distance, minimumNumberOfPoints: 1) { $0.distance(to: $1) }
        return clusters
    }
    
}

import MapKit

protocol MapLocationClusterable: Clusterable {
    var location: CLLocationCoordinate2D { get }
}

extension MapLocationClusterable {
    
    func distance(to other: Self) -> Double {
        let selfLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let otherLocation = CLLocation(latitude: other.location.latitude, longitude: other.location.longitude)
        let distance = selfLocation.distance(from: otherLocation)
        return distance
    }
    
}

extension Array where Element: MapLocationClusterable {
    
    func clusterize(distance: Double) -> [MapLocationCluster<Element>] {
        return clusterize(distance: distance).enumerated().map { (id, values) in
            MapLocationCluster(id: id, values: values)
        }
    }
    
    func clusterize(region: MKCoordinateRegion, factor: Double = 50) -> [MapLocationCluster<Element>] {
        let minSpan = CLLocation(latitude: region.center.latitude - region.span.latitudeDelta, longitude: region.center.longitude)
        let maxSpan = CLLocation(latitude: region.center.latitude + region.span.latitudeDelta, longitude: region.center.longitude)
        let newMapSpanDistance = minSpan.distance(from: maxSpan)
        return clusterize(distance: newMapSpanDistance/factor).enumerated().map { (id, values) in
            MapLocationCluster(id: id, values: values)
        }
    }
    
    
}

struct MapLocationCluster<Value: MapLocationClusterable> {
    
    let id: Int
    
    let values: [Value]
    
    let center: CLLocationCoordinate2D
    
    let radius: Double
    
    init(id: Int, values: [Value]) {
        self.id = id
        self.values = values
        self.center = _center(of: values)
        self.radius = _radius(of: values)
    }
    
}

fileprivate func _center(of values: [some MapLocationClusterable]) -> CLLocationCoordinate2D {
    
    let latitudes = values.map(\.location.latitude)
    
    let longitudes = values.map(\.location.longitude)
    
    let minLatitude = latitudes.min()!
    let maxLatitude = latitudes.max()!
    
    let minLongitude = longitudes.min()!
    let maxLongitude = longitudes.max()!
    
    let centerLatitude = (maxLatitude + minLatitude)/2
    let centerLongitude = (maxLongitude + minLongitude)/2
            
    return CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
    
}

fileprivate func _radius(of values: [some MapLocationClusterable]) -> Double {
    
    let latitudes = values.map(\.location.latitude)
    
    let longitudes = values.map(\.location.longitude)
    
    let minLatitude = latitudes.min()!
    let maxLatitude = latitudes.max()!
    
    let minLongitude = longitudes.min()!
    let maxLongitude = longitudes.max()!
    
    let minLocation = CLLocation(latitude: minLatitude, longitude: minLongitude)
    let maxLocation = CLLocation(latitude: maxLatitude, longitude: maxLongitude)
    
    return minLocation.distance(from: maxLocation)
    
}

extension MapLocationCluster: Identifiable { }

