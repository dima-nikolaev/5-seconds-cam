//
//  QuadrilateralDetectionServiceImp.swift
//  5secondsCam
//
//  Created by Dima on 14/09/2018.
//  Copyright © 2018 Dima Nikolaev. All rights reserved.
//

import AVFoundation
import CoreImage

class QuadrilateralDetectionServiceImp {
    
    private lazy var context: CIContext = {
        if let eaglContext = EAGLContext(api: .openGLES3) {
            return CIContext(eaglContext: eaglContext)
        } else {
            return CIContext(options: nil)
        }
    }()
    
    private lazy var detector = CIDetector(ofType: CIDetectorTypeRectangle,
                                           context: context,
                                           options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])!
    
}

extension QuadrilateralDetectionServiceImp: QuadrilateralDetectionService {
    
    func detect(in sampleBuffer: CMSampleBuffer) -> Quadrilateral? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let frame = CIImage(cvPixelBuffer: pixelBuffer)
        guard
            let rects = detector.features(in: frame) as? [CIRectangleFeature],
            let rect = rects.biggest else { return nil }
        return Quadrilateral(bounds: rect.bounds,
                             topLeft: rect.topLeft,
                             topRight: rect.topRight,
                             bottomLeft: rect.bottomLeft,
                             bottomRight: rect.bottomRight,
                             frameSize: frame.extent.size)
    }
    
}

extension Array where Element: CIRectangleFeature {
    
    var biggest: CIRectangleFeature? {
        guard count > 1 else { return first }
        return self.max(by: { (lhs, rhs) -> Bool in
            return lhs.perimeter < rhs.perimeter
        })
    }
    
}

extension CIRectangleFeature {
    
    var perimeter: CGFloat {
        return    (topRight.x - topLeft.x)
                + (topRight.y - bottomRight.y)
                + (bottomRight.x - bottomLeft.x)
                + (topLeft.y - bottomLeft.y)
    }
    
}
