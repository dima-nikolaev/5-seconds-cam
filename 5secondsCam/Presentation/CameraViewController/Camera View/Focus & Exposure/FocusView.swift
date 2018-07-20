//
//  FocusView.swift
//  5secondsCam
//
//  Created by Dima on 7/19/18.
//  Copyright © 2018 Dima Nikolaev. All rights reserved.
//

import UIKit

class FocusView: UIView {
    
    func setExposureLinePosition(to newValue: CGFloat) {
        guard newValue >= -1 && newValue <= 1 else { return }
        exposureLinePosition = newValue
    }
    
    private(set) var exposureLinePosition: CGFloat = 0 {
        didSet {
//            setNeedsDisplay()
        }
    }
    
    init() {
        let diameter: CGFloat = 44
        self.diameter = diameter
        
        super.init(frame: CGRect(x: 0, y: 0, width: diameter, height: diameter))
        
        layer.cornerRadius = radius
        layer.borderWidth = lineWidth
        layer.borderColor = tint.cgColor
        layer.masksToBounds = true
        backgroundColor = .clear
    }
    
    private let diameter: CGFloat
    private lazy var radius = diameter / 2
    
    private let lineWidth: CGFloat = 1.4
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var tintColor: UIColor! {
        get { return tint }
        set { tint = newValue }
    }
    
    private var tint = UIColor(red: 0.988235294, green: 0.811764706, blue: 0.011764706, alpha: 1)
    
    public override func draw(_ rect: CGRect) {
        let path = UIBezierPath()
        path.lineWidth = lineWidth
//        let y = radius - radius*exposureLinePosition
        let y = radius
        path.move(to: CGPoint(x: 0, y: y))
        path.addLine(to: CGPoint(x: diameter, y: y))
        tint.setStroke()
        path.stroke()
    }
    
}
