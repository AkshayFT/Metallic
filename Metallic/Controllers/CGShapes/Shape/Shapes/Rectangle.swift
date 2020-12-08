//
//  Rectangle.swift
//  Shapes
//
//  Created by Akshay Pakanati on 8/30/18.
//  Copyright © 2018 Ak Inc. All rights reserved.
//

import UIKit

class Rectangle: BaseShapeView {
     
    override var path: UIBezierPath? {
        return UIBezierPath(rect: CGRect(origin: .zero, size: bounds.size))
    }
    
}
