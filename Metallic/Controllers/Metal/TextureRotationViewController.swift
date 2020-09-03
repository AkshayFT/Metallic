//
//  TextureRotationViewController.swift
//  Metallic
//
//  Created by Akshay on 19/05/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class TextureRotationViewController: UIViewController {

    private let image = UIImage(named: "C")!
    private var renderer : FTImageRenderer!
    private var rect : CGRect!
    private var angle : Float = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let metalView = self.view as? MetalView,
            let layer = metalView.layer as? CAMetalLayer else {
                fatalError("Metal view did not setup")
        }

        renderer = FTImageRenderer(layer: layer)
        renderImage()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        renderer.updateSize(size)
        renderImage()
    }

    private func renderImage() {
        rect = CGRect(origin: CGPoint(x: self.view.bounds.midX-250, y: self.view.bounds.midY-250), size: CGSize(width: 500, height: 500))
        renderer.render(image: image, rect: rect, angle: angle)
    }

    @IBAction func rotate() {
        angle += Float.pi/6
        renderer.render(image: image, rect: rect, angle: angle)
    }
}
