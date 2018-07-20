//
//  VideoRecordingServiceImp.swift
//  5secondsCam
//
//  Created by Dima on 7/19/18.
//  Copyright © 2018 Dima Nikolaev. All rights reserved.
//

import AVFoundation
import Photos

class VideoRecordingServiceImp: NSObject, VideoRecordingService {
    
    private let session: AVCaptureSession
    private let queue: DispatchQueue
    
    init(session: AVCaptureSession, queue: DispatchQueue) {
        self.session = session
        self.queue = queue
        super.init()
    }
    
    private lazy var dataOutput: AVCaptureVideoDataOutput = {
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: queue)
        return output
    }()
    
    private var isRecording = false
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var pauseTime = kCMTimeZero
    private var timeOffset = kCMTimeZero
    
    private let videoPath = (NSTemporaryDirectory() as NSString)
        .appendingPathComponent(("video" as NSString)
        .appendingPathExtension("mov")!)
    
    private lazy var videoURL = URL(fileURLWithPath: videoPath)
    
    private func cleanUp() {
        assetWriter = nil
        pauseTime = kCMTimeZero
        timeOffset = kCMTimeZero
        
        if FileManager.default.fileExists(atPath: videoPath) {
            do {
                try FileManager.default.removeItem(atPath: videoPath)
            } catch {
                print(error)
            }
        }
    }
    
    func adjustedSampleBuffer(sample: CMSampleBuffer, offset: CMTime) -> CMSampleBuffer {
        var count: CMItemCount = 0
        CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
        var info = [CMSampleTimingInfo](repeating: CMSampleTimingInfo(duration: kCMTimeZero,
                                                                      presentationTimeStamp: kCMTimeZero,
                                                                      decodeTimeStamp: kCMTimeZero), count: count)
        CMSampleBufferGetSampleTimingInfoArray(sample, count, &info, &count);
        
        for i in 0..<count {
            info[i].decodeTimeStamp = CMTimeSubtract(info[i].decodeTimeStamp, offset);
            info[i].presentationTimeStamp = CMTimeSubtract(info[i].presentationTimeStamp, offset);
        }
        
        var out: CMSampleBuffer?
        CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, &info, &out);
        return out!
    }
    
    // MARK: - Video Recording Service
    
    func addOutput() {
        guard session.canAddOutput(dataOutput) else { return }
        session.addOutput(dataOutput)
        configureOutputConnection()
    }
    
    func configureOutputConnection() {
        guard let connection = dataOutput.connection(with: .video) else { return }
        connection.videoOrientation = .portrait
        if connection.isVideoStabilizationSupported {
            connection.preferredVideoStabilizationMode = .auto
        }
    }
    
    func startRecording() {
        guard let lastSampleBuffer = lastSampleBuffer else { return }
        let startTime = CMSampleBufferGetPresentationTimeStamp(lastSampleBuffer)
        
        guard assetWriter == nil else {
            isRecording = true
            let timeOffset = CMTimeSubtract(startTime, pauseTime)
            self.timeOffset = CMTimeAdd(self.timeOffset, timeOffset)
            return
        }
        
        assetWriter = try? AVAssetWriter(url: videoURL, fileType: .mov)
        
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: nil)
        videoInput.expectsMediaDataInRealTime = true
        assetWriter?.add(videoInput)
        self.videoInput = videoInput
        
        isRecording = true
    }
    
    func pauseRecording() {
        isRecording = false
        guard let lastSampleBuffer = lastSampleBuffer else { return }
        let currentTime = CMSampleBufferGetPresentationTimeStamp(lastSampleBuffer)
        pauseTime = currentTime
    }
    
    func finishRecording() {
        isRecording = false
        assetWriter?.finishWriting {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.videoURL)
            }, completionHandler: { (success, error) in
                self.cleanUp()
            })
        }
    }
    
    private(set) var lastSampleBuffer: CMSampleBuffer?
    
}

// MARK: - Data Output Sample Buffer Delegate

extension VideoRecordingServiceImp: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        lastSampleBuffer = sampleBuffer
        guard isRecording else { return }
        if let writerStatus = assetWriter?.status, writerStatus == .unknown {
            let startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            assetWriter?.startWriting()
            assetWriter?.startSession(atSourceTime: startTime)
        }
        guard CMSampleBufferDataIsReady(sampleBuffer) else { return }
        let adjustedBuffer = adjustedSampleBuffer(sample: sampleBuffer, offset: timeOffset)
        videoInput?.append(adjustedBuffer)
    }
    
}
