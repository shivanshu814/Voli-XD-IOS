//
//  ViewModelBased.swift
//  ST
//
//  Created by Tao Man Kit on 11/7/2019.
//  Copyright © 2019 tao. All rights reserved.
//

import Foundation

protocol ViewModelBased {
    associatedtype ViewModelType: ViewModel
    
    var viewModel: ViewModelType! { get set }
    
    func bindViewModel(_ viewModel: ViewModelType)
    
    func bindAction()
}

extension ViewModelBased {
    func bindAction() {}
}

