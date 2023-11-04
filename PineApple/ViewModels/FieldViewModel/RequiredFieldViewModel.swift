//
//  RequiredFieldViewModel.swift
//  GuestTracker2
//
//  Created by Tao Man Kit on 25/10/2018.
//  Copyright © 2018 ROKO. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

class RequiredFieldViewModel: TextFieldViewModel {
        
    override func validate() -> Bool {
        guard validateRequired(value.value) else {
            errorValue.accept(errorMessage)
            return false
        }
        
        guard validateMaxCount(value.value) else {
            errorValue.accept("Maximum word count for description is \(max).")
            return false
        }
        
        errorValue.accept(nil)
        return true
    }
}

