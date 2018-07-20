//
//  PresentationAssemblyImp.swift
//  5secondsCam
//
//  Created by Dima on 7/19/18.
//  Copyright © 2018 Dima Nikolaev. All rights reserved.
//

import Foundation

class PresentationAssemblyImp {
    
    /*
    private let serviceAssembly: ServiceAssembly
    
    init(serviceAssembly: ServiceAssembly) {
        self.serviceAssembly = serviceAssembly
    }
    */
    
}

extension PresentationAssemblyImp: PresentationAssembly {
    
    func makeCameraViewController() -> CameraViewController {
        let model = CameraModelImp()
        let controller = CameraViewController(model: model, presentationAssembly: self)
        model.delegate = controller
        return controller
    }
    
}
