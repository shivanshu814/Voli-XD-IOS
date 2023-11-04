//
//  PasswordFieldViewModel.swift
//  GuestTracker2
//
//  Created by Tao Man Kit on 23/8/2018.
//  Copyright © 2018 ROKO. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class PasswordFieldViewModel: TextFieldViewModel, SecureFieldViewModel {
    
    var isSecureTextEntry: Bool = true
    
    override func validate() -> Bool {
        // between 8 and 25 caracters
        guard validateSize(value.value, size: (1,100)) else {
            errorValue.accept(errorMessage)
            return false
        }
        errorValue.accept(nil)
        return true
    }
}

// Options for FieldViewModel
protocol SecureFieldViewModel {
    var isSecureTextEntry: Bool { get }
}
