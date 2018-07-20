//
//  CameraButton.swift
//  5secondsCam
//
//  Created by Dima on 7/18/18.
//  Copyright © 2018 Dima Nikolaev. All rights reserved.
//

import UIKit

class CameraButton: UIControl {
    
    var preset = CameraButtonPreset.photo
    
    weak var delegate: CameraButtonDelegate?
    
    private var visualState = CameraButtonVisualState.initial
    
    private let photoPresetAnimationDuration = 0.133
    private let videoPresetAnimationDuration = 0.23
    
    private lazy var ovalStrokeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.frame = bounds
        layer.path = CGPath(ellipseIn: initialRect, transform: nil)
        layer.strokeColor = UIColor(white: 1, alpha: 0.98).cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = ovalStrokeLayerLineWidth
        layer.lineCap = kCALineCapRound
        layer.transform = CATransform3DMakeRotation(-1.57079632679, 0, 0, 1)
        return layer
    }()
    
    private lazy var ovalFillLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.frame = bounds
        layer.path = UIBezierPath(roundedRect: initialFillRect,
                                  cornerRadius: initialRect.width/2).cgPath
        layer.fillColor = initialFillColor
        return layer
    }()
    
    private let ovalStrokeLayerLineWidth: CGFloat = 3
    
    private let ovalStrokeAnimationDuration = 5.0
    private var ovalStrokeFromValue: CGFloat = 0
    
    private lazy var strokeEndAnimationFinisher: StrokeEndAnimationFinisher = {
        let finisher = StrokeEndAnimationFinisher()
        finisher.delegate = self
        return finisher
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    private func configure() {
        backgroundColor = .clear
        clipsToBounds = false
        layer.addSublayer(ovalFillLayer)
        layer.addSublayer(ovalStrokeLayer)
    }
    
    // MARK: Rects
    
    private lazy var initialRect: CGRect = {
        return CGRect(x: (bounds.width - bounds.height) / 2,
                      y: 0,
                      width: bounds.height,
                      height: bounds.height)
    }()
    
    private lazy var recordingRect: CGRect = {
        let ratio: CGFloat = 1.8
        let newSize = CGSize(width: ratio * bounds.height, height: ratio * bounds.height)
        return CGRect(x: (bounds.width - newSize.width) / 2,
                      y: (bounds.height - newSize.height) / 2,
                      width: newSize.width,
                      height: newSize.height)
    }()
    
    private lazy var initialFillRect: CGRect = {
        let ratio: CGFloat = 0.88
        let newSize = CGSize(width: ratio * bounds.height, height: ratio * bounds.height)
        return CGRect(x: (bounds.width - newSize.width) / 2,
                      y: (bounds.height - newSize.height) / 2,
                      width: newSize.width,
                      height: newSize.height)
    }()
    
    private lazy var pressedFillRect: CGRect = {
        let ratio: CGFloat = 0.78
        let newSize = CGSize(width: ratio * bounds.height, height: ratio * bounds.height)
        return CGRect(x: (bounds.width - newSize.width) / 2,
                      y: (bounds.height - newSize.height) / 2,
                      width: newSize.width,
                      height: newSize.height)
    }()
    
    private lazy var recordingFillRect: CGRect = {
        let ratio: CGFloat = 0.42
        let newSize = CGSize(width: ratio * bounds.height, height: ratio * bounds.height)
        return CGRect(x: (bounds.width - newSize.width) / 2,
                      y: (bounds.height - newSize.height) / 2,
                      width: newSize.width,
                      height: newSize.height)
    }()
    
    // MARK: Paths
    
    private lazy var initialPath = UIBezierPath(ovalIn: initialRect).cgPath
    
    private lazy var recordingPath = UIBezierPath(ovalIn: recordingRect).cgPath
    
    private lazy var initialFillPath = UIBezierPath(roundedRect: initialFillRect,
                                                    cornerRadius: initialFillRect.width/2).cgPath
    
    private lazy var pressedFillPath = UIBezierPath(roundedRect: pressedFillRect,
                                                    cornerRadius: pressedFillRect.width/2).cgPath
    
    private lazy var recordingFillPath = UIBezierPath(roundedRect: recordingFillRect,
                                                      cornerRadius: 3).cgPath
    
    // MARK: Colors
    
    private lazy var initialFillColor = UIColor(white: 1, alpha: 0.78).cgColor
    private lazy var pressedFillColor = UIColor(white: 1, alpha: 0.78).cgColor
    private lazy var recordingFillColor = UIColor(red: 1, green: 0.149019608, blue: 0, alpha: 1).cgColor
    
}

