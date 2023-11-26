//
//  MapSandboxApp.swift
//  MapSandbox
//
//  Created by Mateus Rodrigues on 21/11/23.
//

import SwiftUI

struct PinchRepresentable<Content: View>: UIViewControllerRepresentable {
    
    class UIViewControllerType: UIHostingController<Content>, UIGestureRecognizerDelegate {
        
        override func viewDidLoad() {
            super.viewDidLoad()
            if #available(iOS 16.4, *) {
                safeAreaRegions = SafeAreaRegions()
            } else {
                // Fallback on earlier versions
            }
            print(#function)
            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
            pinch.delegate = self
            view.addGestureRecognizer(pinch)
        }

        // Pinch action
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            if gesture.state == .ended {
                print("ended")
            }
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
        
    }
    
    @ViewBuilder var content: () -> Content
    
    func makeUIViewController(context: Context) -> UIViewControllerType {
        UIViewControllerType(rootView: content())
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
        
}

@main
struct MapSandboxApp: App {
    var body: some Scene {
        WindowGroup {
//            PinchRepresentable {
                ContentView()
//            }
            .ignoresSafeArea(.all)
        }
    }
}
