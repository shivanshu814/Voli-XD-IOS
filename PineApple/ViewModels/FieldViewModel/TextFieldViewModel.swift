//
//  FieldViewModel.swift
//  PineApple
//
//  Created by Tao Man Kit on 13/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class TextFieldViewModel: FieldViewModel, ViewModel {
    
    let value = BehaviorRelay<String>(value: "")
    let errorValue = BehaviorRelay<String?>(value: nil)
    var isRequired = true
    var isSingleLine = false
    var max = -1    
    
    var title: String
    var description: String
    var errorMessage: String
    
    init(title: String, description: String = "", errorMessage: String, isSingleLine: Bool = false, isRequired: Bool = true) {
        self.title = title
        self.description = description
        self.errorMessage = errorMessage
        self.isSingleLine = isSingleLine
        self.isRequired = isRequired
    }
    
    func validate() -> Bool {
        
        errorValue.accept(nil)
        return true
    }
}

extension TextFieldViewModel: Equatable {
    
    static func == (lhs: TextFieldViewModel, rhs: TextFieldViewModel) -> Bool {
        return lhs.title == rhs.title
    }
    
}
