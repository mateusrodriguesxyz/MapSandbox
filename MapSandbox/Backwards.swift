//
//  Backwards.swift
//  MapSandbox
//
//  Created by Mateus Rodrigues on 22/11/23.
//

import SwiftUI
import MapKit

public struct Backport<Content> {
    
    public let content: Content

    public init(_ content: Content) {
        self.content = content
    }
    
}

extension View {
    var backport: Backport<Self> { Backport(self) }
}

enum Backports {
    
    struct MapCameraUpdateContext {
        
        let rect: MKMapRect
        let region: MKCoordinateRegion
        
    }
    
}

extension Backport where Content: View {
    
    @ViewBuilder func onMapCameraChange(_ action: @escaping (Backports.MapCameraUpdateContext) -> Void) -> some View {
        if #available(iOS 17, *) {
            content
                .onMapCameraChange { context in
                    action(.init(rect: context.rect, region: context.region))
                }
        } else {
            content
        }
    }
    
}
