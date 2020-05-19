//
//  ToolbarViewController.swift
//  Metallic
//
//  Created by Akshay on 24/09/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import UIKit

protocol ToolbarActionProtocol: class {
    func toolChanged(tool: DrawingTool)
    func sizeChanged(thickness: Thickness)
    func clearAll()
}

class ToolbarViewController: UIViewController {

    weak var delegate: ToolbarActionProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    @IBAction func toolSegmentChanged(_ segControl: UISegmentedControl) {
        let tool : DrawingTool
        if segControl.selectedSegmentIndex == 0 {
            tool = .pen
        } else if segControl.selectedSegmentIndex == 1 {
            tool = .highlighter
        } else {
            tool = .eraser
        }
        delegate?.toolChanged(tool: tool)
    }

    @IBAction func sizeSegmentChanged(_ segControl: UISegmentedControl) {
        let thickness: Thickness
        if segControl.selectedSegmentIndex == 0 {
            thickness = .small
        } else if segControl.selectedSegmentIndex == 1 {
            thickness = .medium
        } else {
            thickness = .large
        }

        delegate?.sizeChanged(thickness: thickness)
    }

    @IBAction func clearAllTapped(_ sender: UIButton) {
        delegate?.clearAll()
    }

}
