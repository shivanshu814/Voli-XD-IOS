//
//  FieldViewModel.swift
//  GuestTracker2
//
//  Created by Tao Man Kit on 23/8/2018.
//  Copyright © 2018 ROKO. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol FieldViewModel {
    
    var title: String { get set }
    var errorMessage: String { get set }
    var max: Int { get set }
    var isRequired: Bool { get set }
    
    // Observables
    var value: BehaviorRelay<String> { get }
    var errorValue: BehaviorRelay<String?> { get }
    
    // Validation
    func validate() -> Bool
}

extension FieldViewModel {
    
    func validateSize(_ value: String, size: (min:Int, max:Int)) -> Bool {
        return (size.min...size.max).contains(value.count)
    }
    func validateString(_ value: String?, pattern: String) -> Bool {
        let test = NSPredicate(format:"SELF MATCHES %@", pattern)
        return test.evaluate(with: value)
    }
    
    func validateRequired(_ value: String) -> Bool {
        return !isRequired || !value.isEmpty
    }
    
    func validateMaxCount(_ value: String) -> Bool {
        
        return max == -1 || value.count <= max || (!isRequired && value.count == 0)
    }
    
}
