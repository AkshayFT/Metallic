//
//  MetalView.swift
//  Metallic
//
//  Created by Akshay on 19/09/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//
#if os(macOS)
import AppKit
#else
import UIKit
#endif
let mtlDevice = MTLCreateSystemDefaultDevice()!
class MetalView: PlatformView {
    private var metalLayer: CAMetalLayer!;

    override func awakeFromNib() {
        super.awakeFromNib()
        if let mtlLayer = self.layer as? CAMetalLayer {
            self.metalLayer = mtlLayer
            self.metalLayer.device = mtlDevice
            self.metalLayer.pixelFormat = .bgra8Unorm
            self.metalLayer.framebufferOnly = false
            self.metalLayer.contentsScale = 2
            self.contentScaleFactor = 2
        }
    }

}
#if os(macOS)
extension MetalView {
    override func layoutSubtreeIfNeeded() {
        super.layoutSubtreeIfNeeded()
        updateDrawbleSize()
    }
}
#endif

#if os(iOS)
extension MetalView {
    override class var layerClass: AnyClass {
        return CAMetalLayer.self
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        updateDrawbleSize()
    }
}
#endif

private extension MetalView {
    func updateDrawbleSize() {
        self.metalLayer.drawableSize = self.bounds.integral.size.scaled(to: 1.0)
    }
}
