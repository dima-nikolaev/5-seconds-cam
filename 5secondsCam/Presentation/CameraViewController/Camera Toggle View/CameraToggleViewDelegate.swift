//
//  CameraToggleViewDelegate.swift
//  5secondsCam
//
//  Created by Dima on 7/19/18.
//  Copyright © 2018 Dima Nikolaev. All rights reserved.
//

import Foundation

protocol CameraToggleViewDelegate: class {
    
    func toggleViewSelect(segment: CameraToggleViewSegment)
    func toggleViewShouldSelectSegment() -> Bool
    
}
