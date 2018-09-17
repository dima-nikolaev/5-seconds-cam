//
//  CameraViewController.swift
//  5secondsCam
//
//  Created by Dima on 7/18/18.
//  Copyright © 2018 Dima Nikolaev. All rights reserved.
//

import UIKit

class CameraViewController: UIViewController {

    private let model: CameraModel
    private let presentationAssembly: PresentationAssembly
    
    init(model: CameraModel, presentationAssembly: PresentationAssembly) {
        self.model = model
        self.presentationAssembly = presentationAssembly
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Views
    
    private lazy var detectionView: DetectionView = {
        let detectionView = DetectionView(frame: CGRect(x: view.bounds.width/2 - 56,
                                                        y: view.safeAreaInsets.top + 15,
                                                        width: 112,
                                                        height: 32))
        detectionView.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
        return detectionView
    }()
    
    private lazy var cameraView: CameraView = {
        let view = CameraView(session: model.captureSession)
        view.delegate = self
        return view
    }()
    
    private lazy var toggleView: CameraToggleView = {
        var bottomIndent: CGFloat {
            if view.bounds.height == 568 {
                return 176
            } else if view.bounds.height == 667 {
                return 166
            } else if view.bounds.height == 736 {
                return 182
            } else {
                return 186
            }
        }
        let safeAreaBottomInset = navigationController?.view.safeAreaInsets.bottom ?? 0
        let origin = CGPoint(x: 0, y: view.bounds.height - safeAreaBottomInset - bottomIndent)
        
        let toggle = CameraToggleView(frame: CGRect(x: origin.x, y: origin.y, width: view.bounds.width, height: 34))
        toggle.delegate = self
        toggle.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        return toggle
    }()
    
    // MARK: - Buttons
    
    private lazy var cameraButton: CameraButton = {
        let diameter: CGFloat = 68
        
        var bottomIndent: CGFloat {
            if view.bounds.height == 568 {
                return 120
            } else if view.bounds.height == 667 {
                return 126
            } else if view.bounds.height == 736 {
                return 142
            } else {
                return 143
            }
        }
        
        let safeAreaBottomInset = navigationController?.view.safeAreaInsets.bottom ?? 0
        let origin = CGPoint(x: view.bounds.width/2 - diameter/2,
                             y: view.bounds.height - safeAreaBottomInset - bottomIndent)
        
        let button = CameraButton(frame: CGRect(x: origin.x, y: origin.y, width: diameter, height: diameter))
        button.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin]
        button.delegate = self
        return button
    }()
    
    private lazy var photoThumbButton: PhotoThumbButton = {
        let button = PhotoThumbButton(frame: CGRect(x: 16,
                                                    y: cameraButton.frame.origin.y + 70,
                                                    width: 56,
                                                    height: 56))
        return button
    }()

