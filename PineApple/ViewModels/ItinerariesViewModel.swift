//
//  ItinerariesViewModel.swift
//  PineApple
//
//  Created by Tao Man Kit on 4/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import Firebase
import CoreLocation
import GooglePlaces

class ItinerariesViewModel: ViewModel {
    
    // MARK: - Properties
    private var _model: ([Itinerary], ItineraryFilterOption) = ([], ItineraryFilterOption())
    var model: ([Itinerary], ItineraryFilterOption) { return _model }
    var rows = BehaviorRelay<[ViewModel]>(value: [ItinerariesFilterViewModel(option: ItineraryFilterOption())])
    var locationOptions = BehaviorRelay<[Location]>(value: locationOption)
    var sortOptions = BehaviorRelay<[ItineraryFilterOption.SortBy]>(value: sortByOption)
    var relatedTags = BehaviorRelay<[TagCellViewModel]>(value: [])
    var isMore = BehaviorRelay<Bool>(value: true)
    var paging = Paging()
    var pagings = [String: Paging]()
    var queryStatus = [String: Bool]()
    var itineraries = [Itinerary]()
    var isAnimated = true
    var isCurrentLocation = false
    var filterViewModel: ItinerariesFilterViewModel {
        return rows.value[0] as! ItinerariesFilterViewModel
    }
    var detailViewModels: [ItineraryDetailViewModel] {
        return (rows.value[1...]).map{$0 as! ItineraryDetailViewModel}
    }
    var locationViewModel: LocationViewModel!
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    init() {
        self._model = ([], ItineraryFilterOption())
        self.setup(with: model)
    }
    
    init(model: ([Itinerary], ItineraryFilterOption)) {
        self._model = model
        self.setup(with: model)
    }
        
}

// MARK: - ViewModel
extension ItinerariesViewModel {
    
    func setup(with model: ([Itinerary], ItineraryFilterOption)) {
        _model = model
        
        if locationViewModel == nil {
            locationViewModel = LocationViewModel()
            
            locationViewModel.predictions
                .asObservable()
                .bind {[weak self] (predictions) in
                    self?.locationOptions.accept(predictions)
            }
            .disposed(by: disposeBag)
            
            showPopularCities()
        }
        
        // Rows
        var _rows = [ViewModel]()
        filterViewModel.setup(with: model.1)

        _rows.append(filterViewModel)
        let itineraries = _model.0.map{ItineraryDetailViewModel(itinerary: ItineraryViewModel(itinerary: $0))}
        _rows.append(contentsOf: itineraries)
        rows.accept(_rows)
    }
}

// MARK - Public
extension ItinerariesViewModel {
    
    func getSelectedLocation(_ index: Int, completionHandler: @escaping (Location) -> Void) {
        let location = locationOptions.value[index]
        if let placeId = location.placecId, !locationViewModel.searchText.value.isEmpty {
            locationViewModel.convertToValidLocationFormat(placeId) { (info) in
                if let info = info {
                    let _location = Location(shortName: info.city, longName: info.fullName)
                    completionHandler(_location)
                } else {
                    completionHandler(location)
                }
            }
        } else {
            completionHandler(filterViewModel.resolveCurrentLocationIfNeeded(location))
        }
    }
    
    func showPopularCities() {
        locationOptions.accept(locationOption)
    }
    
    func refresh(_ itinerary: Itinerary) {

        if let index = _model.0.firstIndex(of: itinerary) {
            var newModel = _model.0
            if itinerary.isPrivate || itinerary.isDeleted {
                var newRow = rows.value
                if newRow.count > index+1 {
                    newRow.remove(at: index+1)
                    rows.accept(newRow)
                }
            } else {
                newModel[index] = itinerary
                if detailViewModels.count > index {
                    let model = detailViewModels[index].model
                    model.setup(with: itinerary)
                    detailViewModels[index].setup(with: model)
                }
            }
        }
    }
    
    func getRelatedTags() {
        Tag.findFeaturedTags {[weak self] (tags, error) in
            if error == nil {
                self?.relatedTags.accept(tags.map{TagCellViewModel(tag: $0)})
            }
        }        
    }
    
