//
//  VideoRecordingService.swift
//  5secondsCam
//
//  Created by Dima on 7/19/18.
//  Copyright © 2018 Dima Nikolaev. All rights reserved.
//

import AVFoundation

protocol VideoRecordingService {
    
    func addOutput()
    func configureOutputConnection()
    
    func startRecording()
    func pauseRecording()
    func finishRecording()
    
    var lastSampleBuffer: CMSampleBuffer? { get }
    
}
