//
//  DetectionView.swift
//  5secondsCam
//
//  Created by Dima on 14/09/2018.
//  Copyright © 2018 Dima Nikolaev. All rights reserved.
//

import UIKit

class DetectionView: UIView {
    
    var state = InfoViewState.notIPhone {
        didSet {
            switch state {
            case .iPhone:
                label.backgroundColor = .green
            case .notIPhone:
                label.backgroundColor = .red
            }
            label.text = state.rawValue
        }
    }
    
    private lazy var label: UILabel = {
        let label = UILabel(frame: bounds)
        label.backgroundColor = .red
        label.textColor = .white
        label.text = "Not iPhone"
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.masksToBounds = true
        layer.cornerRadius = bounds.height/2
        addSubview(label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

enum InfoViewState: String {
    case
    iPhone,
    notIPhone = "Not iPhone"
}
