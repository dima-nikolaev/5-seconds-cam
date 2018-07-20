//
//  PhotoShootService.swift
//  5secondsCam
//
//  Created by Dima on 7/19/18.
//  Copyright © 2018 Dima Nikolaev. All rights reserved.
//

import AVFoundation
import UIKit

protocol PhotoShootingService {
    
    func addOutput()
    func configureOutput()
    func removeOutput()
    
    func capture(flashMode: AVCaptureDevice.FlashMode,
                 livePhotoMode: Bool,
                 depthDataMode: Bool,
                 willCaptureAnimation: @escaping () -> Void,
                 completion: @escaping (_ error: Error?, _ preview: UIImage?, _ data: Data?) -> Void)
    
}
