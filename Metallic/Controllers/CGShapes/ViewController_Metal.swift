//
//  ViewController_Metal.swift
//  Metallic
//
//  Created by Akshay on 11/05/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit


extension ViewController {

    func renderMetalShape(from shapeView: UIView) {
        guard let layer = canvas?.layer as? CAMetalLayer else {
            fatalError("Metal view did not setup")
        }

//      let roundedRect =  RoundedRectangle(origin: self.canvas.center,
//                                           width: 150,
//                                           height: 200,
//                                           cornerRadius: 50)
//        if let roundedRectView = shapeView as? RoundedRectangleCG {
//            var roundedRect = roundedRectView.rectangle!
//            roundedRect.origin = roundedRectView.frame.origin
//            let renderer = DrawRenderer(metalLayer: layer)
//            roundedRect.draw(roundedRect: roundedRect, renderer: renderer)
//        }
    }
}
