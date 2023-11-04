//
//  UITableView+Extension.swift
//  PineApple
//
//  Created by Tao Man Kit on 19/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import UIKit

extension UITableView {
    func update() {
        UIView.setAnimationsEnabled(false)
        beginUpdates()
        endUpdates()
        UIView.setAnimationsEnabled(true)
    }
}
