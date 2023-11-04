//
//  TagViewModel.swift
//  PineApple
//
//  Created by Tao Man Kit on 7/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class TagViewModel: ViewModel {
    
    // MARK: - Properties
    var model: String!
    var itineraries = BehaviorRelay<[Itinerary]>(value: [])
    var imageSuggestion = BehaviorRelay<[TagImageCellViewModel]>(value: [])
    var sortOptions = BehaviorRelay<[ItineraryFilterOption.SortBy]>(value: sortByOption)
    var sortBy = BehaviorRelay<ItineraryFilterOption.SortBy>(value: .createDate)
    var relatedTagViewModel = ItinerariesViewModel()
    var paging = Paging()
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    init() {}
    
    init(tag: String) {
        self.model = tag
        
        self.itineraries
            .asObservable()
            .bind {[weak self] (itineraries) in
                guard let strongSelf = self else { return }
                var _imageSuggestion = strongSelf.imageSuggestion.value
                                
                itineraries.forEach{
                    for activity in $0.activities {
                        if (activity.tag.map{$0.lowercased()}).contains(strongSelf.model.lowercased()) {
                            for attachment in activity.attachments {
                                let vm = TagImageCellViewModel(itinerary: $0, attachment: attachment, imageHeight: TagImageCellViewModel.ImageHeight(rawValue: Int.random(in: 0..<3))!)
                                _imageSuggestion.append(vm)
                            }
                        }
                    }
                }                
                strongSelf.imageSuggestion.accept(_imageSuggestion)
            }.disposed(by: disposeBag)
    }
    
}

// MARK: - Public
extension TagViewModel {
    
    func fetchTagActivities(_ completionHandler: RequestDidCompleteBlock?) {
        let option = ItineraryFilterOption(location: "", state: "", country: "", tags: [model], sortBy: sortBy.value)
        
        Itinerary.find(by: option, paging: paging) { [weak self] (itineraries, error) in
            guard let strongSelf = self else { return }
            if let error = error {
                completionHandler?(false, error)
            } else {
                strongSelf.handlePagingData(itineraries, br: strongSelf.itineraries, paging: strongSelf.paging)                
                completionHandler?(true, nil)
            }
        }
    }
    
}

