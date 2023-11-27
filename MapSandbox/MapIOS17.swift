//
//  MapIOS17.swift
//  MapSandbox
//
//  Created by Mateus Rodrigues on 26/11/23.
//

import Foundation


//if #available(iOS 17, *) {
//    MapReader { reader in
//        Map(initialPosition: .userLocation(fallback: .automatic)) {
//            ForEach(clusters) { cluster in
//                if cluster.values.count == 1 {
//                    Marker("", coordinate: cluster.center)
//                } else {
//                    Marker("", monogram: Text("\(cluster.values.count)"), coordinate: cluster.center)
//                }
//            }
//        }
//        .onMapCameraChange { context in
//            clusters = places.clusterize(region: context.region)
//        }
//        .onTapGesture(count: 2) {
//            if let location = reader.convert($0, from: .local) {
//                places.append(.init(id: places.count, location: location))
//                clusters = places.clusterize(distance: mapSpanDistance/50)
//            }
//        }
//    }
//    .tabItem {
//        Text("iOS 17")
//    }
//}
