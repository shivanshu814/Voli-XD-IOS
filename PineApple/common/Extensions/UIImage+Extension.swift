//
//  UIImage+Extension.swift
//  NBCU
//
//  Created by Steven Tao on 7/9/2016.
//  Copyright © 2016 ROKO. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    
    func saveToPath(_ path: String) throws {
        try jpegData(compressionQuality: 0.4)?.write(to: URL(fileURLWithPath: path), options: [.atomic])
    }
    
    func resizeToNormal() -> UIImage {
        return fixOrientation().resizeImage(CGSize(width: 1024, height: 1024))
    }
    
    func resizeToSmall() -> UIImage {
        return fixOrientation().resizeImage(CGSize(width: 400, height: 400))
    }
    
    func resizeToVerySmall() -> UIImage {
        return fixOrientation().resizeImage(CGSize(width: 270, height: 270))
    }
    
    func resizeImageForUpload() -> UIImage {
        if min(size.height, size.width) / 2 <= UIScreen.main.nativeBounds.size.width || max(size.height, size.width) / 2 <= UIScreen.main.nativeBounds.size.height {
            return self
        }
        return resizeImage(CGSize(width: self.size.width/2, height: self.size.height/2))
    }
    
    func resizeImage(_ bound: CGSize) -> UIImage {
        let imgRef = cgImage
        let width = CGFloat(imgRef!.width)
        let height = CGFloat(imgRef!.height)
        
        if width <= bound.width && height <= bound.height {
            return self
        }
        
        let transform = CGAffineTransform.identity
        var rect = CGRect(x: 0, y: 0, width: width, height: height)
        
        if width > bound.width || height > bound.height {
            let ratio = width/height
            if ratio > 1 {
                rect.size.width = bound.width
                rect.size.height = bound.width / ratio
            } else {
                rect.size.height = bound.height;
                rect.size.width = bound.height * ratio
            }
        }
        
        let scaleRatio = rect.size.width / width
        
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 1)
        let context = UIGraphicsGetCurrentContext()
        context!.scaleBy(x: scaleRatio, y: -scaleRatio)
        context!.translateBy(x: 0, y: -height)
        context!.concatenate(transform)
        UIGraphicsGetCurrentContext()!.draw(imgRef!, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        let imageCopy = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return imageCopy ?? self
    }
    
    func cropImage(_ rect: CGRect) -> UIImage {
        if let imageref = cgImage!.cropping(to: rect) {
            return UIImage(cgImage: imageref)
        }
        return self
    }
    
    func cropMediaImage() -> UIImage {
        let rect = CGRect(x: 0, y: size.height/2-67.5, width: size.width, height: 65.0);
        return cropImage(rect)
    }
    
    func fixOrientation() -> UIImage {
        
        // No-op if the orientation is already correct
        if ( self.imageOrientation == UIImage.Orientation.up ) {
            return self;
        }
        
        // We need to calculate the proper transformation to make the image upright.
        // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
        var transform: CGAffineTransform = CGAffineTransform.identity
        
        if ( self.imageOrientation == UIImage.Orientation.down || self.imageOrientation == UIImage.Orientation.downMirrored ) {
            transform = transform.translatedBy(x: self.size.width, y: self.size.height)
            transform = transform.rotated(by: .pi)
        }
        
        if ( self.imageOrientation == UIImage.Orientation.left || self.imageOrientation == UIImage.Orientation.leftMirrored ) {
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.rotated(by: .pi)
        }
        
        if ( self.imageOrientation == UIImage.Orientation.right || self.imageOrientation == UIImage.Orientation.rightMirrored ) {
            transform = transform.translatedBy(x: 0, y: self.size.height);
            transform = transform.rotated(by: (.pi / 2) * -1);
        }
        
        if ( self.imageOrientation == UIImage.Orientation.upMirrored || self.imageOrientation == UIImage.Orientation.downMirrored ) {
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        }
        
        if ( self.imageOrientation == UIImage.Orientation.leftMirrored || self.imageOrientation == UIImage.Orientation.rightMirrored ) {
            transform = transform.translatedBy(x: self.size.height, y: 0);
            transform = transform.scaledBy(x: -1, y: 1);
        }
        
        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.
        let ctx: CGContext = CGContext(data: nil, width: Int(self.size.width), height: Int(self.size.height),
                                                      bitsPerComponent: self.cgImage!.bitsPerComponent, bytesPerRow: 0,
                                                      space: self.cgImage!.colorSpace!,
                                                      bitmapInfo: self.cgImage!.bitmapInfo.rawValue)!;
        
        ctx.concatenate(transform)
        
        if ( self.imageOrientation == UIImage.Orientation.left ||
            self.imageOrientation == UIImage.Orientation.leftMirrored ||
            self.imageOrientation == UIImage.Orientation.right ||
            self.imageOrientation == UIImage.Orientation.rightMirrored ) {
            ctx.draw(self.cgImage!, in: CGRect(x: 0,y: 0,width: self.size.height,height: self.size.width))
        } else {
            ctx.draw(self.cgImage!, in: CGRect(x: 0,y: 0,width: self.size.width,height: self.size.height))
        }
        
        // And now we just create a new UIImage from the drawing context and return it
        return UIImage(cgImage: ctx.makeImage()!)
    }
    
    
    
}
