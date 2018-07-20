//
//  CameraToggleView.swift
//  5secondsCam
//
//  Created by Dima on 7/19/18.
//  Copyright © 2018 Dima Nikolaev. All rights reserved.
//

import UIKit

class CameraToggleView: UIView {
    
    weak var delegate: CameraToggleViewDelegate?
    
    private(set) var segment = CameraToggleViewSegment.photo
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        isUserInteractionEnabled = true
        
        let font = UIFont.systemFont(ofSize: 12, weight: .medium)
        let textColor = UIColor.white
        
        photoLabel.text = "PHOTO"
        photoLabel.font = font
        photoLabel.textColor = textColor
        photoLabel.frame.size = photoLabel.intrinsicContentSize
        addSubview(photoLabel)
        
        videoLabel.text = "VIDEO"
        videoLabel.font = font
        videoLabel.textColor = textColor
        videoLabel.frame.size = videoLabel.intrinsicContentSize
        addSubview(videoLabel)
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap(recognizer:))))
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setSegment(_ newSegment: CameraToggleViewSegment) {
        guard newSegment != segment else { return }
        segment = newSegment
        layout(animated: true)
    }
    
    private let photoLabel = UILabel(frame: .zero)
    private let videoLabel = UILabel(frame: .zero)
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layout(animated: false)
    }
    
    private func layout(animated: Bool) {
        let segmentAlpha: CGFloat = 0.41
        let selectedSegmentAlpha: CGFloat = 1
        if animated {
            switch segment {
            case .photo:
                UIView.animate(withDuration: 0.3, delay: 0.1, options: .curveEaseInOut, animations: {
                    self.photoLabel.frame.origin = self.photoLabelOrigin
                    self.photoLabel.alpha = selectedSegmentAlpha
                }, completion: nil)
                UIView.animate(withDuration: 0.3) {
                    self.videoLabel.frame.origin = self.videoLabelOrigin
                    self.videoLabel.alpha = segmentAlpha
                }
            case .video:
                UIView.animate(withDuration: 0.3) {
                    self.photoLabel.frame.origin = self.photoLabelOrigin
                    self.photoLabel.alpha = segmentAlpha
                }
                UIView.animate(withDuration: 0.3, delay: 0.1, options: .curveEaseInOut, animations: {
                    self.videoLabel.frame.origin = self.videoLabelOrigin
                    self.videoLabel.alpha = selectedSegmentAlpha
                }, completion: nil)
            }
        } else {
            photoLabel.frame.origin = photoLabelOrigin
            videoLabel.frame.origin = videoLabelOrigin
            switch segment {
            case .photo:
                photoLabel.alpha = 1
                videoLabel.alpha = 0.41
            case .video:
                photoLabel.alpha = 0.41
                videoLabel.alpha = 1
            }
        }
    }
    
    private var photoLabelOrigin: CGPoint {
        switch segment {
        case .photo:
            return CGPoint(x: bounds.width/2 - photoLabel.frame.width/2,
                           y: bounds.height/2 - photoLabel.frame.height/2)
        case .video:
            return CGPoint(x: 0.25*bounds.width - photoLabel.frame.width/2,
                           y: bounds.height/2 - photoLabel.frame.height/2)
        }
    }
    
    private var videoLabelOrigin: CGPoint {
        switch segment {
        case .photo:
            return CGPoint(x: 0.75*bounds.width - videoLabel.frame.width/2,
                           y: bounds.height/2 - videoLabel.frame.height/2)
        case .video:
            return CGPoint(x: bounds.width/2 - videoLabel.frame.width/2,
                           y: bounds.height/2 - videoLabel.frame.height/2)
        }
    }
    
    @objc private func tap(recognizer: UITapGestureRecognizer) {
        guard let shouldSelect = delegate?.toggleViewShouldSelectSegment(), shouldSelect else { return }
        let location = recognizer.location(in: self)
        let selectedSegment: CameraToggleViewSegment = location.x > bounds.width/2 ? .video : .photo
        guard selectedSegment != segment else { return }
        segment = selectedSegment
        delegate?.toggleViewSelect(segment: segment)
        layout(animated: true)
    }
    
}
