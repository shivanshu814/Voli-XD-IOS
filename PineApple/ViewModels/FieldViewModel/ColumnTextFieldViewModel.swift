//
//  ColumnTextFieldViewModel.swift
//  PineApple
//
//  Created by Tao Man Kit on 23/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class ColumnTextFieldViewModel: TextFieldViewModel {
    // MARK: - Properties
    var viewModel: (TextFieldViewModel, TextFieldViewModel)?
    
    // MARK: - Init
    init(viewModel: (TextFieldViewModel, TextFieldViewModel)) {
        super.init(title: "", errorMessage: "")
        self.viewModel = viewModel
        self.isSingleLine = true
    }
    
    override func validate() -> Bool {
        let v1 = viewModel?.0.validate() ?? true
        let v2 = viewModel?.1.validate() ?? true
        return v1 && v2
    }
}
