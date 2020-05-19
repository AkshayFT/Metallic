//
//  ViewController.swift
//  Metallic-Mac
//
//  Created by Akshay on 12/09/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import Cocoa
import MetalKit

class ImageRenderController: PlatformController {

    var metalView: MTKView!
    var renderer : ImageRenderer!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.metalView = self.view as? MTKView
        guard self.metalView != nil else { fatalError("Metal view is not initialized") }
        self.metalView.device = MTLCreateSystemDefaultDevice()

        renderer = ImageRenderer(metalView: self.metalView)
        renderer.mtkView(metalView, drawableSizeWillChange: metalView.drawableSize)
        self.metalView.delegate = renderer
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
}
