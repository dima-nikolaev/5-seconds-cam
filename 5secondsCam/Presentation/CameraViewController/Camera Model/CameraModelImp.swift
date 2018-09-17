//
//  CameraModelImp.swift
//  5secondsCam
//
//  Created by Dima on 7/18/18.
//  Copyright © 2018 Dima Nikolaev. All rights reserved.
//

import AVFoundation
import UIKit

class CameraModelImp: CameraModel {
    
    private lazy var photoShootingService: PhotoShootingService = PhotoShootingServiceImp(session: captureSession,
                                                                                          queue: captureSessionQueue)
    private lazy var videoRecordingService: VideoRecordingService = {
        let service = VideoRecordingServiceImp(session: captureSession,
                                            queue: captureSessionQueue)
        service.delegate = self
        return service
    }()
    private lazy var quadrilateralDetector: QuadrilateralDetectionService = QuadrilateralDetectionServiceImp()
    
    init() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraSetupResult = .success
        case .notDetermined:
            cameraSetupResult = .notDetermined
        case .denied, .restricted:
            cameraSetupResult = .notAuthorized
        }
    }
    
    private var discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                                                                    mediaType: AVMediaType.video,
                                                                    position: .unspecified)
    
    private lazy var captureSessionQueue = DispatchQueue(label: "com.dimanikolaev.5secondsCam.cameraCaptureQueue",
                                                         qos: .userInteractive)
    
    private(set) var camera: AVCaptureDevice?
    
    private func getFrame(cameraPosition: AVCaptureDevice.Position) -> UIImage? {
        guard
            let sampleBuffer = videoRecordingService.lastSampleBuffer,
            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        var coreImage = CIImage(cvImageBuffer: imageBuffer)
        coreImage = coreImage
            .transformed(by: coreImage.orientationTransform(for: cameraPosition == .back ? .up : .upMirrored))
        return UIImage(ciImage: coreImage)
    }
    
    private(set) var captureSessionIsConfiguring = false
    
    private(set) var captureSessionPreset = CaptureSessionPreset.photo
    
    private func configureCaptureSession(completionHandler: () -> Void) {
        guard cameraSetupResult == .success else { return }
        
        captureSessionIsConfiguring = true
        
        var newCameraSetupResult = CameraSetupResult.configurationFaild
        
        defer {
            captureSession.commitConfiguration()
            cameraSetupResult = newCameraSetupResult
            captureSessionIsConfiguring = false
            completionHandler()
        }
        
        captureSession.beginConfiguration()
        
        captureSession.sessionPreset = .photo
        
        // Camera
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
        
        self.camera = camera
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: camera)
            guard captureSession.canAddInput(videoInput) else { return }
            captureSession.addInput(videoInput)
        } catch {
            print(error)
            return
        }
        
        videoRecordingService.addOutput()
        photoShootingService.addOutput()
        
        newCameraSetupResult = .success
    }
    
    @objc private func subjectAreaDidChange(notification: NSNotification) {
        delegate?.cameraSubjectAreaDidChange()
        let devicePoint = CGPoint(x: 0.5, y: 0.5)
        focus(with: .continuousAutoFocus, exposureMode: .continuousAutoExposure, at: devicePoint, monitorSubjectAreaChange: false)
    }
    
    // MARK: - Camera Model
    
    // MARK: Configuration
    
    weak var delegate: CameraModelDelegate?
    
    private(set) var captureSession = AVCaptureSession()
    
    private(set) var cameraSetupResult = CameraSetupResult.notDetermined
    
    func requestAccessToCamera(completionHandler: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { (successForVideo) in
            DispatchQueue.main.async {
                self.cameraSetupResult = successForVideo ? .success : .notAuthorized
                completionHandler(successForVideo)
            }
        }
    }
    
    func configureCamera(completionHandler: @escaping () -> Void) {
        captureSessionQueue.async {
            self.configureCaptureSession(completionHandler: completionHandler)
        }
    }
    
    // MARK: Input Setup
    
    func focus(with focusMode: AVCaptureDevice.FocusMode,
               exposureMode: AVCaptureDevice.ExposureMode,
               at devicePoint: CGPoint,
               monitorSubjectAreaChange: Bool) {
        captureSessionQueue.async {
            guard let device = self.camera else { return }
            self.maxExposureTargetBias = device.maxExposureTargetBias
            self.exposureTargetBias = device.exposureTargetBias
            self.minExposureTargetBias = device.minExposureTargetBias
            do {
                try device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = focusMode
                }
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = exposureMode
                }
                device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
            } catch {
                print(error)
            }
        }
    }
    
    private var maxExposureTargetBias: Float = 0
    private var exposureTargetBias: Float = 0
    private var minExposureTargetBias: Float = 0
    
    func updateExposure(value: Float) {
        captureSessionQueue.async {
            guard let device = self.camera else { return }
            do {
                try device.lockForConfiguration()
                device.isSubjectAreaChangeMonitoringEnabled = false
                let bias: Float
                if value >= 0 {
                    bias = self.exposureTargetBias + value * ((self.maxExposureTargetBias - self.exposureTargetBias) * 0.66)
                } else {
                    bias = self.exposureTargetBias + value * ((self.exposureTargetBias - self.minExposureTargetBias) * 0.66)
                }
                device.setExposureTargetBias(bias, completionHandler: nil)
                device.unlockForConfiguration()
            } catch {
                print(error)
            }
        }
    }
    
    private(set) lazy var flashMode: AVCaptureDevice.FlashMode = {
        let rawValue = UserDefaults.standard.integer(forKey: "CameraModel.flashMode")
        return AVCaptureDevice.FlashMode(rawValue: rawValue) ?? .off
    }()
    
    func changeFlashMode() -> AVCaptureDevice.FlashMode {
        let newRawValue = flashMode.rawValue + 1
        if newRawValue < 3 {
            flashMode = AVCaptureDevice.FlashMode(rawValue: newRawValue) ?? .off
        } else {
            flashMode = .off
        }
        UserDefaults.standard.set(flashMode.rawValue, forKey: "CameraModel.flashMode")
        return flashMode
    }
    
    // MARK: Camera & Camera Preset
    
    func changeCameraPreset(lastFrameHandler: @escaping (UIImage?) -> Void, completionHandler: @escaping () -> Void) {
        guard let cameraPosition = camera?.position else { return }
        
        self.captureSessionIsConfiguring = true
        
        captureSessionPreset = captureSessionPreset == .photo ? .video : .photo
        
        let frame = getFrame(cameraPosition: cameraPosition)
        lastFrameHandler(frame)
        
        captureSessionQueue.async {
            self.captureSession.beginConfiguration()
            if self.captureSession.sessionPreset == .photo {
                self.captureSession.sessionPreset = .hd1280x720
                self.photoShootingService.removeOutput()
                self.videoRecordingService.configureOutputConnection()
            } else {
                self.captureSession.sessionPreset = .photo
                self.photoShootingService.addOutput()
            }
            self.captureSession.commitConfiguration()
            DispatchQueue.main.async {
                self.captureSessionIsConfiguring = false
                completionHandler()
            }
        }
    }
    
    func changeCamera(lastFrameHandler: @escaping (UIImage?) -> Void, completionHandler: @escaping () -> Void) {
        guard let oldDevice = camera else { return }
        
        let frame = getFrame(cameraPosition: oldDevice.position)
        lastFrameHandler(frame)
        
        captureSessionQueue.async {
            let currentPosition = oldDevice.position
            
            let preferredPosition: AVCaptureDevice.Position
            let preferredDeviceType: AVCaptureDevice.DeviceType
            
            switch currentPosition {
            case .unspecified, .front:
                preferredPosition = .back
                preferredDeviceType = .builtInDualCamera
                
            case .back:
                preferredPosition = .front
                preferredDeviceType = .builtInTrueDepthCamera
            }
            
            let devices = self.discoverySession.devices
            var newVideoDevice: AVCaptureDevice? = nil
            
            if let device = devices.first(where: { $0.position == preferredPosition && $0.deviceType == preferredDeviceType }) {
                newVideoDevice = device
            } else if let device = devices.first(where: { $0.position == preferredPosition }) {
                newVideoDevice = device
            }
            
            guard let newDevice = newVideoDevice else {
                DispatchQueue.main.async { completionHandler() }
                return
            }
            
            do {
                let videoDeviceInput = try AVCaptureDeviceInput(device: newDevice)
                
                self.captureSession.beginConfiguration()
                
                self.captureSession.inputs.forEach { (input) in
                    self.captureSession.removeInput(input)
                }
                
                if self.captureSession.canAddInput(videoDeviceInput) {
                    NotificationCenter.default.removeObserver(self,
                                                              name: .AVCaptureDeviceSubjectAreaDidChange,
                                                              object: oldDevice)
                    NotificationCenter.default.addObserver(self,
                                                           selector: #selector(self.subjectAreaDidChange),
                                                           name: .AVCaptureDeviceSubjectAreaDidChange,
                                                           object: newDevice)
                    self.captureSession.addInput(videoDeviceInput)
                    self.camera = newDevice
                }
                
                self.videoRecordingService.configureOutputConnection()
                self.photoShootingService.configureOutput()
                
                self.captureSession.commitConfiguration()
            } catch {
                print(error)
            }
            DispatchQueue.main.async { completionHandler() }
        }
    }
    
    // MARK: Lifecycle
    
    func turnCameraOn(completionHandler: @escaping () -> Void) {
        if let device = camera {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(subjectAreaDidChange),
                                                   name: .AVCaptureDeviceSubjectAreaDidChange,
                                                   object: device)
        }
        
        captureSessionQueue.async {
            if self.cameraSetupResult == .success && !self.captureSessionIsConfiguring && !self.captureSession.isRunning {
                self.captureSession.startRunning()
                DispatchQueue.main.async { completionHandler() }
            }
        }
    }
    
    func turnCameraOff(lastFrameHandler: @escaping (UIImage?) -> Void) {
        NotificationCenter.default.removeObserver(self)
        
        if let device = camera, let frame = getFrame(cameraPosition: device.position) {
            lastFrameHandler(frame)
        }
        
        captureSessionQueue.async {
            if self.cameraSetupResult == .success && self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
            
        }
    }
    
    // MARK: Video Recording
    
    func startRecording() {
        captureSessionQueue.async {
            self.videoRecordingService.startRecording()
        }
    }
    
    func pauseRecording() {
        captureSessionQueue.async {
            self.videoRecordingService.pauseRecording()
        }
    }
    
    func finishRecording() {
        captureSessionQueue.async {
            self.videoRecordingService.finishRecording()
        }
    }
    
    // MARK: Photo Capturing
    
    func capturePhoto(willCaptureAnimation: @escaping () -> Void,
                      completion: @escaping (_ error: Error?, _ preview: UIImage?, _ data: Data?) -> Void) {
        photoShootingService.capture(flashMode: flashMode,
                                     livePhotoMode: true,
                                     depthDataMode: true,
                                     willCaptureAnimation: willCaptureAnimation,
                                     completion: completion)
    }
    
}

extension CameraModelImp: VideoRecordingServiceDelegate {
    
    func sampleBufferWasUpdate(newSampleBuffer: CMSampleBuffer) {
        let result = quadrilateralDetector.detect(in: newSampleBuffer)
        delegate?.newQuadrilateralWasDetect(quadrilateral: result.quadrilateral,
                                            isIphone: result.isIphone)
    }
    
}

