//
//  ShapesViewController.swift
//  Metallic
//
//  Created by Akshay on 20/04/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit
import simd

final class ShapesViewController: UIViewController {

    @IBOutlet var metalView: MetalView!
    var renderer : DrawRenderer!

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let layer = metalView?.layer as? CAMetalLayer else {
            fatalError("Metal view did not setup")
        }
        renderer = DrawRenderer(metalLayer: layer)

        //Metal
        let roundedRect = RoundedRectangle(origin: self.metalView.center,
                                           width: 150,
                                           height: 200,
                                           cornerRadius: 50)

        roundedRect.draw(roundedRect: roundedRect, renderer: renderer)
    }
}
