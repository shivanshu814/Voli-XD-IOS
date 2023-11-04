//
//  UIView+Extension.swift
//  PineApple
//
//  Created by Tao Man Kit on 19/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func blur() {
        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(blurEffectView, at: 0)        
    }
}
