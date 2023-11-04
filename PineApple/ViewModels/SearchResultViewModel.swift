//
//  SearchResultViewModel.swift
//  PineApple
//
//  Created by Tao Man Kit on 20/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class SearchResultViewModel: ViewModel {
    // MARK: - Properties
    enum SearchType: Int {
        case all
        case user
        case itinerary
        case tag
    }
    private var _type = SearchType.all
    private var _model: SearchViewModel!
    var type: SearchType {return _type}
    var model: SearchViewModel {return _model}
    
    var rows: [ViewModel] {
        switch type {
        case .all: return model.all.value
        case .user: return model.users.value
        case .itinerary: return model.itineraries.value
        case .tag: return model.tags.value
        }
    }
    
    // MARK: - Init
    init(model: SearchViewModel, type: SearchType) {
        self._model = model
        self._type = type
    }
}
