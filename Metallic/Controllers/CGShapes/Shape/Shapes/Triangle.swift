//
//  Triangle.swift
//  Shapes
//
//  Created by Akshay Pakanati on 8/30/18.
//  Copyright © 2018 Ak Inc. All rights reserved.
//

import UIKit

class Triangle: BaseShapeView {
    
    //Shape Protocol Implementation
    override var initialSize: CGSize {
        return CGSize(width: 80, height: 160)
    }
    
    override var path: UIBezierPath? {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: bounds.size.width/2, y: 0.0))
        path.addLine(to: CGPoint(x: 0.0, y: bounds.size.height))
        path.addLine(to: CGPoint(x: bounds.size.width, y: bounds.size.height))
        path.close()
        return path
    }
    
}
