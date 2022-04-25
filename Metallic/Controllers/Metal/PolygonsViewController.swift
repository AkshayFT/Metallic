//
//  PolygonsViewController.swift
//  Metallic
//
//  Created by Akshay on 14/04/20.
//  Copyright © 2020 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

class PolygonsViewController: UIViewController {
    @IBOutlet private var metalView: MetalView!
    private var metalLayer: CAMetalLayer!
    private var renderer : DrawRenderer!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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

        refreshTapped(nil)
    }

    @IBAction func refreshTapped(_ sender: UIBarButtonItem?) {
        renderer.clearAll()
        let pointsArray = [points, points2, points3, points4, points5, points6]

        var borderPoints = [CGPoint]()

        let randomArray = pointsArray.randomElement()!

        let vertices = randomArray.map { vector -> Vertex in
            return Vertex(vector, vector.normal)
        }

        if let polygon = Polygon(vertices)?.tessellate() {
            let triangles = polygon.triangulate()
            for triangle in triangles {
                let points = triangle.vertices.map { vertex -> CGPoint in
                    return CGPoint(x: vertex.position.x, y: vertex.position.y)
                }
                renderer.fillShape(points: points)
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        print(#function,touches.map({$0.location(in: self.view)}))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        print(#function,touches.map({$0.location(in: self.view)}))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
       // print(#function,touches.map({$0.location(in: self.view)}))
    }

}

extension Vector {
    static var random: Vector {
        return Vector(Double.random(in: 200...600), Double.random(in: 200...600))
    }

    static var randomVectors: [Vector] {
        var vectors = [Vector]()
        for _ in 5...20 {
            vectors.append(Vector.random)
        }
        vectors.append(vectors[0])
        return vectors
    }
}



//Clockwise
let points = [
    Vector(506.0, 621.1),
    Vector(559.2, 485.1),
    Vector(406.1, 429.9),
    Vector(306.0, 300.1),
    Vector(306.0, 621.1),
    Vector(506.0, 301.1),
]

let points2 = [
    Vector(614.6, 627.0),
    Vector(748.4, 509.1),
    Vector(747.5, 506.5),
    Vector(541.2, 272.1),
    Vector(234.5, 376.4),
    Vector(235.2, 376.3),
    Vector(316.5, 664.2)
]

let points3 = [
    Vector(581.0, 542.5),
    Vector(968.0, 652.0),
    Vector(756.5, 419.5),
    Vector(958.0, 256.5),
    Vector(666.0, 319.0),
    Vector(537.0, 156.0),
    Vector(397.0, 281.0),
    Vector(147.5, 329.5),
    Vector(137.0, 561.0),
    Vector(421.5, 466.0),
    Vector(550.5, 667.5)
]

let points4 = [
    Vector(999.5, 580.0),
    Vector(1050.0, 670.0),
    Vector(1079.5, 447.5),
    Vector(924.0, 379.0),
    Vector(793.5, 349.0),
    Vector(713.0, 393.0),
    Vector(667.0, 453.0),
    Vector(590.5, 357.5),
    Vector(652.5, 277.5),
    Vector(565.0, 237.0),
    Vector(506.5, 246.5),
    Vector(436.0, 331.5),
    Vector(403.0, 444.0),
    Vector(437.5, 563.5),
    Vector(547.0, 632.0),
    Vector(636.5, 653.5),
    Vector(725.0, 663.5),
    Vector(832.0, 666.0),
    Vector(974.0, 666.5)
]

let points5 = [
    Vector(617.0, 628.5),
    Vector(814.0, 423.0),
    Vector(618.5, 152.5),
    Vector(399.5, 167.5),
    Vector(341.0, 395.0),
    Vector(585.5, 635.0)
]

//Complex
let points6 = [
Vector(462.0, 614.5),
Vector(808.5, 522.5),
Vector(214.0, 335.5),
Vector(800.5, 289.0),
Vector(196.5, 552.0),
Vector(322.0, 669.0)
]

