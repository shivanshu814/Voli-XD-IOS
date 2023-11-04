//
//  SettingViewModel.swift
//  PineApple
//
//  Created by Tao Man Kit on 17/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class SettingViewModel: ViewModel {
    private var _model: User
    var model: User { return _model }
    var privacySetting = BehaviorRelay<[SettingCellViewModel]>(value: [])
    var notificationSetting = BehaviorRelay<[SettingCellViewModel]>(value: [])
    var privacySettingKeys = ["Itinerary visibility", "Private messaging"]
    var notificationSettingKeys = ["Comment, Save, Like", "Private message", "New follower", "Itinerary shared with you"]
    
    // MARK: - Init
    init(model: User) {
        _model = model
        setup(with: model)
    }
}

// MARK: - ViewModel
extension SettingViewModel {
    func setup(with model: User) {
        var privacySettingValue = [SettingCellViewModel]()
        var notificationSettingValue = [SettingCellViewModel]()
        
        for key in privacySettingKeys {
            privacySettingValue.append(SettingCellViewModel(model: (model.setting.filter{$0.title == key}).first ?? Setting(title: key, isEnabled: true))  )
        }
        
        for key in notificationSettingKeys {
            notificationSettingValue.append(SettingCellViewModel(model: (model.setting.filter{$0.title == key}).first ?? Setting(title: key, isEnabled: true))  )
        }
        
        privacySetting.accept(privacySettingValue)
        notificationSetting.accept(notificationSettingValue)
    }
}

// MARK: - Public
extension SettingViewModel {
    func save(_ completionHandler: @escaping RequestDidCompleteBlock) {
        if var currentUser = Globals.currentUser {
            
            for vm in privacySetting.value {
                if let index = currentUser.setting.firstIndex(of: vm.model) {
                    currentUser.setting[index] = vm.model
                }
            }
            for vm in notificationSetting.value {
                if let index = currentUser.setting.firstIndex(of: vm.model) {
                    currentUser.setting[index] = vm.model
                }
            }
                                
            User.updateSetting(currentUser) {(result, error) in
                if result {
                    Globals.currentUser?.setting = currentUser.setting
                }
                completionHandler(result, error)
            }
        }
    }
}