    func getItineraries(tag: String? = nil, _ completionHandler: @escaping RequestDidCompleteBlock) {
        
        func updateQueryStatus(_ tag: String) {
            synced(self) {
                queryStatus[tag] = false
            }
        }
        
        func updateItineraries(_ newItineraries: [Itinerary], option: ItineraryFilterOption, isRenew: Bool = false) {
            synced(self) {
                if isRenew {
                    itineraries = newItineraries
                } else {
                    for itinerary in newItineraries {
                        if !itineraries.contains(itinerary) {
                            itineraries.append(itinerary)
                        }
                    }
                    // sort if tag filter exist
                    switch option.sortBy {
                    case .createDate: itineraries = itineraries.sorted(by: { $0.createDate > $1.createDate })
                    case .popularity: itineraries = itineraries.sorted(by: { $0.likeCount > $1.likeCount })
                    case .duration: itineraries = itineraries.sorted(by: { $0.duration > $1.duration })
                    case .distance: itineraries = itineraries.sorted(by: { $0.distance < $1.distance })
                    }
                }
            }
        }
        
        func fetch(_ tag: String? = nil, completionHandler: @escaping RequestDidCompleteBlock) {
            var option = filterViewModel.model
            var _paging = paging
            if tag != nil {
                option.tags = [tag!]
                _paging = pagings[tag!]!
            }
            Itinerary.find(by: option, paging: _paging) { [weak self] (result, error) in
                guard let strongSelf = self else { return }
                
                let isTags = !strongSelf.filterViewModel.model.tags.isEmpty
                if isTags {
                    guard !option.tags.isEmpty else { return }
                    guard strongSelf.filterViewModel.model.tags.contains(option.tags.first!) else { return }
                } else {
                    guard option.tags.isEmpty else { return}
                }
                
                if let error = error {
                    if isTags {
                        updateQueryStatus(option.tags.first!)
                    }
                    completionHandler(false, error)
                } else {
                    if isTags {
                        var newItineraries = result
                        
                        // update like and comment
                        for i in 0..<newItineraries.count {
                            newItineraries[i].updateLikeCommentSave()
                        }
                        
                        updateItineraries(newItineraries, option: option)
                        strongSelf.setup(with: (strongSelf.itineraries, strongSelf.filterViewModel.model))
                        _paging.start += 1
                        
                        updateQueryStatus(option.tags.first!)
                        if (strongSelf.queryStatus.values.filter{$0}).isEmpty {
                            completionHandler(true, nil)
                        }
                        
                        // isMore
                        var _isMore = false
                        for paging in strongSelf.pagings.values {
                            if paging.isMore.value {
                                _isMore = true
                                break
                            }
                        }
                        strongSelf.isMore.accept(_isMore)
                        
                    } else {
                        var newItineraries: [Itinerary]
                        if strongSelf.paging.start > 0 {
                            newItineraries = strongSelf.detailViewModels.map{$0.model.model}
                            newItineraries.append(contentsOf: result)
                        } else {
                            newItineraries = result
                        }
                        // update like and comment
                        for i in 0..<newItineraries.count {
                            newItineraries[i].updateLikeCommentSave()
                        }
                        
                        strongSelf.setup(with: (newItineraries, strongSelf.filterViewModel.model))
                        _paging.start += 1
                        strongSelf.isMore.accept(_paging.isMore.value)
                        completionHandler(true, nil)
                    }
                                        
                }
            }
        }
                
        let tags = filterViewModel.model.tags
        if tags.isEmpty {
            pagings.removeAll()
            fetch(completionHandler: completionHandler)
        } else {
            paging.start = 0
            pagings = pagings.filter{filterViewModel.model.tags.contains($0.key)}
            // check if it is fresh start
            if (pagings.values.filter{$0.start>0}).isEmpty {
                itineraries = []
            } else {
                var newItineraries = [Itinerary]()
                for itinerary in itineraries {
                    for tag in filterViewModel.model.tags {
                        if (itinerary.tags.map{$0.lowercased()}).contains(tag.lowercased()) {
                            newItineraries.append(itinerary)
                            break
                        }
                    }
                }
                updateItineraries(newItineraries, option: filterViewModel.model, isRenew: true)
            }
            queryStatus.removeAll()
            let tags = tag == nil ? filterViewModel.model.tags : [tag!]
            for tag in tags {
                queryStatus[tag] = false
                if !pagings.has(key: tag) {
                    pagings[tag] = Paging()
                }
                fetch(tag, completionHandler: completionHandler)
            }
        }
    }
    
}
