//
//  ShapeSelectionViewController.swift
//  Shapes
//
//  Created by Akshay Pakanati on 8/28/18.
//  Copyright © 2018 Ak Inc. All rights reserved.
//

import UIKit

class ShapeSelectionViewController: UIViewController {
    
    var shapeSelected : ((ShapeType) -> Void)?
    
    var shapes : [ShapeType] = [.roundRectangle]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

}

extension ShapeSelectionViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shapes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "shapeCell", for: indexPath)
        cell.textLabel?.text = shapes[indexPath.row].rawValue
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {        
        self.dismiss(animated: true) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.shapeSelected?(strongSelf.shapes[indexPath.row])
        }
    }
}
