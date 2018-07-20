//
//  PhotoShootServiceImp.swift
//  5secondsCam
//
//  Created by Dima on 7/19/18.
//  Copyright © 2018 Dima Nikolaev. All rights reserved.
//

import AVFoundation
import Photos
import UIKit

class PhotoShootingServiceImp: NSObject {
    
    private let session: AVCaptureSession
    private let queue: DispatchQueue
    
    init(session: AVCaptureSession, queue: DispatchQueue) {
        self.session = session
        self.queue = queue
        super.init()
    }
    
    private lazy var photoOutput: AVCapturePhotoOutput = {
        let output = AVCapturePhotoOutput()
        output.isHighResolutionCaptureEnabled = true
        return output
    }()
    
    private var willCaptureAnimation: (() -> Void)?
    private var completionHandler: ((Error?, UIImage?, Data?) -> Void)?
    
    private var livePhotoMovieURLs = [Int64: URL]()
    
    private var preview: UIImage?
    private var data: Data?
    
    private func cleanUp(fileURL: URL) {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            try FileManager.default.removeItem(atPath: fileURL.path)
        } catch {
            print(error)
        }
    }

}

// MARK: - Photo Shooting Service

extension PhotoShootingServiceImp: PhotoShootingService {
    
    func addOutput() {
        guard session.canAddOutput(photoOutput) else { return }
        session.addOutput(photoOutput)
        configureOutput()
    }
    
    func configureOutput() {
        photoOutput.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliverySupported
        photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
    }
    
    func removeOutput() {
        session.removeOutput(photoOutput)
    }
    
    func capture(flashMode: AVCaptureDevice.FlashMode,
                 livePhotoMode: Bool,
                 depthDataMode: Bool,
                 willCaptureAnimation: @escaping () -> Void,
                 completion completionHandler: @escaping (Error?, UIImage?, Data?) -> Void) {
        self.willCaptureAnimation = willCaptureAnimation
        self.completionHandler = completionHandler
        
        let settings: AVCapturePhotoSettings
        
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        } else {
            settings = AVCapturePhotoSettings()
        }
        
        settings.flashMode = flashMode
        
        if livePhotoMode && photoOutput.isLivePhotoCaptureSupported {
            let fileName = NSUUID().uuidString
            let filePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((fileName as NSString).appendingPathExtension("mov")!)
            settings.livePhotoMovieFileURL = URL(fileURLWithPath: filePath)
        }
        
        settings.isDepthDataDeliveryEnabled = depthDataMode && photoOutput.isDepthDataDeliverySupported
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
}

// MARK: - Capture Photo Capture Delegate

extension PhotoShootingServiceImp: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        DispatchQueue.main.async {
            self.willCaptureAnimation?()
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let data = photo.fileDataRepresentation() {
            self.data = data
            self.preview = UIImage(data: data)
        }
        completionHandler?(error, preview, data)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingLivePhotoToMovieFileAt outputFileURL: URL,
                     duration: CMTime,
                     photoDisplayTime: CMTime,
                     resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        livePhotoMovieURLs[resolvedSettings.uniqueID] = outputFileURL
    }
    
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
                     error: Error?) {
        guard let data = self.data else { return }
        
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: data, options: nil)
            if let fileURL = self.livePhotoMovieURLs[resolvedSettings.uniqueID] {
                let options = PHAssetResourceCreationOptions()
                options.shouldMoveFile = true
                request.addResource(with: .pairedVideo, fileURL: fileURL, options: options)
            }
        }) { (_, error) in
            guard let fileURL = self.livePhotoMovieURLs[resolvedSettings.uniqueID] else { return }
            self.livePhotoMovieURLs[resolvedSettings.uniqueID] = nil
            self.cleanUp(fileURL: fileURL)
        }
    }
    
}
