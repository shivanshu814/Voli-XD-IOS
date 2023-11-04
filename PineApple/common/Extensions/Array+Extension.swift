//
//  Array+Extension.swift
//  ForceRank
//
//  Created by Steven Tao on 24/11/15.
//  Copyright © 2015 roko. All rights reserved.
//

import Foundation

extension Array where Element : Hashable {
    var unique: [Element] {
        return Array(Set(self))
    }
}

extension Array where Element: Equatable {
    mutating func removeObject(_ object: Element) {
        if let index = self.index(of: object) {
            self.remove(at: index)
        }
    }
    
    mutating func removeObjectsInArray(_ array: [Element]) {
        for object in array {
            self.removeObject(object)
        }
    }
}