    private lazy var flashButton: UIButton = {
        let button = UIButton(frame: CGRect(x: view.bounds.width - 72,
                                            y: cameraButton.frame.origin.y + 70,
                                            width: 56,
                                            height: 56))
        button.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin]
        let image: UIImage?
        switch model.flashMode {
        case .off:
            image = UIImage(named: "flashOff")
        case .on:
            image = UIImage(named: "flashOn")
        case .auto:
            image = UIImage(named: "flashAuto")
        }
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(changeFlashMode), for: .touchUpInside)
        return button
    }()
    
    private lazy var changeCameraButton: UIButton = {
        let button = UIButton(frame: CGRect(x: flashButton.frame.origin.x,
                                            y: flashButton.frame.origin.y - 68,
                                            width: 56,
                                            height: 56))
        button.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin]
        button.setImage(UIImage(named: "changeCamera"), for: .normal)
        button.addTarget(self, action: #selector(changeCamera), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Actions
    
    private func changeCameraPreset() {
        cameraView.hideFocus()
        
        disableCameraButtons(shouldUpdatePhotoThumbButton: true)
        
        model.changeCameraPreset(lastFrameHandler: { (lastFrame) in
            self.cameraView.updateBlurredPreview(to: lastFrame)
            self.layoutCameraView(sessionPreset: self.model.captureSessionPreset, animated: true)
        }, completionHandler: {
            switch self.model.captureSessionPreset {
            case .photo:
                self.cameraButton.preset = .photo
            case .video:
                self.cameraButton.preset = .video
            }
            self.enableCameraButtons(shouldUpdatePhotoThumbButton: true)
            self.cameraView.updateBlurredPreview(to: nil)
        })
    }
    
    @objc private func changeCamera() {
        cameraView.hideFocus()
        
        cameraButton.isEnabled  = false
        flashButton.isEnabled = false
        changeCameraButton.isEnabled = false
        
        model.changeCamera(lastFrameHandler: { (lastFrame) in
            self.cameraView.updateBlurredPreview(to: lastFrame)
        }, completionHandler: {
            self.cameraButton.isEnabled  = true
            self.flashButton.isEnabled = true
            self.changeCameraButton.isEnabled = true
            self.cameraView.updateBlurredPreview(to: nil)
        })
    }
    
    @objc private func changeFlashMode() {
        let image: UIImage?
        switch model.changeFlashMode() {
        case .off:
            image = UIImage(named: "flashOff")
        case .on:
            image = UIImage(named: "flashOn")
        case .auto:
            image = UIImage(named: "flashAuto")
        }
        flashButton.setImage(image, for: .normal)
    }
    
    private func enableCameraButtons(shouldUpdatePhotoThumbButton: Bool = false) {
        updateCameraButtons(isEnabled: true, shouldUpdatePhotoThumbButton: shouldUpdatePhotoThumbButton)
    }
    
    private func disableCameraButtons(shouldUpdatePhotoThumbButton: Bool = false) {
        updateCameraButtons(isEnabled: false, shouldUpdatePhotoThumbButton: shouldUpdatePhotoThumbButton)
    }
    
    private func updateCameraButtons(isEnabled: Bool, shouldUpdatePhotoThumbButton: Bool) {
        cameraButton.isEnabled = isEnabled
        flashButton.isEnabled = isEnabled
        changeCameraButton.isEnabled = isEnabled
        
        guard shouldUpdatePhotoThumbButton, model.captureSessionPreset == .photo else { return }
        
        if isEnabled && photoThumbButton.isEnabled {
            photoThumbButton.alpha = 0
            photoThumbButton.isHidden = false
            UIView.animate(withDuration: cameraView.updateBlurredPreviewAnimationDuration, delay: 0, options: .curveLinear, animations: {
                self.photoThumbButton.alpha = 1
            }, completion: nil)
        } else {
            photoThumbButton.isHidden = true
        }
    }
    
    func turnCameraOn() {
        print(#function)
        handleCameraSetupResult()
    }
    
    func turnCameraOff() {
        print(#function)
        model.turnCameraOff { (frame) in
            self.disableCameraButtons()
            self.cameraView.updateBlurredPreview(to: frame)
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        view.addSubview(cameraView)
        view.addSubview(toggleView)
        view.addSubview(cameraButton)
        view.addSubview(photoThumbButton)
        view.addSubview(changeCameraButton)
        view.addSubview(flashButton)
        view.addSubview(detectionView)
        
        disableCameraButtons()
        
        model.configureCamera {
            self.model.turnCameraOn {
                self.enableCameraButtons()
            }
        }
        
        addSwipeGestures()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print(#function)
        super.viewDidAppear(animated)
        turnCameraOn()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        print(#function)
        super.viewDidDisappear(animated)
        turnCameraOff()
    }
    
    // MARK: - Layout

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutCameraView(sessionPreset: model.captureSessionPreset, animated: false)
    }
    
    private func layoutCameraView(sessionPreset: CaptureSessionPreset, animated: Bool) {
        let cameraViewFrame: CGRect
        switch sessionPreset {
        case .photo:
            var topIndent: CGFloat {
                if view.bounds.height == 812 {
                    return 0
                } else {
                    return navigationController?.navigationBar.frame.height ?? 0
                }
            }
            cameraViewFrame = CGRect(x: 0,
                                     y: view.safeAreaInsets.top - topIndent,
                                     width: view.frame.width,
                                     height: view.frame.width / 0.75)
        case .video:
            cameraViewFrame = view.bounds
        }
        
        if animated {
            UIView.animate(withDuration: 0.25) {
                self.cameraView.frame = cameraViewFrame
            }
        } else {
            cameraView.frame = cameraViewFrame
        }
    }
    
    // MARK: - Camera
    
    private func addSwipeGestures() {
        let swipeGestureRecognizer: UISwipeGestureRecognizer = {
            let recognizer = UISwipeGestureRecognizer(target: self, action: #selector(setVideoCameraPreset))
            recognizer.direction = .left
            return recognizer
        }()
        let swipGestureRecognizer: UISwipeGestureRecognizer = {
            let recognizer = UISwipeGestureRecognizer(target: self, action: #selector(setPhotoCameraPreset))
            return recognizer
        }()
        view.addGestureRecognizer(swipeGestureRecognizer)
        view.addGestureRecognizer(swipGestureRecognizer)
    }
    
    private func handleCameraSetupResult() {
        switch model.cameraSetupResult {
        case .success:
            model.turnCameraOn {
                self.enableCameraButtons()
                self.cameraView.updateBlurredPreview(to: nil)
            }
        case .notDetermined,
             .notAuthorized,
             .configurationFaild:
            showInfoView(cameraSetupResult: model.cameraSetupResult)
        }
    }
    
    @objc private func setVideoCameraPreset() {
        guard
            toggleView.segment == .photo,
            !model.captureSessionIsConfiguring,
            cameraView.shouldMakeChanges else { return }
        
        changeCameraPreset()
        toggleView.setSegment(.video)
    }
    
    @objc private func setPhotoCameraPreset() {
        guard
            toggleView.segment == .video,
            !model.captureSessionIsConfiguring,
            cameraView.shouldMakeChanges else { return }
        changeCameraPreset()
        toggleView.setSegment(.photo)
    }
    
    private func showInfoView(cameraSetupResult: CameraSetupResult) {
        switch cameraSetupResult {
        case .success:
            break
        case .notDetermined:
            let title = "Allow the Access to the Camera"
            let message = "To create selfies allow the access to the camera of your iPhone."
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                self.model.requestAccessToCamera(completionHandler: { (success) in
                    if success {
                        self.model.configureCamera {
                            self.model.turnCameraOn {
                                self.enableCameraButtons()
                                self.cameraView.updateBlurredPreview(to: nil)
                            }
                        }
                        
                    } else {
                        self.showInfoView(cameraSetupResult: .notAuthorized)
                    }
                })
            }))
            present(alert, animated: true, completion: nil)
            
        case .notAuthorized:
            let title = "Allow the Access to the Camera in Settings"
            let message = "To create selfies allow the access to the camera of your iPhone."
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                guard
                    let appSettingsURL = URL(string: UIApplicationOpenSettingsURLString),
                    UIApplication.shared.canOpenURL(appSettingsURL) else { return }
                UIApplication.shared.open(appSettingsURL, options: [:], completionHandler: nil)
            }))
            present(alert, animated: true, completion: nil)
            
        case .configurationFaild:
            let title = "Something went wrong"
            let message = "An error occurred while configuring the camera."
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            present(alert, animated: true, completion: nil)
        }
    }

}

