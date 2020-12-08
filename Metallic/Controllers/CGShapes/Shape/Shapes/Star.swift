//
//  Star.swift
//  Shapes
//
//  Created by Akshay Pakanati on 8/30/18.
//  Copyright © 2018 Ak Inc. All rights reserved.
//

import UIKit

class Star: BaseShapeView {

    //Shape Protocol Implementation
    override var initialSize: CGSize {
        return CGSize(width: 160, height: 160)
    }
    
    override var path: UIBezierPath? {
        return star(with: bounds)
    }
    
    
    //BezierPath for Star
    func star(with frame:CGRect) -> UIBezierPath {
        let sides = 5
        let radius = min(frame.size.width/4,frame.size.height/4)
        let pointyness : CGFloat = 2.0
        let startAngle = CGFloat(-1*(360/sides/4))
        let path = starPath(x: frame.size.width/2, y: frame.size.height/2, radius: radius, sides: sides, pointyness: pointyness, startAngle: startAngle)
        return UIBezierPath(cgPath: path)
    }
    
    func degree2radian(a:CGFloat)->CGFloat {
        let b = CGFloat(Double.pi) * a/180
        return b
    }
    
    func polygonPointArray(sides:Int,x:CGFloat,y:CGFloat,radius:CGFloat,adjustment:CGFloat=0)->[CGPoint] {
        let angle = degree2radian(a: 360/CGFloat(sides))
        let cx = x // x origin
        let cy = y // y origin
        let r  = radius // radius of circle
        var i = sides
        var points = [CGPoint]()
        while points.count <= sides {
            let xpo = cx - r * cos(angle * CGFloat(i)+degree2radian(a: adjustment))
            let ypo = cy - r * sin(angle * CGFloat(i)+degree2radian(a: adjustment))
            points.append(CGPoint(x: xpo, y: ypo))
            i -= 1;
        }
        return points
    }
    
    func starPath(x:CGFloat, y:CGFloat, radius:CGFloat, sides:Int, pointyness:CGFloat, startAngle:CGFloat=0) -> CGPath {
        let adjustment = startAngle + CGFloat(360/sides/2)
        let path = CGMutablePath.init()
        let points = polygonPointArray(sides: sides,x: x,y: y,radius: radius, adjustment: startAngle)
        let cpg = points[0]
        let points2 = polygonPointArray(sides: sides,x: x,y: y,radius: radius*pointyness,adjustment:CGFloat(adjustment))
        var i = 0
        path.move(to: CGPoint(x:cpg.x,y:cpg.y))
        for p in points {
            path.addLine(to: CGPoint(x:points2[i].x, y:points2[i].y))
            path.addLine(to: CGPoint(x:p.x, y:p.y))
            i += 1
        }
        path.closeSubpath()
        return path
    }
}
