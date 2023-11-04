//
//  SSOFieldViewModel.swift
//  GuestTracker2
//
//  Created by Tao Man Kit on 23/8/2018.
//  Copyright © 2018 ROKO. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class NumberFieldViewModel: TextFieldViewModel {
    
    override func validate() -> Bool {
        if isRequired || (!isRequired && !value.value.isEmpty) {
            let numberPattern = "^[0-9]+$"
            guard validateString(value.value, pattern:numberPattern) else {
                errorValue.accept(errorMessage)
                return false
            }
        }
        errorValue.accept(nil)
        return true
    }
}