// MARK: - Camera Model Delegate

extension CameraViewController: CameraModelDelegate {
    
    func cameraSubjectAreaDidChange() {
        cameraView.hideFocus()
    }
    
    func newQuadrilateralWasDetect(quadrilateral: Quadrilateral?, isIphone: Bool) {
        DispatchQueue.main.async {
            self.detectionView.state = isIphone ? .iPhone : .notIPhone
            self.cameraView.draw(quadrilateral)
        }
    }
    
}

// MARK: - Camera View Delegate

extension CameraViewController: CameraViewDelegate {
    
    func cameraViewFocus(on devicePoint: CGPoint) {
        model.focus(with: .autoFocus, exposureMode: .autoExpose, at: devicePoint, monitorSubjectAreaChange: true)
    }
    
    func cameraViewUpdateExposure(value: Float) {
        model.updateExposure(value: value)
    }
    
}

// MARK: - Camera Button Delegate

extension CameraViewController: CameraButtonDelegate {
    
    func cameraButtonTookPhoto() {
        model.capturePhoto(willCaptureAnimation: {
            self.cameraView.layer.opacity = 0.25
            UIView.animate(withDuration: 0.25) {
                self.cameraView.layer.opacity = 1
            }
        }) { (error, preview, data) in
            self.photoThumbButton.updateThumb(to: preview)
        }
    }
    
    func cameraButtonDidStartVideoRecording() {
        toggleView.isUserInteractionEnabled = false
        changeCameraButton.isUserInteractionEnabled = false
        flashButton.isUserInteractionEnabled = false
        
        UIView.animate(withDuration: 0.1) {
            self.toggleView.alpha = 0
            self.changeCameraButton.alpha = 0
            self.flashButton.alpha = 0
        }
        model.startRecording()
    }
    
    func cameraButtonDidPauseVideoRecording() {
        model.pauseRecording()
    }
    
    func cameraButtonDidFinishVideoRecording() {
        UIView.animate(withDuration: 0.1, delay: 0.1, options: .curveEaseInOut, animations: {
            self.toggleView.alpha = 1
            self.changeCameraButton.alpha = 1
            self.flashButton.alpha = 1
        }) { (_) in
            self.toggleView.isUserInteractionEnabled = true
            self.changeCameraButton.isUserInteractionEnabled = true
            self.flashButton.isUserInteractionEnabled = true
        }
        model.finishRecording()
    }
    
}

// MARK: - Toggle View Delegate

extension CameraViewController: CameraToggleViewDelegate {
    
    func toggleViewSelect(segment: CameraToggleViewSegment) {
        changeCameraPreset()
    }
    
    func toggleViewShouldSelectSegment() -> Bool {
        return !model.captureSessionIsConfiguring && cameraView.shouldMakeChanges
    }
    
}

