//
//  ViewModel.swift
//  ST
//
//  Created by Tao Man Kit on 11/7/2019.
//  Copyright © 2019 tao. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

protocol ViewModel {
    
}

extension ViewModel {
    
    func handlePagingData<T>(_ data: [T], br: BehaviorRelay<[T]>, paging: Paging) {
        if paging.start > 0 {
            var newValue = br.value
            newValue.append(contentsOf: data)
            br.accept(newValue)
        } else {
            br.accept(data)
        }
        paging.start += 1
    }
}
