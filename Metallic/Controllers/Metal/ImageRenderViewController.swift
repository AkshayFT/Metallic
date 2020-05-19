//
//  ImageRenderViewController.swift
//  Metallic
//
//  Created by Akshay on 11/09/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class ImageRenderViewController: UIViewController {

    var metalLayer: CAMetalLayer!
    var renderer : ImageRenderer!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let metalView = self.view as? MetalView,
            let layer = metalView.layer as? CAMetalLayer else {
                fatalError("Metal view did not setup")
        }
        self.metalLayer = layer
        renderer = ImageRenderer(metalLayer: layer)
        renderer.render(on: layer)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        renderer.render(on: metalLayer)
    }
}
