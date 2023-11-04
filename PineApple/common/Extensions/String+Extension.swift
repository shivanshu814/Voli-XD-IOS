//
//  String+Extension.swift
//  NBCUQueryEngine
//
//  Created by Tao Man Kit on 14/5/2018.
//  Copyright © 2018 ROKO. All rights reserved.
//

import Foundation
import UIKit

extension String: Error {}

extension String: LocalizedError {
    public var errorDescription: String? { return self }
    
    func heightWithConstrainedWidth(width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedString.Key.font: font], context: nil)
        return ceil(boundingBox.height) 
    }
    
    func attributedStringWithLineSpace(_ space: CGFloat) -> NSMutableAttributedString {
        let attributedString = NSMutableAttributedString(string: self)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = space
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))
        return attributedString
    }
    
    
//    func widthWithConstrainedHeight(_ height: CGFloat, font: UIFont) -> CGFloat {
//        let constraintRect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: height)
//
//        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
//
//        return ceil(boundingBox.width)
//    }
//
//    func heightWithConstrainedWidth(_ width: CGFloat, font: UIFont) -> CGFloat? {
//        let constraintRect = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
//        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
//
//        return ceil(boundingBox.height)
//    }
}
