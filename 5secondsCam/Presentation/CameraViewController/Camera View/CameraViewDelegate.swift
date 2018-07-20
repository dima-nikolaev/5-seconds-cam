//
//  CameraViewDelegate.swift
//  5secondsCam
//
//  Created by Dima on 7/19/18.
//  Copyright © 2018 Dima Nikolaev. All rights reserved.
//

import UIKit

protocol CameraViewDelegate: class {
    
    func cameraViewFocus(on devicePoint: CGPoint)
    func cameraViewUpdateExposure(value: Float)
    
}
