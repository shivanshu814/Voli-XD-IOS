//
//  Tag.swift
//  PineApple
//
//  Created by Tao Man Kit on 21/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation

struct Tag {
    var name: String
    var taggedCount: Int
    var keywords: [String] {
        var _keywords = name.lowercased().components(separatedBy: " ")
        _keywords.append(name.lowercased())
        return _keywords
    }
    
    // MARK: - Init
    init(name: String, taggedCount: Int = 0) {
        self.name = name
        self.taggedCount = taggedCount
    }
    
    init(data: [String : Any]) {
        self.name = data["name"] as? String ?? ""
        self.taggedCount = data["taggedCount"] as? Int ?? 0

    }
}