// MARK: - UIResponer Touches

extension CameraButton {
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch preset {
        case .photo:
            handleTouchesBeganForPhotoPreset()
        case .video:
            handleTouchesBeganForVideoPreset()
        }
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch preset {
        case .photo:
            handleTouchesEndedForPhotoPreset()
        case .video:
            handleTouchesEndedForVideoPreset()
        }
    }
    
    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch preset {
        case .photo:
            handleTouchesEndedForPhotoPreset()
        case .video:
            handleTouchesEndedForVideoPreset()
        }
    }
    
    // MARK: Touches Began
    
    private func handleTouchesBeganForPhotoPreset() {
        switch visualState {
        case .initial:
            visualState = .pressing
            runOvalFillLayerAnimation(fromPath: initialFillPath, toPath: pressedFillPath,
                                      fromColor: initialFillColor, toColor: pressedFillColor,
                                      duration: photoPresetAnimationDuration)
        default:
            break
        }
    }
    
    private func handleTouchesBeganForVideoPreset() {
        switch visualState {
        case .initial:
            visualState = .pressing
            runOvalFillLayerAnimation(fromPath: initialFillPath, toPath: recordingFillPath,
                                      fromColor: initialFillColor, toColor: recordingFillColor,
                                      duration: videoPresetAnimationDuration)
        default:
            break
        }
    }
    
    // MARK: Touches Ended
    
    private func handleTouchesEndedForPhotoPreset() {
        switch visualState {
        case .pressing:
            visualState = .pressed
        case .pressed:
            visualState = .releasing
            delegate?.cameraButtonTookPhoto()
            runOvalFillLayerAnimation(fromPath: pressedFillPath, toPath: initialFillPath,
                                      fromColor: pressedFillColor, toColor: initialFillColor,
                                      duration: photoPresetAnimationDuration)
        default:
            break
        }
    }
    
    private func handleTouchesEndedForVideoPreset() {
        switch visualState {
        case .pressing:
            visualState = .pressed
        case .pressed:
            visualState = .recording
            runOvalStrokeLayerAnimation(fromPath: initialPath, toPath: recordingPath)
            delegate?.cameraButtonDidStartVideoRecording()
            runOvalStrokeLayerAnimation(fromValue: ovalStrokeFromValue)
        case .recording:
            guard let ovalStrokeCurrentValue = ovalStrokeLayer.presentation()?.strokeEnd else { break }
            ovalStrokeFromValue = ovalStrokeCurrentValue
            ovalStrokeLayer.strokeEnd = ovalStrokeCurrentValue
            ovalStrokeLayer.removeAllAnimations()
            visualState = .releasing
            delegate?.cameraButtonDidPauseVideoRecording()
            runOvalFillLayerAnimation(fromPath: recordingFillPath, toPath: initialFillPath,
                                      fromColor: recordingFillColor, toColor: initialFillColor,
                                      duration: videoPresetAnimationDuration)
        default:
            break
        }
    }
    
}

// MARK: - Core Animations

extension CameraButton {
    
    func runOvalFillLayerAnimation(fromPath: CGPath, toPath: CGPath, fromColor: CGColor, toColor: CGColor, duration: CFTimeInterval) {
        let timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        let ovalFillLayerPathAnimation = CABasicAnimation(keyPath: "path")
        ovalFillLayerPathAnimation.fromValue = fromPath
        ovalFillLayerPathAnimation.toValue = toPath
        ovalFillLayerPathAnimation.duration = duration
        ovalFillLayerPathAnimation.timingFunction = timingFunction
        ovalFillLayerPathAnimation.delegate = self
        
        let ovalFillLayerFillColorAnimation = CABasicAnimation(keyPath: "fillColor")
        ovalFillLayerFillColorAnimation.fromValue = fromColor
        ovalFillLayerFillColorAnimation.toValue = toColor
        ovalFillLayerFillColorAnimation.duration = duration
        ovalFillLayerFillColorAnimation.timingFunction = timingFunction
        
        ovalFillLayer.path = toPath
        ovalFillLayer.add(ovalFillLayerPathAnimation, forKey: nil)
        
        ovalFillLayer.fillColor = toColor
        ovalFillLayer.add(ovalFillLayerFillColorAnimation, forKey: nil)
    }
    
