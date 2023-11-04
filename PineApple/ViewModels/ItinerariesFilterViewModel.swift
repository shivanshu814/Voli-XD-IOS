//
//  ItinerariesFilterViewModel.swift
//  PineApple
//
//  Created by Tao Man Kit on 4/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import Firebase

class ItinerariesFilterViewModel: ViewModel {
    
    // MARK: - Properties    
    private var _model: ItineraryFilterOption
    var model: ItineraryFilterOption { return _model }
    var location = BehaviorRelay<Location>(value: locationOption[0])
    var sortBy = BehaviorRelay<ItineraryFilterOption.SortBy>(value: .createDate)
    var tags = BehaviorRelay<[TagCellViewModel]>(value: [])
    var contentOffsetX: CGFloat = 0
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    init(option: ItineraryFilterOption) {
        self._model = option
        self.setup(with: option)
        
        location
            .asObservable()
            .bind {[weak self] (_) in
                self?.updateModel()
        }.disposed(by: disposeBag)
        
        sortBy
            .asObservable()
            .bind {[weak self] (_) in
                self?.updateModel()
        }.disposed(by: disposeBag)
    }
    
}

// MARK: - ViewModel
extension ItinerariesFilterViewModel {
    
    func setup(with model: ItineraryFilterOption) {
        _model = model
        
        let _location = resolveCurrentLocationIfNeeded(location.value)
        location.accept(_location)
        sortBy.accept(model.sortBy)
    }
    
    func updateModel() {
        _model.location = location.value.shortName
        if _model.location == WORLDWIDE {
           _model.location = ""
        } else {
            let components = location.value.longName.components(separatedBy: ", ")
            if components.count == 1 {
                _model.country = components[0]
                _model.state = ""
            } else if components.count > 2 {
                _model.state = components[1]
                _model.country = components[2]
            } else {
                _model.country = components[1]
                _model.state = ""
            }
        }
        _model.sortBy = sortBy.value
        _model.tags = (tags.value.filter{$0.isSelected.value}).map{$0.tag.name}
    }
    
    func resolveCurrentLocationIfNeeded(_ location: Location) -> Location {
        if location.shortName == CURRENT_LOCATION {
            if let info = LocationController.shared.locationInfo {
                return Location(shortName: info.city, longName: info.fullName)
            } else {
                return locationOption[0]
            }
            
        }
        return location
    }
}

// MARK: - Private
extension ItinerariesFilterViewModel {
    func getSuggestTags() {
        Tag.findPropularTags(by: model) {[weak self] (tags, error) in
            if error == nil {                
                self?.tags.accept(tags.map{TagCellViewModel(tag: $0, isSelectionEnabled: true)})
            }
        }               
    }
}
