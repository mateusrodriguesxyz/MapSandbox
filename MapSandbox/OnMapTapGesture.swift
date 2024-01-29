//
//  OnMapTapGesture.swift
//  MapSandbox
//
//  Created by Mateus Rodrigues on 26/11/23.
//

import MapKit
import SwiftUI

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

    let mapCenter = CGPoint(x: mapSize.width / 2, y: mapSize.height / 2)

    let xValue = (point.x - mapCenter.x) / mapCenter.x
    let xSpan = xValue * region.span.longitudeDelta / 2

    let yValue = (point.y - mapCenter.y) / mapCenter.y
    let ySpan = yValue * region.span.latitudeDelta / 2

    return CLLocationCoordinate2D(latitude: lat - ySpan, longitude: lon + xSpan)
  }

}
