//
//  UUtilities.swift
//  Metallic
//
//  Created by Akshay on 23/09/19.
//  Copyright © 2019 Fluid Touch Pte Ltd. All rights reserved.
//

import Foundation

#if os(macOS)
import AppKit
typealias PlatformController = NSViewController
typealias PlatformView = NSView
#else
import UIKit
typealias PlatformController = UIViewController
typealias PlatformView = UIView
#endif

extension UIColor {
    static var random : UIColor {
        return UIColor(red: CGFloat.random(in: 0...1),
                       green: CGFloat.random(in: 0...1),
                       blue: CGFloat.random(in: 0...1),
                       alpha: 1.0)
    }
}
