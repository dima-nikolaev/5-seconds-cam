//
//  Quadrilateral.swift
//  5secondsCam
//
//  Created by Dima on 14/09/2018.
//  Copyright © 2018 Dima Nikolaev. All rights reserved.
//

import UIKit

struct Quadrilateral {
    
    let bounds: CGRect
    
    let topLeft: CGPoint
    let topRight: CGPoint
    let bottomLeft: CGPoint
    let bottomRight: CGPoint
    
    let frameSize: CGSize
    
    func scaled(by ratio: CGFloat) -> Quadrilateral {
        return Quadrilateral(bounds: CGRect(x: bounds.origin.x * ratio,
                                            y: bounds.origin.y * ratio,
                                            width: bounds.width * ratio,
                                            height: bounds.height * ratio),
                             topLeft: CGPoint(x: topLeft.x * ratio,
                                              y: topLeft.y * ratio),
                             topRight: CGPoint(x: topRight.x * ratio,
                                               y: topRight.y * ratio),
                             bottomLeft: CGPoint(x: bottomLeft.x * ratio,
                                                 y: bottomLeft.y * ratio),
                             bottomRight: CGPoint(x: bottomRight.x * ratio,
                                                  y: bottomRight.y * ratio),
                             frameSize: CGSize(width: frameSize.width * ratio,
                                               height: frameSize.height * ratio))
    }
    
}

extension Quadrilateral: CustomStringConvertible {
    
    var description: String {
        return """
        Extent: (\(frameSize.width), \(frameSize.height).
        Points: \(topLeft), \(topRight), \(bottomLeft), \(bottomRight).
        """
    }
    
}
