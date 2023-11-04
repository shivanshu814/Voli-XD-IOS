//
//  UILabel+Extension.swift
//  PineApple
//
//  Created by Tao Man Kit on 3/11/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import UIKit

extension UILabel {
    func heightForView() -> CGFloat {
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text

        label.sizeToFit()
        return label.frame.height
    }
}
