//
//  Ellipse.swift
//  Shapes
//
//  Created by Akshay Pakanati on 8/30/18.
//  Copyright © 2018 Ak Inc. All rights reserved.
//

import UIKit

class Ellipse: BaseShapeView {
    
    //Shape Protocol Implementation
    override var initialSize: CGSize {
        return CGSize(width: 160, height: 80)
    }
    
    override var path: UIBezierPath? {
        return UIBezierPath(ovalIn: CGRect(origin: .zero, size: bounds.size))
    }
}
