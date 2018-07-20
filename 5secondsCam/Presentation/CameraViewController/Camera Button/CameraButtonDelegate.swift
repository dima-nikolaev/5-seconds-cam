//
//  CameraButtonDelegate.swift
//  5secondsCam
//
//  Created by Dima on 7/18/18.
//  Copyright © 2018 Dima Nikolaev. All rights reserved.
//

import Foundation

protocol CameraButtonDelegate: class {
    
    func cameraButtonTookPhoto()
    
    func cameraButtonDidStartVideoRecording()
    func cameraButtonDidPauseVideoRecording()
    func cameraButtonDidFinishVideoRecording()
    
}
