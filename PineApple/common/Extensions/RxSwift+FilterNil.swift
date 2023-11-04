//
//  RxSwift+FilterNil.swift
//  ST
//
//  Created by Tao Man Kit on 11/7/2019.
//  Copyright © 2019 tao. All rights reserved.
//

import Foundation
import RxSwift

protocol OptionalType {
    associatedtype Wrapped
    var value: Wrapped? { get }
}

extension Optional: OptionalType {
    var value: Wrapped? {
        return self
    }
}

extension Observable where Element: OptionalType {
    
    func filterNil() -> Observable<Element.Wrapped> {
        return flatMap { (element) -> Observable<Element.Wrapped> in
            if let value = element.value {
                return .just(value)
            } else {
                return .empty()
            }
        }
    }
}
