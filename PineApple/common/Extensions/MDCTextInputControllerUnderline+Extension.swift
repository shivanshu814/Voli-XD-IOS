//
//  MDCTextInputControllerUnderline+Extension.swift
//  PineApple
//
//  Created by Tao Man Kit on 22/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import MaterialComponents.MaterialTextFields

extension MDCTextInputControllerOutlinedTextArea {
    func setupStyles(with textField: MDCMultilineTextField, observer: NSObject) {
        textInputFont = Styles.customFontLight(15)
        inlinePlaceholderFont = Styles.customFontLight(15)
        inlinePlaceholderColor = Styles.g797979
        normalColor = Styles.gD8D8D8
        activeColor = Styles.gD8D8D8
        isFloatingEnabled = false
        textField.textView?.addObserver(observer, forKeyPath: "contentSize", options: (NSKeyValueObservingOptions.new), context: nil)
        underlineHeightActive = MDCTextInputControllerFilled.underlineHeightNormalDefault
        
    }
}

extension MDCTextInputControllerOutlined {
    
    
    func setupStyles(with textField: MDCTextField, observer: NSObject) {
        textInputFont = Styles.customFontLight(15)
        inlinePlaceholderFont = Styles.customFontLight(15)
        inlinePlaceholderColor = Styles.g797979
        normalColor = Styles.gD8D8D8
        activeColor = Styles.gD8D8D8
        isFloatingEnabled = false
//        underlineHeightActive = MDCTextInputControllerFilled.underlineHeightNormalDefault
    }
    
}

extension MDCTextInputControllerUnderline {
    func setupStyles(with textField: MDCMultilineTextField, observer: NSObject) {
        textInputFont = UIFont.systemFont(ofSize: 14)
        inlinePlaceholderFont = UIFont.systemFont(ofSize: 14)
        inlinePlaceholderColor = Styles.gray
        normalColor = Styles.lightGray
        activeColor = Styles.lightGray
        floatingPlaceholderActiveColor = Styles.p8437FF
        floatingPlaceholderNormalColor = Styles.p8437FF
        textField.textView?.addObserver(observer, forKeyPath: "contentSize", options: (NSKeyValueObservingOptions.new), context: nil)
        underlineHeightActive = MDCTextInputControllerFilled.underlineHeightNormalDefault
        
    }
    
    func setupStyles(with textField: MDCTextField, observer: NSObject) {
        textInputFont = UIFont.systemFont(ofSize: 14)
        inlinePlaceholderFont = UIFont.systemFont(ofSize: 14)
        inlinePlaceholderColor = Styles.gray
        normalColor = Styles.lightGray
        activeColor = Styles.lightGray
        floatingPlaceholderActiveColor = Styles.p8437FF
        floatingPlaceholderNormalColor = Styles.p8437FF
        underlineHeightActive = MDCTextInputControllerFilled.underlineHeightNormalDefault        
    }
    
}

