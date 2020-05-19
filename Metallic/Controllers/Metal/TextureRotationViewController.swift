//
//  TextureRotationViewController.swift
//  Metallic
//
//  Created by Akshay on 19/05/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class TextureRotationViewController: UIViewController {

    let image = UIImage(named: "A")!
    var renderer : FTImageRenderer!
    let rect = CGRect(x: 200, y: 200, width: 500, height: 500)
    var angle : Float = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let metalView = self.view as? MetalView,
            let layer = metalView.layer as? CAMetalLayer else {
                fatalError("Metal view did not setup")
        }

        renderer = FTImageRenderer(layer: layer)

        renderer.render(image: image, rect: rect, angle: angle)
    }

    @IBAction func rotate() {
        angle += Float.pi/6
        renderer.render(image: image, rect: rect, angle: angle)
    }
}
