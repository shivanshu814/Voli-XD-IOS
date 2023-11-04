//
//  File.swift
//  PineApple
//
//  Created by Tao Man Kit on 29/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation

extension TimeInterval {
    var toString: String {
        let hr = self.int / (60*60)
        let min = (self.int % (60*60)) / 60
        if hr == 0 {
//            return "\(min) \(min > 1 ? "mins" : "min")"
            let time = "\(min) \(min > 1 ? "mins" : "min")"
            return time == "0 min" ? "" : time
        }
        if min == 0 {
            return "\(hr) \(hr > 1 ? "hours" : "hour")"
        }
        return "\(hr) \(hr > 1 ? "hours" : "hour") \(min) \(min > 1 ? "mins" : "min")"
    }
    
//    var toShortString: String {
//        let hr = self.int / (60*60)
//        let min = (self.int % (60*60)) / 60
//        if hr == 0 {
//            let time = "\(min) \(min > 1 ? "mins" : "min")"
//            return time == "0 min" ? "" : time
//        }
//        if min == 0 {
//            return "\(hr) \(hr > 1 ? "hrs" : "hr")"
//        }
//        return "\(hr) \(hr > 1 ? "hrs" : "hr") \(min) \(min > 1 ? "mins" : "min")"
//    }
    
    var toShortString: String {
        let hr = self.int / (60*60)
        let min = (self.int % (60*60)) / 60
        if hr == 0 {
            let time = "\(min) Min"
            return time == "0 Min" ? "" : time
        }
        if min == 0 {
            return "\(hr) Hr"
        }
        return "\(hr) Hr \(min) Min"
    }
}
