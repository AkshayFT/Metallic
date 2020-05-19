//
//  DrawingViewController.swift
//  Metallic-Mac
//
//  Created by Akshay on 23/09/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import Cocoa

class DrawingViewController: NSViewController {

    var metalLayer: CAMetalLayer!
    var renderer : DrawRenderer!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func touchesBegan(with event: NSEvent) {
        super.touchesBegan(with: event)
    }

    override func touchesMoved(with event: NSEvent) {
        super.touchesMoved(with: event)
    }

    override func touchesEnded(with event: NSEvent) {
        super.touchesEnded(with: event)
    }
    
}
