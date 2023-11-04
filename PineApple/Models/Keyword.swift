//
//  Keyword.swift
//  PineApple
//
//  Created by Tao Man Kit on 22/10/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation

struct Keyword {
    var name: String
    
    // MARK: - Init
    init(name: String) {
        self.name = name
    }
    
    init(data: [String : Any]) {
        self.name = data["name"] as? String ?? ""    

    }
}
