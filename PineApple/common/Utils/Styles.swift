//
//  Styles.swift
//  ST
//
//  Created by Tao Man Kit on 11/7/2019.
//  Copyright © 2019 tao. All rights reserved.
//

import Foundation
import UIKit
import SwiftMessageBar

struct Styles {
    static let dateFormatter_ddMMyyyyHHmmsssss = DateFormatter()
    static let dateFormatter_HHmma = DateFormatter()
    static let dateFormatter_HHmmaddMM = DateFormatter()
    static let dateFormatter_HHmmaddMMYYYY = DateFormatter()
    static let dateFormatter_HHmmaddMMyyyy = DateFormatter()
    static let dateFormatter_ddMMMyyyy = DateFormatter()
    static let dateFormatter_ddMMM = DateFormatter()
    static let lastPriceNumberFormattor = NumberFormatter()
    static let changeNumberFormattor = NumberFormatter()
    static let numberFormatter = NumberFormatter()
    static let decreasingColor = "ff4444"
    static let increasingColor = "00C851"
    static let neutralColor = "70c9df"
    static let p6A0DFF = UIColor(hex: 0x6A0DFF)!
    static let p8437FF = UIColor(hex: 0x8437FF)!
    static let pCFC2FF = UIColor(hex: 0xCFC2FF)!
    static let pF6F2FE = UIColor(hex: 0xF6F2FE)!
    
    static let g2E2D2D = UIColor(hex: 0x2E2D2D)!
    static let g504F4F = UIColor(hex: 0x504F4F)!
    static let g797979 = UIColor(hex: 0x797979)!
    static let g888888 = UIColor(hex: 0x888888)!
    static let gAEAEAE = UIColor(hex: 0xAEAEAE)!
    static let gD8D8D8 = UIColor(hex: 0xD8D8D8)!
    
    static let lightGray = UIColor(hex: 0x2E2D2D)!
    static let gray = UIColor(hex: 0x504F4F)!
    
    static let black = UIColor(hex: 0x2C3847)!
        
    static var multipleLineTextAttributes = [
        NSAttributedString.Key.foregroundColor: Styles.g504F4F,
        NSAttributedString.Key.font: Styles.customFontLight(15)
    ]
    
    static let navigationBarTitleAttributes = [
        NSAttributedString.Key.foregroundColor: Styles.p6A0DFF,
        NSAttributedString.Key.font: Styles.customFontSemibold(16)
    ]
    
    static let navigationBarItemAttributes = [
        NSAttributedString.Key.foregroundColor: Styles.p6A0DFF,
        NSAttributedString.Key.font: Styles.customFontSemibold(16)
    ]
    
    static let toolBarItemAttributes = [
        NSAttributedString.Key.foregroundColor: Styles.g504F4F,
        NSAttributedString.Key.font: Styles.customFontSemibold(16)
    ]
    
    static func setup() {
        
//        Sofia Pro ["SofiaProBold", "SofiaProUltraLight-Italic", "SofiaProBold-Italic", "SofiaProMedium", "SofiaProSemiBold-Italic", "SofiaProLight", "SofiaProExtraLight-Italic", "SofiaProSemiBold", "SofiaProBlack-Italic", "SofiaProRegular-Italic", "SofiaProUltraLight", "SofiaProBlack", "SofiaProRegular", "SofiaProMedium-Italic", "SofiaProExtraLight", "SofiaProLight-Italic"]
//        UIFont.familyNames.forEach({ familyName in
//            let fontNames = UIFont.fontNames(forFamilyName: familyName)
//            print(familyName, fontNames)
//        })
        
        let ps = NSMutableParagraphStyle()
        ps.lineSpacing = 4
        multipleLineTextAttributes[.paragraphStyle] = ps
        
        let config = SwiftMessageBar.Config.Builder()
            .withErrorColor(UIColor(hex: 0x9FFAEF))
            .withInfoColor(UIColor(hex: 0x9FFAEF))
//            .withSuccessIcon(#imageLiteral(resourceName: "bell-icon"))
            .withTitleFont(Styles.customFontBold(17))
            .withMessageFont(Styles.customFontBold(17))
            .withTitleColor(Styles.g504F4F)
            .withMessageColor(Styles.g504F4F)
            .build()
                
        SwiftMessageBar.setSharedConfig(config)
        
        
        Styles.setupNavigationBar()
        numberFormatter.numberStyle = .decimal        
        
        dateFormatter_HHmmaddMMyyyy.dateFormat = "hh:mma   •   dd-MM/yyyy"
        dateFormatter_HHmma.dateFormat = "hh:mma"
        dateFormatter_ddMMyyyyHHmmsssss.dateFormat = "ddMMyyyyHHmmsssss"
        dateFormatter_HHmmaddMM.dateFormat = "hh:mma dd/MM"
        dateFormatter_HHmmaddMMYYYY.dateFormat = "hh:mma dd/MM/yyyy"
        dateFormatter_ddMMMyyyy.dateFormat = "dd MMM yyyy"
        dateFormatter_ddMMM.dateFormat = "dd MMM"
        
        lastPriceNumberFormattor.minimumFractionDigits = 1
        lastPriceNumberFormattor.minimumIntegerDigits = 1
        lastPriceNumberFormattor.maximumFractionDigits = 2
        
        changeNumberFormattor.minimumFractionDigits = 1
        changeNumberFormattor.minimumIntegerDigits = 1
        changeNumberFormattor.maximumFractionDigits = 3
    }
    
    static func setupNavigationBar() {
//        UINavigationBar.appearance().setTitleVerticalPositionAdjustment(6, for: .default)
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().shadowOpacity = 0
        UINavigationBar.appearance().titleTextAttributes = Styles.navigationBarTitleAttributes as [NSAttributedString.Key : Any]
        UINavigationBar.appearance().tintColor = Styles.p8437FF
        UINavigationBar.appearance().barTintColor = UIColor.white
        
        UIBarButtonItem.appearance().setTitleTextAttributes(Styles.navigationBarItemAttributes as [NSAttributedString.Key : Any], for: .normal)
        UIBarButtonItem.appearance().setTitleTextAttributes(Styles.navigationBarItemAttributes as [NSAttributedString.Key : Any], for: .highlighted)
        UIBarButtonItem.appearance().setTitleTextAttributes(Styles.navigationBarItemAttributes as [NSAttributedString.Key : Any], for: .selected)
    }
    
    static func customFont(_ fontSize: CGFloat) -> UIFont{
        return UIFont(name: "SofiaProRegular", size: fontSize)!
    }
    
    static func customFontBold(_ fontSize: CGFloat) -> UIFont{
        return UIFont(name: "SofiaProBold", size: fontSize)!
    }
    
    static func customFontLight(_ fontSize: CGFloat) -> UIFont{
        return UIFont(name: "SofiaProLight", size: fontSize)!
    }
    
    static func customFontSemibold(_ fontSize: CGFloat) -> UIFont{
        return UIFont(name: "SofiaProSemiBold", size: fontSize)!
    }
    
    static func customFontMedium(_ fontSize: CGFloat) -> UIFont{
        return UIFont(name: "SofiaProMedium", size: fontSize)!
    }
    
    
    
}
