//
//  Date+Extension.swift
//  PineApple
//
//  Created by Tao Man Kit on 2/11/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation

extension Date {
    var toDateString: String {
        return year == Date().year ? Styles.dateFormatter_ddMMM.string(from: self) : Styles.dateFormatter_ddMMMyyyy.string(from: self)
    }
    
    var hhmma: Date {
        let dateStr = Styles.dateFormatter_HHmma.string(from: self)
        let date = Styles.dateFormatter_HHmma.date(from: dateStr)!
        return date
    }
    
    var toDateTimeString: String {
        if isInToday {
            return Styles.dateFormatter_HHmma.string(from: self)
        } else if isInCurrentYear {
            return  Styles.dateFormatter_HHmmaddMM.string(from: self)
        } else {
            return  Styles.dateFormatter_HHmmaddMMyyyy.string(from: self)
        }
    }
}
