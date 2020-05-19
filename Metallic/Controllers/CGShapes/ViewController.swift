//
//  ViewController.swift
//  Shapes
//
//  Created by Akshay Pakanati on 8/27/18.
//  Copyright © 2018 Ak Inc. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var canvas: MetalView!
    
    var selectedShape: BaseShapeView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? ShapeSelectionViewController, segue.identifier == "presentShapeSelection" {
            controller.shapeSelected = { [weak self] shape in
                self?.addNewShape(shape: shape)
            }
        }
    }
    
    func addNewShape(shape:ShapeType) {
        
        selectedShape?.isSelected = false
        
        let newShapeView = ShapeGenerator.generate(shape: shape)
        newShapeView.center = canvas.center
        canvas.addSubview(newShapeView)

        renderMetalShape(from: newShapeView)
        
        selectedShape = newShapeView
        
        let panGestureRecongnizer = UIPanGestureRecognizer(target: self, action: #selector(handleMove(sender:)))
        newShapeView.addGestureRecognizer(panGestureRecongnizer)
        
        let resizeGestureRecongnizer = UIPanGestureRecognizer(target: self, action: #selector(handleResize(sender:)))
        newShapeView.resizerView?.addGestureRecognizer(resizeGestureRecongnizer)
        
    }
}

//Touch Recognizers
extension ViewController {
    
    //Handling Resize option with Pan Gesture
    @objc func handleResize(sender: UIPanGestureRecognizer) {
        
        if let mainView = sender.view?.superview as? BaseShapeView, sender.state == UIGestureRecognizer.State.changed {
            selectedShape = mainView
            selectedShape?.isSelected = true
            
            var size = mainView.bounds.size
            let translation = sender.translation(in:sender.view)
            size = CGSize(width:size.width + translation.x, height:size.height + translation.y)
            if size.width >= 20 && size.height >= 20 {
                mainView.frame.size = size
                sender.setTranslation(CGPoint.zero, in: sender.view)
                renderMetalShape(from: mainView)
            }
        }
    }
    
    //Handling Move option with Pan Gesture
    @objc func handleMove(sender: UIPanGestureRecognizer) {
        if (sender.state == UIGestureRecognizer.State.changed) {
            var center = sender.view?.center
            let translation = sender.translation(in:sender.view)
            center = CGPoint(x:center!.x + translation.x, y:center!.y + translation.y)
            sender.view?.center = center!
            sender.setTranslation(CGPoint.zero, in: sender.view)
            renderMetalShape(from: sender.view!)
        }
    }

    //Used to identify touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        //Remove selection for the existing
        selectedShape?.isSelected = false
        
        if let touch = touches.first, let shape = touch.view as? BaseShapeView {
            shape.isSelected = true
            selectedShape = shape
        } else {
            selectedShape?.isSelected = false
        }
    }
}
