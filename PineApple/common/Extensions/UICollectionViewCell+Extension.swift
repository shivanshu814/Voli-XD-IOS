//
//  UICollectionViewCell+Extension.swift
//  PineApple
//
//  Created by Tao Man Kit on 26/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import UIKit

extension UICollectionViewCell {
    func addShadow(with radius: CGFloat = 0) {
        if radius > 0 {
            contentView.layer.cornerRadius = radius
        }
        contentView.layer.borderWidth = 1.0
        contentView.layer.borderColor = UIColor.clear.cgColor
        contentView.layer.masksToBounds = true
//        contentView.backgroundColor = UIColor.white
        
        layer.shadowColor = UIColor.gray.cgColor
        layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        if radius > 0 {
            layer.shadowRadius = radius
        }
        layer.shadowOpacity = 0.8
        layer.masksToBounds = false
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: contentView.layer.cornerRadius).cgPath
        layer.backgroundColor = UIColor.clear.cgColor
    }
}
