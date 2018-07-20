//
//  CameraModel.swift
//  5secondsCam
//
//  Created by Dima on 7/18/18.
//  Copyright © 2018 Dima Nikolaev. All rights reserved.
//

import AVFoundation
import UIKit

protocol CameraModel {
    
    // MARK: Configuration
    
    var delegate: CameraModelDelegate? { get set }
    
    var captureSession: AVCaptureSession { get }
    
    var captureSessionIsConfiguring: Bool { get }
    
    var captureSessionPreset: CaptureSessionPreset { get }
    
    var cameraSetupResult: CameraSetupResult { get }
    
    func requestAccessToCamera(completionHandler: @escaping (Bool) -> Void)
    
    func configureCamera(completionHandler: @escaping () -> Void)
    
    // MARK: Input Setup
    
    func focus(with focusMode: AVCaptureDevice.FocusMode,
               exposureMode: AVCaptureDevice.ExposureMode,
               at devicePoint: CGPoint,
               monitorSubjectAreaChange: Bool)
    
    func updateExposure(value: Float)
    
    var flashMode: AVCaptureDevice.FlashMode { get }
    
    func changeFlashMode() -> AVCaptureDevice.FlashMode
    
    // MARK: Camera & Camera Preset
    
    func changeCameraPreset(lastFrameHandler: @escaping (UIImage?) -> Void, completionHandler: @escaping () -> Void)
    
    func changeCamera(lastFrameHandler: @escaping (UIImage?) -> Void, completionHandler: @escaping () -> Void)
    
    // MARK: Lifecycle
    
    func turnCameraOn(completionHandler: @escaping () -> Void)
    func turnCameraOff(lastFrameHandler: @escaping (UIImage?) -> Void)
    
    // MARK: Video Recording
    
    func startRecording()
    func pauseRecording()
    func finishRecording()
    
    // MARK: Photo Capturing
    
    func capturePhoto(willCaptureAnimation: @escaping () -> Void,
                      completion: @escaping (_ error: Error?, _ preview: UIImage?, _ data: Data?) -> Void)
    
}
