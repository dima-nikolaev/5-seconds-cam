//
//  CameraModelDelegate.swift
//  5secondsCam
//
//  Created by Dima on 7/19/18.
//  Copyright © 2018 Dima Nikolaev. All rights reserved.
//

import Foundation

protocol CameraModelDelegate: class {
    
    func cameraSubjectAreaDidChange()
    func newQuadrilateralWasDetect(quadrilateral: Quadrilateral)
    
}
