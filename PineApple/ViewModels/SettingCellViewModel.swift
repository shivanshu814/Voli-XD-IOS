//
//  SettingCellViewModel.swift
//  PineApple
//
//  Created by Tao Man Kit on 17/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class SettingCellViewModel: ViewModel {
    private var _model: Setting
    var model: Setting { return _model }
    var title = BehaviorRelay<String>(value: "")
    var isEnabled = BehaviorRelay<Bool>(value: false)
    
    // MARK: - Init
    init(model: Setting) {
        self._model = model
        setup(with: model)
    }
}

// MARK: - ViewModel
extension SettingCellViewModel {
    func setup(with model: Setting) {
        _model = model
        
        title.accept(model.title)
        isEnabled.accept(model.isEnabled)
    }
    
    private func updateModel() {
        _model.isEnabled = isEnabled.value
    }
}

// MARK: - Public
extension SettingCellViewModel {
    
    func save(isOn: Bool) {
        isEnabled.accept(isOn)
        updateModel()
    }
}
