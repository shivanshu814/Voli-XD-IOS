//
//  Setting.swift
//  PineApple
//
//  Created by Tao Man Kit on 17/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation

struct Setting  {
    var title: String
    var isEnabled: Bool
}

extension Setting: Equatable {
    static func == (lhs: Setting, rhs: Setting) -> Bool {
        return lhs.title == rhs.title
    }
}
