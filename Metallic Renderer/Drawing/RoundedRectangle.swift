//
//  RoundedRectangle.swift
//  Metallic
//
//  Created by Akshay on 16/04/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

typealias Angle = Float

struct RoundedRectangle {

    var bounds : CGRect {
        return CGRect(origin: origin, size: CGSize(width: width, height: height))
    }

    var width: CGFloat
    var height: CGFloat

    var origin: CGPoint

    var sideWidth: CGFloat {
        return width - 2*cornerRadius
    }

    var sideHeight: CGFloat {
        return height - 2*cornerRadius
    }

    private var _cornerRadius: CGFloat = 0
    var cornerRadius: CGFloat {
        set {
            let maxPossible = min(width/2, height/2)
            if newValue > maxPossible {
                _cornerRadius = maxPossible
            } else if cornerRadius < 0 {
                _cornerRadius = 0
            }
            _cornerRadius = newValue
        } get {
            let maxPossible = min(width/2, height/2)
            if _cornerRadius > maxPossible {
                return maxPossible
            } else if _cornerRadius < 0 {
                return 0
            }
            return _cornerRadius
        }
    }

    init(origin: CGPoint, width: CGFloat, height: CGFloat, cornerRadius: CGFloat) {
        self.origin = origin
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
}

func getCirclePoints(origin: CGPoint, corner: Corner, radius: CGFloat)->[CGPoint] {
    let result: [CGPoint] = stride(from: corner.angle.from, to: corner.angle.to, by: 1).map {
        let bearing = CGFloat($0) * .pi / 180
        let x = origin.x + radius * cos(bearing)
        let y = origin.y + radius * sin(bearing)
        return CGPoint(x: x, y: y)
    }
    return result
}

enum Corner: CaseIterable {
    case topRight
    case bottomRight
    case bottomLeft
    case topLeft

    var angle: (from: CGFloat, to: CGFloat) {
        switch self {
        case .topRight:
            return (0.0, 90.0)
        case .bottomRight:
            return (90.0, 180.0)
        case .bottomLeft:
            return (180.0, 270.0)
        case .topLeft:
            return (270.0, 360.0)
        }
    }

    var color: UIColor {
        switch self {
        case .topLeft:
            return .green
        case .topRight:
            return .orange
        case .bottomRight:
            return .yellow
        case .bottomLeft:
            return .systemPink
        }
    }

    func origin(width: CGFloat, height: CGFloat) -> CGPoint {
        switch self {
        case .topRight:
            return CGPoint(x: width/2, y: height/2)
        case .bottomRight:
            return CGPoint(x: -width/2, y: height/2)
        case .bottomLeft:
            return CGPoint(x: -width/2, y: -height/2)
        case .topLeft:
            return CGPoint(x: width/2, y: -height/2)
        }
    }
}



extension RoundedRectangle {

    func draw(roundedRect: RoundedRectangle, renderer: DrawRenderer) {

        var polyPoints = [CGPoint]()

        //fill the corners
        for corner in Corner.allCases {

            //find the point to transle
            let pointToTranslate = corner.origin(width: roundedRect.sideWidth, height: roundedRect.sideHeight)

            let originForCorner = roundedRect.origin.applying(CGAffineTransform(translationX: pointToTranslate.x, y: pointToTranslate.y))
            let points = getCirclePoints(origin: originForCorner, corner: corner, radius: roundedRect.cornerRadius)

            var trainglePoints = [CGPoint]()
            points.enumerated().forEach { (index, point) in
                trainglePoints.append(point)
                if index != 0 {
                    trainglePoints.append(originForCorner)
                    trainglePoints.append(point)
                }
            }
            renderer.fillShape(points: trainglePoints, color: .red )

            polyPoints.append(contentsOf: [points[0], points[points.count-1]])
        }

        //Fill the inermediate polygon
        let vertices = polyPoints.map { point -> Vertex in
            let vector = Vector(point.x.toDouble, point.y.toDouble)
            return Vertex(vector, vector.normal)
        }

        if let polygon = Polygon(vertices)?.tessellate() {
            let triangles = polygon.triangulate()
            for triangle in triangles {
                let points = triangle.vertices.map { vertex -> CGPoint in
                    return CGPoint(x: vertex.position.x, y: vertex.position.y)
                }
                renderer.fillShape(points: points, color: .red)
            }
        }
    }
}
