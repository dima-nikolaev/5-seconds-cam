//
//  CameraView.swift
//  5secondsCam
//
//  Created by Dima on 7/19/18.
//  Copyright © 2018 Dima Nikolaev. All rights reserved.
//

import UIKit
import AVFoundation

class CameraView: UIView {
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    var isManualFocusInactive: Bool { return focusExposureView.alpha == 0 }
    
    private(set) var shouldMakeChanges = true
    
    weak var delegate: CameraViewDelegate?
    
    init(session: AVCaptureSession) {
        super.init(frame: .zero)
        
        backgroundColor = .black
        
        previewLayer.session = session
        
        addTapGesture()
        addPanGesture()
        
        addSubview(focusExposureView)
        addSubview(previewContainer)
        
        addSubview(quadrilateralView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func hideFocus() {
        guard focusExposureView.alpha == 1 else { return }
        UIView.animate(withDuration: 0.3333333) {
            self.focusExposureView.alpha = 0
        }
    }
    
    private let previewAnimator = UIViewPropertyAnimator(duration: 0.275, curve: .linear)
    
    var updateBlurredPreviewAnimationDuration: TimeInterval { return previewAnimator.duration }
    
    func updateBlurredPreview(to preview: UIImage?) {
        if let preview = preview {
            previewView.image = preview
            previewContainer.isHidden = false
            previewContainer.alpha = 1
        } else {
            shouldMakeChanges = false
            previewAnimator.addAnimations {
                self.previewContainer.alpha = 0
            }
            previewAnimator.addCompletion { (_) in
                self.previewContainer.isHidden = true
                self.previewView.image = nil
                self.shouldMakeChanges = true
            }
            previewAnimator.startAnimation(afterDelay: 0.05)
        }
    }
    
    private lazy var focusExposureView: FocusExposureView = {
        let view = FocusExposureView()
        view.alpha = 0
        return view
    }()
    
    private lazy var previewView = UIImageView(frame: .zero)
    
    private lazy var blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    
    private lazy var previewContainer: UIView = {
        let container = UIView(frame: bounds)
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.alpha = 0
        container.isHidden = true
        previewView.frame = container.bounds
        previewView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(previewView)
        blurView.frame = container.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(blurView)
        return container
    }()
    
    private lazy var quadrilateralView = QuadrilateralView(frame: bounds)
    
    func draw(_ quadrilateral: Quadrilateral) {
        let ratio = bounds.width / quadrilateral.frameSize.width
        let scaledQuadrilateral = quadrilateral.scaled(by: ratio)
        let path = UIBezierPath()
        path.move(to: scaledQuadrilateral.topLeft)
        path.addLine(to: scaledQuadrilateral.topRight)
        path.addLine(to: scaledQuadrilateral.bottomRight)
        path.addLine(to: scaledQuadrilateral.bottomLeft)
        path.addLine(to: scaledQuadrilateral.topLeft)
        path.close()
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -bounds.height)
        path.apply(transform)
        quadrilateralView.shapeLayer.path = path.cgPath
    }
    
}

// MARK: Focus & Exposure

extension CameraView {
    
    private func addTapGesture() {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(setFocus(recognizer:)))
        addGestureRecognizer(recognizer)
    }
    
    @objc private func setFocus(recognizer: UITapGestureRecognizer) {
        var location = recognizer.location(in: self)
        
        let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: location)
        delegate?.cameraViewFocus(on: devicePoint)
        
        if location.x < 34 {
            location.x = 34
        } else if location.x > bounds.width - 34 {
            location.x = bounds.width - 34
        }
        
        if location.y <  24 {
            location.y = 24
        } else if location.y > bounds.height - 24 {
            location.y = bounds.height - 24
        }
        
        focusExposureView.setExposureLinePosition(to: 0)
        focusExposureView.center = location
        focusExposureView.alpha = 1
    }
    
    private func addPanGesture() {
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(adjustExposure(recognizer:)))
        recognizer.delegate = self
        addGestureRecognizer(recognizer)
    }
    
    @objc private func adjustExposure(recognizer: UIPanGestureRecognizer) {
        let position = -recognizer.translation(in: self).y / bounds.height
        let exposureLinePosition = focusExposureView.exposureLinePosition + position
        focusExposureView.setExposureLinePosition(to: exposureLinePosition)
        delegate?.cameraViewUpdateExposure(value: Float(exposureLinePosition))
        recognizer.setTranslation(.zero, in: self)
    }
    
}

extension CameraView: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == gestureRecognizers?.last {
            return focusExposureView.alpha == 1
        } else if gestureRecognizer == gestureRecognizers?.first {
            return true
        } else {
            return focusExposureView.alpha == 0
        }
    }
    
}

class QuadrilateralView: UIView {
    
    override class var layerClass: AnyClass {
        return CAShapeLayer.self
    }
    
    var shapeLayer: CAShapeLayer {
        return layer as! CAShapeLayer
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.fillColor = UIColor(white: 1, alpha: 0.6666).cgColor
        shapeLayer.lineWidth = 1.8
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
