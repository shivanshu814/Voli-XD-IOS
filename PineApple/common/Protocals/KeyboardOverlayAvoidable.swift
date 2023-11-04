//
//  KeyboardOverlayAvoidable.swift
//  PineApple
//
//  Created by Tao Man Kit on 22/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import UIKit

protocol KeyboardOverlayAvoidable where Self: UIViewController {
    var keyboardHeight: CGFloat { get set }
    var keyboardDidShowBlock: (() -> Void)? { get set }
}

extension KeyboardOverlayAvoidable {
    func addKeyboardNotification() {
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil) {[weak self] (notification) in
            self?.keyboardDidShow(notification: notification)
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil) {[weak self] (notification) in
            guard let strongSelf = self else { return }
            UIView.animate(withDuration: 0.2) {
                strongSelf.view.frame = CGRect(x: 0, y: 0, width: strongSelf.view.frame.width, height: UIScreen.main.bounds.height)
                strongSelf.view.layoutIfNeeded()
            }
        }
        
    }
    
    func removeKeyboardNotification() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func keyboardDidShow(notification: Notification) {
        print(self)
        keyboardDidShowBlock?()
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            keyboardHeight = keyboardRectangle.height
        }
        
        if view.frame.origin.y == 0 {
            let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey]
            
            UIView.animate(withDuration: animationDuration as! TimeInterval) { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.view.frame = CGRect(x: 0, y: 0, width: strongSelf.view.frame.width, height: ((strongSelf.view.window?.frame.height) ?? UIScreen.main.bounds.height) - strongSelf.keyboardHeight)
//                strongSelf.view.layoutIfNeeded()
            }
        }
    }
    
}
