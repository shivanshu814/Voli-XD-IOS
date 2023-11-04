//
//  SearchViewModel.swift
//  PineApple
//
//  Created by Tao Man Kit on 19/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

struct SearchResult {
    var sortValue: String
    var model: ViewModel
}

class SearchViewModel: ViewModel {
    
    // MARK: - Properties
    var popularUsers = BehaviorRelay<[UserCellViewModel]>(value: [])
    var popularItineraries = BehaviorRelay<[ItineraryDetailViewModel]>(value: [])
    var users = BehaviorRelay<[UserCellViewModel]>(value: [])
    var itineraries = BehaviorRelay<[ItineraryDetailViewModel]>(value: [])
    var tags = BehaviorRelay<[TagCellViewModel]>(value: [])
    var all = BehaviorRelay<[ViewModel]>(value: [])
    var suggestKeywords = BehaviorRelay<[String]>(value: [])
    var relatedTags = BehaviorRelay<[TagCellViewModel]>(value: [])
    
    var keyword = BehaviorRelay<String>(value: "")
    var selectedKeyword = ""
    var userPaging = Paging()
    var itineraryPaging = Paging()
    var tagPaging = Paging()
    var fetchingKeywords = false
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    init() {
        Observable.combineLatest(users, itineraries, tags) { (a1, a2, a3) -> [ViewModel] in
            var sortValue = [SearchResult]()
            a1.forEach {
                sortValue.append(SearchResult(sortValue: $0.name.value, model: $0))
            }
            a2.forEach {
                sortValue.append(SearchResult(sortValue: $0.model.model.title, model: $0))
            }
            a3.forEach {
                sortValue.append(SearchResult(sortValue: $0.tag.name, model: $0))
            }
            
            var vms = [ViewModel]()
            vms = (sortValue.sorted(by: { $0.sortValue > $1.sortValue })).map {$0.model}
            return vms
        }
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: {[weak self] (all) in
            guard let strongSelf = self else { return }
            strongSelf.all.accept(all)
        }).disposed(by: disposeBag)
    }
}

// MARK: - Public
extension SearchViewModel {
    
    func getRelatedTags() {
        Tag.findFeaturedTags {[weak self] (tags, error) in
            if error == nil {
                self?.relatedTags.accept(tags.map{TagCellViewModel(tag: $0)})
            }
        }
    }
    
    func searchPopularUsers() {
        User.findPopularUsers(Paging(start: 0, itemPerPage: 3)) {[weak self] (users, error) in
            if error == nil {
                self?.popularUsers.accept(users.map{UserCellViewModel(user: $0)})
            }
        }
    }
    
    func searchPopularItineraries() {
        Itinerary.findPopularItineraries(Paging(start: 0, itemPerPage: 4)) {[weak self]  (itineraries, error) in
            if error == nil {
                self?.popularItineraries.accept(itineraries.map{ItineraryDetailViewModel(itinerary: $0)})
            }
        }
    }
    
    func fetchKeywords() {
        let _keyword = keyword.value.lowercased()
        print("_keyword: " + _keyword)
        fetchingKeywords = true
        
        suggestKeywords.accept(suggestKeywords.value.filter{$0.starts(with: _keyword)})
        
        Keyword.findKeywords(_keyword) {[weak self] (keywords, error) in
            guard let strongSelf = self else { return }
            if self?.keyword.value.lowercased() == _keyword {
                self?.fetchingKeywords = false
                self?.suggestKeywords.accept((keywords.filter{$0.name.starts(with: strongSelf.keyword.value.lowercased())}).map{$0.name})
            }
        }
    }
    
    func search(_ keyword: String) {
        var _keyword = keyword
        if !suggestKeywords.value.contains(keyword) && !suggestKeywords.value.isEmpty {
            _keyword = suggestKeywords.value.first!
        }
        selectedKeyword = _keyword
        
        userPaging.start = 0
        itineraryPaging.start = 0
        tagPaging.start = 0
        reset()
        searchUsers()
        searchItineraries()
        searchTags()
        getRelatedTags()
    }
    
    func reset() {
        users.accept([])
        itineraries.accept([])
        tags.accept([])
    }
    
    func searchUsers() {
        User.findByKeyword(Keyword(name: selectedKeyword), paging: userPaging) {[weak self] (users, error) in
            guard let strongSelf = self else { return }
            if error == nil {
                let data = users.map{UserCellViewModel(user: $0)}
                strongSelf.handlePagingData(data, br: strongSelf.users, paging: strongSelf.userPaging)
            }
        }
    }
    
    func searchItineraries() {
       Itinerary.findByKeyword(Keyword(name: selectedKeyword), paging: itineraryPaging) { [weak self ](itineraries, error) in
            guard let strongSelf = self else { return }
            if error == nil {
                let data = itineraries.map{ItineraryDetailViewModel(itinerary: $0)}
                strongSelf.handlePagingData(data, br: strongSelf.itineraries, paging: strongSelf.itineraryPaging)
            }
        }
    }
    
    func searchTags() {
        Tag.findByKeyword(Keyword(name: selectedKeyword), paging: tagPaging) {[weak self] (tags, error) in
            guard let strongSelf = self else { return }
            if error == nil {
                let data = tags.map{TagCellViewModel(tag: $0)}
                strongSelf.handlePagingData(data, br: strongSelf.tags, paging: strongSelf.tagPaging)
            }
        }
    }
}
