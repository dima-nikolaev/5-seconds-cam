//
//  FocusExposureView.swift
//  5secondsCam
//
//  Created by Dima on 7/19/18.
//  Copyright © 2018 Dima Nikolaev. All rights reserved.
//

import UIKit

class FocusExposureView: UIView {
    
    func setExposureLinePosition(to newValue: CGFloat) {
        focusSign.setExposureLinePosition(to: newValue)
        exposureSign.center.y = 21.95 - newValue*22
    }
    
    var exposureLinePosition: CGFloat {
        return focusSign.exposureLinePosition
    }
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 69, height: 44))
        
        exposureSign.tintColor = focusSign.tintColor
        
        focusSign.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        exposureSign.frame = CGRect(x: 51, y: 12.95, width: 18, height: 18)
        
        addSubview(focusSign)
        addSubview(exposureSign)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let focusSign = FocusView()
    private let exposureSign = UIImageView(image: UIImage(named: "focusExposure"))
    
}

