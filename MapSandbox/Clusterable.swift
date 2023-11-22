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

protocol LocationClusterable: Clusterable {
    var latitude: Double { get }
    var longitude: Double { get }
}

struct LocationCluster<Value: LocationClusterable> {
    let values: [Value]
}

extension Array where Element: Clusterable {
    
    func clusterize(distance: Double) -> [[Element]] {
        
        let dbscan = DBSCAN(self)
        
        let (clusters, _) = dbscan(epsilon: distance, minimumNumberOfPoints: 1) { $0.distance(to: $1) }
        
        return clusters
        
    }
    
}

extension Array where Element: LocationClusterable {
    
    func clusterize(distance: Double) -> [LocationCluster<Element>] {
        return clusterize(distance: distance).map({ LocationCluster(values: $0) })
    }
    
}
