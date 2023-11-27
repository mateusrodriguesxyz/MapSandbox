//
//  MKMarkerAnnotationViewRepresentable.swift
//  MapSandbox
//
//  Created by Mateus Rodrigues on 26/11/23.
//

import SwiftUI
import MapKit

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
