//
//  UITextView+Extension.swift
//  PineApple
//
//  Created by Tao Man Kit on 22/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import UIKit

extension UITextView {
    
    func addInputAccessoryView(with target: Any, doneAction: Selector?) {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        doneToolbar.backgroundColor = UIColor.white
        doneToolbar.barStyle = .default
        doneToolbar.tintColor = Styles.g504F4F
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: target, action: doneAction)
        done.setTitleTextAttributes(Styles.toolBarItemAttributes as [NSAttributedString.Key : Any], for: .normal)
        
//        let previousButton = UIBarButtonItem(title: "Previous", style: .plain, target: target, action: previousAction)
//        previousButton.width = 30
//
//        let nextButton = UIBarButtonItem(title: "Next", style: .plain, target: target, action: nextAction)
//        nextButton.width = 30
        var items = [UIBarButtonItem]()
//        items.append(contentsOf: [previousButton, nextButton])
        
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        
        self.inputAccessoryView = doneToolbar
    }
}
