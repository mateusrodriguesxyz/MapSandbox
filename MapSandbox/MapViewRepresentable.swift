//
//  MapViewRepresentable.swift
//  MapSandbox
//
//  Created by Mateus Rodrigues on 06/12/23.
//

import MapClusterizer
import MapKit
import SwiftUI

enum AnnotationKind<Element> {
  case single(_ element: Element)
  case cluster(_ elements: [Element])
}

struct MapViewRepresentable<Data: RandomAccessCollection, Content: View>: UIViewRepresentable {

  let initialRegion: MKCoordinateRegion

  let data: Data

  let coordinate: KeyPath<Data.Element, CLLocationCoordinate2D>

  let content: (AnnotationKind<Data.Element>) -> (Content)

  let onSelect: (AnnotationKind<Data.Element>) -> Void

  func makeCoordinator() -> Coordinator {
    .init(content: content, onSelect: onSelect)
  }

  func makeUIView(context: Context) -> MKMapView {
    let uiView = MKMapView(frame: .zero)
    uiView.region = initialRegion
    let annotations = data.map({ Annotation(item: $0, coordinate: $0[keyPath: coordinate]) })
    uiView.addAnnotations(annotations)
    uiView.register(
      CustomAnnotationView.self,
      forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
    uiView.register(
      CustomAnnotationView.self,
      forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
    context.coordinator.configure(uiView)
    return uiView
  }

  func updateUIView(_ uiView: MKMapView, context: Context) {
    uiView.region = initialRegion
  }

}

extension MapViewRepresentable {

  class Coordinator: NSObject, MKMapViewDelegate {

    var mapView: MKMapView? = nil

    let content: (AnnotationKind<Data.Element>) -> (Content)

    let onSelect: (AnnotationKind<Data.Element>) -> Void

    init(
      content: @escaping (AnnotationKind<Data.Element>) -> Content,
      onSelect: @escaping (AnnotationKind<Data.Element>) -> Void
    ) {
      self.content = content
      self.onSelect = onSelect
    }

    func configure(_ mapView: MKMapView) {
      self.mapView = mapView
      mapView.delegate = self
      mapView.showsScale = true
      addDisableZoomTapGesture(to: mapView)
      //            addZoomDoubleTapGesture(to: mapView)
    }

    // https://stackoverflow.com/questions/35639388/tapping-an-mkannotation-to-select-it-is-really-slow
    func addDisableZoomTapGesture(to mapView: MKMapView) {
      let gesture = UITapGestureRecognizer(target: self, action: #selector(disableZoom(_:)))
      gesture.numberOfTapsRequired = 1
      gesture.numberOfTouchesRequired = 1
      mapView.addGestureRecognizer(gesture)
    }

    @objc func disableZoom(_ sender: UITapGestureRecognizer? = nil) {
      guard let mapView = sender?.view as? MKMapView else { return }
      mapView.isZoomEnabled = false
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        mapView.isZoomEnabled = true
      }
    }

    func addZoomDoubleTapGesture(to mapView: MKMapView) {
      let gesture = UITapGestureRecognizer(target: self, action: #selector(zoom(_:)))
      gesture.numberOfTapsRequired = 2
      gesture.numberOfTouchesRequired = 1
      mapView.addGestureRecognizer(gesture)
    }

    @objc func zoom(_ sender: UITapGestureRecognizer? = nil) {
      guard let mapView = sender?.view as? MKMapView else { return }
      // TODO
    }

    func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
      //            if let single = annotation as? Annotation {
      //                onSelect(.single(single.item))
      //            }
      //            if let cluster = annotation as? MKClusterAnnotation {
      //                onSelect(.cluster(cluster.memberAnnotations.compactMap({ ($0 as? Annotation)?.item })))
      //                mapView.showAnnotations(cluster.memberAnnotations, animated: true)
      //            }
      mapView.deselectAnnotation(annotation, animated: true)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
      switch annotation {
      case is MKClusterAnnotation:
        let view =
          mapView.dequeueReusableAnnotationView(
            withIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier, for: annotation)
          as! CustomAnnotationView
        if view._content == nil {
          view._content = content
        }
        view.canShowCallout = false
        return view
      default:
        let view =
          mapView.dequeueReusableAnnotationView(
            withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier, for: annotation)
          as! CustomAnnotationView
        if view._content == nil {
          view._content = content
        }
        view.canShowCallout = false
        view.clusteringIdentifier = "id"
        return view
      }
    }

  }

  class Annotation: NSObject, MKAnnotation {
    let item: Data.Element
    let coordinate: CLLocationCoordinate2D
    init(item: Data.Element, coordinate: CLLocationCoordinate2D) {
      self.item = item
      self.coordinate = coordinate
    }
  }

  final class CustomAnnotationView: MKAnnotationView {

    struct SwifUIAnnotationView: View {

      @ObservedObject var model: Model

      let content: (AnnotationKind<Data.Element>) -> (Content)

      var body: some View {
        let _ = Self._printChanges()
        content(model.kind)
      }
    }

    class Model: ObservableObject {

      @Published var kind: AnnotationKind<Data.Element> = .cluster([])
    }

    let model = Model()

    override var annotation: MKAnnotation? {
      didSet {
        guard let annotation else { return }
        if let single = annotation as? Annotation {
          model.kind = .single(single.item)
        }
        if let cluster = annotation as? MKClusterAnnotation {
          model.kind = .cluster(cluster.memberAnnotations.compactMap({ ($0 as? Annotation)?.item }))
        }
      }
    }

    var _content: ((AnnotationKind<Data.Element>) -> (Content))? = nil {
      didSet {
        configure()
      }
    }

    var swiftUIView: UIView = .init()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
      super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
      swiftUIView.isUserInteractionEnabled = true
    }

    private func configure() {
      backgroundColor = .clear
      if let _content {
        swiftUIView = UIHostingConfiguration {
          SwifUIAnnotationView(model: model, content: _content)
        }.margins(.all, 0).makeContentView()
        addSubview(swiftUIView)
        swiftUIView.translatesAutoresizingMaskIntoConstraints = false
        swiftUIView.backgroundColor = .systemRed
        NSLayoutConstraint.activate([
          swiftUIView.leftAnchor.constraint(equalTo: leftAnchor),
          swiftUIView.rightAnchor.constraint(equalTo: rightAnchor),
          swiftUIView.topAnchor.constraint(equalTo: topAnchor),
          swiftUIView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
      }
    }

    override func layoutSubviews() {
      super.layoutSubviews()
      swiftUIView.bounds.origin.y = 0.1
      swiftUIView.bounds.origin.y = .zero
      frame = CGRect(origin: .zero, size: swiftUIView.intrinsicContentSize)
    }

  }

}

extension CLLocationCoordinate2D {

  public func distance(to other: Self) -> Double {
    let selfLocation = CLLocation(latitude: latitude, longitude: longitude)
    let otherLocation = CLLocation(latitude: other.latitude, longitude: other.longitude)
    let distance = selfLocation.distance(from: otherLocation)
    return distance
  }

}

//        public func zoom(on cluster: MKClusterAnnotation, factor: Double = 3) {
//
//            var distance: Double = 0
//
//            cluster.memberAnnotations.forEach { annotation in
//                cluster.memberAnnotations.forEach { other in
//                    if other.coordinate.latitude == annotation.coordinate.latitude, other.coordinate.longitude == annotation.coordinate.longitude  { return }
//                    distance = max(distance, annotation.coordinate.distance(to: other.coordinate))
//                }
//            }
//
//            func _center(of values: [MKAnnotation]) -> CLLocationCoordinate2D {
//
//                let latitudes = values.map(\.coordinate.latitude)
//
//                let longitudes = values.map(\.coordinate.longitude)
//
//                let minLatitude = latitudes.min()!
//                let maxLatitude = latitudes.max()!
//
//                let minLongitude = longitudes.min()!
//                let maxLongitude = longitudes.max()!
//
//                let centerLatitude = (maxLatitude + minLatitude)/2
//                let centerLongitude = (maxLongitude + minLongitude)/2
//
//                return CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
//
//            }
//
//            let zoomRegion = MKCoordinateRegion(center: _center(of: cluster.memberAnnotations), latitudinalMeters: distance * factor, longitudinalMeters: distance * factor)
//
//
//            mapView?.setRegion(zoomRegion, animated: true)
//
//        }

//        func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
//            if let single = annotation as? Annotation {
//                onSelect(.single(single.item))
//            }
//            if let cluster = annotation as? MKClusterAnnotation {
//                mapView.showAnnotations(cluster.memberAnnotations, animated: true)
//                onSelect(.cluster(cluster.memberAnnotations.compactMap({ ($0 as? Annotation)?.item })))
//            }
//            mapView.deselectAnnotation(annotation, animated: false)
//        }
