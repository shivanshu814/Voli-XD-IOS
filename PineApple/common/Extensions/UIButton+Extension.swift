//
//  UIButton+Extension.swift
//  PineApple
//
//  Created by Tao Man Kit on 29/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import QuartzCore
import UIKit
import FirebaseUI
import Firebase
import FirebaseStorage

extension UIView {
    
    func addGradient(_ startColor: UIColor, endColor: UIColor, size: CGSize? = nil) {
        if layer.sublayers == nil || (layer.sublayers!.filter {$0 is CAGradientLayer}).isEmpty {
            let gradientLayer:CAGradientLayer = CAGradientLayer()
            gradientLayer.frame.size = size ?? frame.size
            gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
            layer.insertSublayer(gradientLayer, at: 0)
        } else {
            (layer.sublayers!.filter {$0 is CAGradientLayer}).first?.frame.size = frame.size
        }
    }
    
    func playBounceAnimation(_ values: [Any] = [1.0 ,1.4, 0.9, 1.15, 0.95, 1.02, 1.0], duration: CGFloat = 0.4) {
        let bounceAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        bounceAnimation.values = values
        bounceAnimation.duration = TimeInterval(duration)
        bounceAnimation.calculationMode = CAAnimationCalculationMode.cubic        
        layer.add(bounceAnimation, forKey: "bounceAnimation")
    }
    
    
}

extension UIButton {
    func loadImage(_ path: String) {
        if path.starts(with: "/") {
            if let image = UIImage(contentsOfFile: path) {
                setImage(image, for: .normal)
            }
        } else {
            let storageRef = Storage.storage().reference()
            let reference = storageRef.child(path)
            
            imageView?.sd_setImage(with: reference, placeholderImage: nil, completion: {[weak self] (image, error, cacheType, reference) in
                guard let strongSelf = self else { return }
                if image != nil {
                    strongSelf.setImage(image, for: .normal)
                } else {
                    print(error?.localizedDescription ?? "")
                }
            })
        }
    }
}