    func runOvalStrokeLayerAnimation(fromValue: CGFloat) {
        let duration = Double(1 - ovalStrokeFromValue) * ovalStrokeAnimationDuration
        
        let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeEndAnimation.fromValue = ovalStrokeFromValue
        strokeEndAnimation.toValue = 1
        strokeEndAnimation.duration = duration
        strokeEndAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        strokeEndAnimation.delegate = strokeEndAnimationFinisher
        
        ovalStrokeLayer.strokeEnd = 1
        ovalStrokeLayer.add(strokeEndAnimation, forKey: nil)
    }
    
    func runOvalStrokeLayerAnimation(fromPath: CGPath, toPath: CGPath) {
        let timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        let ovalStrokeLayerPathAnimation = CABasicAnimation(keyPath: "path")
        ovalStrokeLayerPathAnimation.fromValue = fromPath
        ovalStrokeLayerPathAnimation.toValue = toPath
        ovalStrokeLayerPathAnimation.duration = videoPresetAnimationDuration
        ovalStrokeLayerPathAnimation.timingFunction = timingFunction
        
        ovalStrokeLayer.path = toPath
        ovalStrokeLayer.add(ovalStrokeLayerPathAnimation, forKey: nil)
    }
    
}

// MARK: - Core Animations Delegate

extension CameraButton: CAAnimationDelegate {
    
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        switch preset {
        case .photo:
            handleAnimationFinishForPhotoPreset()
        case .video:
            handleAnimationFinishForVideoPreset()
        }
    }
    
}

// MARK: - Finish Animation Handlers

extension CameraButton {
    
    private func handleAnimationFinishForPhotoPreset() {
        switch visualState {
        case .pressing:
            visualState = .pressed
        case .pressed:
            visualState = .releasing
            delegate?.cameraButtonTookPhoto()
            runOvalFillLayerAnimation(fromPath: pressedFillPath, toPath: initialFillPath,
                                      fromColor: pressedFillColor, toColor: initialFillColor,
                                      duration: photoPresetAnimationDuration)
        case .releasing:
            visualState = .initial
        default:
            break
        }
    }
    
    private func handleAnimationFinishForVideoPreset() {
        switch visualState {
        case .pressing:
            visualState = .pressed
        case .pressed:
            visualState = .recording
            runOvalStrokeLayerAnimation(fromPath: initialPath, toPath: recordingPath)
            delegate?.cameraButtonDidStartVideoRecording()
            runOvalStrokeLayerAnimation(fromValue: ovalStrokeFromValue)
        case .releasing:
            visualState = .initial
            runOvalStrokeLayerAnimation(fromPath: recordingPath, toPath: initialPath)
            if ovalStrokeFromValue == 1 {
                ovalStrokeFromValue = 0
                delegate?.cameraButtonDidFinishVideoRecording()
            }
        default:
            break
        }
    }
    
}

// MARK: - Stroke End Animation Finisher & Delegate

extension CameraButton: StrokeEndAnimationFinisherDelegate {
    
    func strokeEndAnimationDidFinish() {
        ovalStrokeFromValue = 1
        visualState = .releasing
        runOvalFillLayerAnimation(fromPath: recordingFillPath, toPath: initialFillPath,
                                  fromColor: recordingFillColor, toColor: initialFillColor,
                                  duration: videoPresetAnimationDuration)
    }
    
}

class StrokeEndAnimationFinisher: NSObject, CAAnimationDelegate {
    
    weak var delegate: StrokeEndAnimationFinisherDelegate?
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            delegate?.strokeEndAnimationDidFinish()
        }
    }
    
}

protocol StrokeEndAnimationFinisherDelegate: class {
    
    func strokeEndAnimationDidFinish()
    
}

