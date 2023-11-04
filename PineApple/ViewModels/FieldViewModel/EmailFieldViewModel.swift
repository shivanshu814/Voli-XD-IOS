//
//  EmailFieldViewModel.swift
//  GuestTracker2
//
//  Created by Tao Man Kit on 23/8/2018.
//  Copyright © 2018 ROKO. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class EmailFieldViewModel: TextFieldViewModel {
    
    override func validate() -> Bool {
        if isRequired || (!isRequired && !value.value.isEmpty) {
            let emailPattern = "[A-Z0-9a-z._%+-]+@([A-Za-z0-9.-]{2,64})+\\.[A-Za-z]{2,64}"
            guard validateString(value.value, pattern:emailPattern) else {
                errorValue.accept(errorMessage)
                return false
            }
        }
        errorValue.accept(nil)
        return true
    }
}
