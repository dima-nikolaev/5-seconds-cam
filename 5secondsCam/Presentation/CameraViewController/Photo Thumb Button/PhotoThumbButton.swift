//
//  PhotoThumbButton.swift
//  5secondsCam
//
//  Created by Dima on 7/18/18.
//  Copyright © 2018 Dima Nikolaev. All rights reserved.
//

import UIKit

public class PhotoThumbButton: UIButton {
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin]
        addSubview(bottomImageView)
        addSubview(topImageView)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func updateThumb(to newThumb: UIImage?) {
        topImageView.image = newThumb
        topImageView.isHidden = false
        UIView.animateKeyframes(withDuration: 0.266, delay: 0, options: .calculationModeCubic, animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5) {
                let scaleTransform = CGAffineTransform(scaleX: 0.88, y: 0.88)
                self.bottomImageView.transform = scaleTransform
                self.topImageView.transform = scaleTransform
            }
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                self.bottomImageView.transform = .identity
                self.topImageView.transform = .identity
            }
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1) {
                self.topImageView.alpha = 1
            }
        }) { (_) in
            self.bottomImageView.image = newThumb
            self.topImageView.isHidden = true
            self.topImageView.alpha = 0
        }
    }
    
    private lazy var bottomImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 3,
                                                  y: 3,
                                                  width: bounds.width - 6,
                                                  height: bounds.height - 6))
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 2
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var topImageView: UIImageView = {
        let imageView = UIImageView(frame: bottomImageView.frame)
        imageView.contentMode = bottomImageView.contentMode
        imageView.layer.cornerRadius = bottomImageView.layer.cornerRadius
        imageView.clipsToBounds = bottomImageView.clipsToBounds
        imageView.isHidden = true
        imageView.alpha = 0
        return imageView
    }()
    
}
