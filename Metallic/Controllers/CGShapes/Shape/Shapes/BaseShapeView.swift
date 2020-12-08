//
//  BaseShapeView.swift
//  Shapes
//
//  Created by Akshay Pakanati on 8/30/18.
//  Copyright © 2018 Ak Inc. All rights reserved.
//

import UIKit

protocol Shape {
    var initialSize : CGSize { get }
    var initialColor : UIColor { get }
    var path : UIBezierPath? { get }
}

class BaseShapeView:UIView, Shape {
    
    //Shape Protocol Implementation
    var initialSize: CGSize {
        return CGSize(width: 150, height: 100)
    }
    
    var initialColor: UIColor {
        return .random
    }
    
    //Will be overwritten by Subclasses
    var path: UIBezierPath? {
        return nil
    }
    
    //SubLayers and Resizing Views
    var resizerView : UIView!
    let borderLayer = CAShapeLayer()
    let shapeLayer = CAShapeLayer()
    
    //Selection Handler
    var isSelected : Bool = false {
        didSet {
            if isSelected == true {
                borderLayer.isHidden = false
                resizerView.isHidden = false
                superview?.bringSubviewToFront(self)
            } else {
                borderLayer.isHidden = true
                resizerView.isHidden = true
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.frame.size = initialSize
        setupLayers()
        setUpResizer()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupLayers() {
        
        borderLayer.strokeColor = UIColor.black.cgColor
        borderLayer.lineDashPattern = [6, 3]
        borderLayer.frame = bounds
        borderLayer.fillColor = nil
        borderLayer.needsDisplayOnBoundsChange = true
        borderLayer.path = UIBezierPath(rect: bounds).cgPath
        borderLayer.isHidden = true
        layer.addSublayer(borderLayer)
        
        shapeLayer.strokeColor = UIColor.clear.cgColor
        shapeLayer.frame = bounds
        shapeLayer.fillColor = initialColor.cgColor
        shapeLayer.needsDisplayOnBoundsChange = true
        layer.addSublayer(shapeLayer)
        
    }
    
    func setUpResizer() {
        let size = CGSize(width: 20, height: 20)
        let origin = CGPoint(x:bounds.size.width - size.width, y:bounds.size.height - size.height)
        let resizerView = UIImageView(frame: CGRect(origin: origin, size: size))
        resizerView.image = UIImage(named: "resize")
        resizerView.isUserInteractionEnabled = true
        addSubview(resizerView)
        
        self.resizerView = resizerView
        self.resizerView.isHidden = true
    }
    
}

//Update the layers and subviews when the main view is resized or moved
extension BaseShapeView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //Update the selection border based on new bounds
        borderLayer.path = UIBezierPath(rect: bounds).cgPath
        
        //Update the main shape based on new bounds
        shapeLayer.path = path?.cgPath
        
        //Reposition the Resizer icon based on new bounds
        let size = resizerView.bounds.size
        let origin = CGPoint(x:bounds.size.width - size.width, y:bounds.size.height - size.height)
        resizerView?.frame = CGRect(origin: origin, size: size)
    }
}

extension BaseShapeView {
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if resizerView.frame.contains(point) {
            return resizerView
        } else if  path?.contains(point) == true {
            return self
        } else {
            return nil
        }
    }
}

