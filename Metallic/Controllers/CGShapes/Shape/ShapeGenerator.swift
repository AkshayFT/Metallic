//
//  ShapeGenerator.swift
//  Shapes
//
//  Created by Akshay Pakanati on 8/27/18.
//  Copyright © 2018 Ak Inc. All rights reserved.
//

import UIKit

class ShapeGenerator {
    
    class func generate(shape:ShapeType) -> BaseShapeView {
        
        let frame = CGRect.zero       
        var view : BaseShapeView

        switch shape {
        case .star:
            view = Star(frame:frame)
        case .triangle:
            view = Triangle(frame:frame)
        case .rectangle:
            view = Rectangle(frame:frame)
        case .ellipse:
            view = Ellipse(frame:frame)
        case .roundRectangle:
            view = Rectangle(frame:frame)
        }
        
        view.backgroundColor = .clear
        view.isSelected = true
        return view
    }
    
}
