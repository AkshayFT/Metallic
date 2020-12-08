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
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        self.backgroundColor = .red
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

extension UIScreen
{
    var maxDimension: CGFloat {
        let screenBounds = coordinateSpace.convert(self.bounds, to: self.fixedCoordinateSpace);
        let maxValue = max(screenBounds.width, screenBounds.height);
        #if targetEnvironment(macCatalyst)
        let mainScreen = UIScreen.main;
        return maxValue * mainScreen.scale * 2;
        #else
        return maxValue;
        #endif
    }

    static var screenContentScale : CGFloat {
        #if targetEnvironment(macCatalyst)
        return globalScreenScale;
        #else
        return UIScreen.main.scale;
        #endif
    }
}
