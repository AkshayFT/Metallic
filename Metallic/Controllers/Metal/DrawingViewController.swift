//
//  DrawingViewController.swift
//  Metallic
//
//  Created by Akshay on 20/09/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit


class DrawingViewController: UIViewController {

    private var metalLayer: CAMetalLayer!
    private var renderer : DrawRenderer!

    private var currentTool : DrawingTool = .pen
    private var currentThickness : Thickness = .small
    private var currentColor : UIColor = .red

    @IBOutlet private var metalView: MetalView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if metalLayer == nil {
            guard let layer = metalView.layer as? CAMetalLayer else {
                fatalError("Metal view not setup")
            }

            self.metalLayer = layer
            renderer = DrawRenderer(metalLayer: layer)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let toolbar = segue.destination as? ToolbarViewController {
            toolbar.delegate = self
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        renderer.viewportSizeDidChange()
    }
}

extension DrawingViewController: ToolbarActionProtocol {
    func toolChanged(tool: DrawingTool) {
        currentTool = tool
        switch tool {
        case .pen:
            currentColor = .red
        case .highlighter:
            currentColor = .yellow
        case .eraser:
            currentColor = .white
        }
    }

    func sizeChanged(thickness: Thickness) {
        currentThickness = thickness
    }

    func clearAll() {
        renderer.clearAll()
    }
}


extension DrawingViewController {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        let points = createPoints(from: touches, event: event)
        renderer.render(mode: currentTool,
                        points:points,
                        color:currentColor,
                        thickness: currentThickness,
                        shouldClear: true,
                        shouldEnd: false)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        let points = createPoints(from: touches, event: event)
        renderer.render(mode: currentTool,
                        points:points,
                        color:currentColor,
                        thickness: currentThickness,
                        shouldClear: false,
                        shouldEnd: false)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        let points = createPoints(from: touches, event: event)
        renderer.render(mode: currentTool,
                        points:points,
                        color:currentColor,
                        thickness: currentThickness,
                        shouldClear: false,
                        shouldEnd: true)
    }
}

private extension DrawingViewController {
    func createPoints(from touches:Set<UITouch>, event: UIEvent?) -> [CGPoint] {

        guard let touch = touches.first, let coalesced = event?.coalescedTouches(for: touch) else {
            return [CGPoint]()
        }
        var points = [CGPoint]();
        coalesced.forEach { (touch) in
            var point = touch.preciseLocation(in: metalView);
            point.y = metalView.frame.height - point.y;
            points.append(point);
        }

//        event?.predictedTouches(for: touch)?.forEach({ touch in
//            var point = touch.preciseLocation(in: metalView);
//            point.y = metalView.frame.height - point.y;
//            points.append(point);
//        })
        return points
    }
}
