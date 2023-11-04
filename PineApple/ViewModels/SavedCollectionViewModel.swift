//
//  SavedCollectionViewModel.swift
//  PineApple
//
//  Created by Tao Man Kit on 3/10/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class SavedCollectionViewModel: ViewModel {
    
    // MARK: - Properties
    enum Mode {
        case add
        case rename
        case delete
        
        var title: String {
            switch self {
            case .add: return "COLLECTION NAME"
            case .rename: return "Rename"
            case .delete: return "Are you sure you want to delete this?"
            }
        }
    }
    
    var model: ItineraryDetailViewModel?
    var collectionModel: SavedCollectionDetailViewModel?
    var collectionName = BehaviorRelay<String>(value: "")
    var collections = BehaviorRelay<[SavedCollection]>(value: [])
    var allCollections = [SavedCollection]()
    var allItineraries = BehaviorRelay<[Itinerary]>(value: [])
    private let disposeBag = DisposeBag()
    var itineraryViewModel: ItineraryViewModel? {
        return model?.model
    }
    var mode: Mode = .add
    var paging = Paging()
    var isAnimated = true
    
    // MARK: - Init
    init() {}
    
    init(model: ItineraryDetailViewModel) {
        self.model = model
        setup(with: model)
    }
    
    init(collectionModel: SavedCollectionDetailViewModel, mode: Mode) {
        self.collectionModel = collectionModel
        self.mode = mode
        setup(with: collectionModel)
    }
}

// MARK: - ViewModel
extension SavedCollectionViewModel {
    func setup(with model: ItineraryDetailViewModel) {
        collectionName.accept(itineraryViewModel?.activityViewModels.first?.city.value ?? "")
        
    }
    
    func setup(with model: SavedCollectionDetailViewModel) {
        self.model = model.itineraries.value.first
        collectionName.accept(model.name.value)
    }
    
    func updateModel() {
        if let model = collectionModel?.model {
            collectionModel?.setup(with: model)
        }
    }
}

// MARK: - Public
extension SavedCollectionViewModel {
    
    func refresh(_ itinerary: Itinerary) {
        for i in 0..<allCollections.count {
            if let index = (allCollections[i].itineraries.map{$0.itinerary}).firstIndex(of: itinerary) {
                allCollections[i].itineraries[index].model.setup(with: itinerary)
                break
            }
        }        
    }
    
    func refresh(_ collection: SavedCollection) {
        var newCollection = allCollections
        
        if let index = allCollections.firstIndex(of: collection) {
            if collection.isDeleted {
                newCollection.remove(at: index)
            } else {
                newCollection[index] = collection
            }
        }
        collections.accept(newCollection)
        
    }
    
    func handleSharedCollection(_ id: String, name: String, uid: String, completionHandler: @escaping RequestDidCompleteBlock) {
        
        func getAllItineraries(in collection: SavedCollection, completionHandler: @escaping RequestDidCompleteBlock) {
            SavedCollection.findItineraries(in: collection, userId: uid, paging: paging) { [weak self](itineraries, error) in
                guard let strongSelf = self else { return }
                strongSelf.handlePagingData(itineraries, br: strongSelf.allItineraries, paging: strongSelf.paging)
                if !strongSelf.paging.isMore.value {
                    // create collection
                    var newCollection = collection
                    newCollection.itineraries = strongSelf.allItineraries.value.map{ItineraryDetailViewModel(itinerary: $0)}
                    SavedCollection.create(newCollection) { (result, error) in
                        strongSelf.paging.start = 0
                        strongSelf.allItineraries.accept([])
                        if let error = error {
                            completionHandler(false, error)
                        } else {
                            strongSelf.getCollectionList(completionHandler)
                        }
                    }
                } else {
                    getAllItineraries(in: collection, completionHandler: completionHandler)
                }
                
            }
        }
        
        // Fetch the itineraries
        let collection = SavedCollection(id: id, name: name, itineraries: [])
        getAllItineraries(in: collection, completionHandler: completionHandler)
                        
    }
    
    func getCollectionList(_ completionHandler:  RequestDidCompleteBlock? = nil) {
        if let currentUser = Globals.currentUser {
            
            SavedCollection.findByUserId(currentUser.id) { [weak self](collections, error) in
                guard let strongSelf = self else { return }
                if let error = error {
                    completionHandler?(false, error)
                } else {
                    var _collections = collections
                    for (index, collection) in _collections.enumerated() {
                        let newItineraries = collection.itineraries
                        for i in 0..<newItineraries.count {
                            let collectionRef = SavedCollection(id: collection.id, name: collection.name, itineraries: [])
                            newItineraries[i].collection = collectionRef
                        }
                        _collections[index].itineraries = newItineraries
                    }
                    strongSelf.allCollections = _collections
                    strongSelf.collections.accept(_collections)
                    completionHandler?(true, nil)
                }
            }
            
        }
    }
    
    func search() {
        if collectionName.value.isEmpty {
            collections.accept(allCollections)
        } else {
            let newValue = collections.value.filter {$0.name.lowercased().contains(collectionName.value.lowercased())}
            collections.accept(newValue)
        }        
    }
    
    func save(_ completionHandler: @escaping RequestDidCompleteBlock) {
        guard Globals.currentUser != nil else { return }
        if mode == .add {
            let add = {[weak self] in
                guard let strongSelf = self else { return }
                let collections = strongSelf.allCollections.filter{$0.name == strongSelf.collectionName.value}
                if collections.isEmpty {
                    // create collection
                    var collection = SavedCollection(id: "", name: strongSelf.collectionName.value, itineraries: [strongSelf.model!])
                    
                    SavedCollection.create(collection) { [weak self] (id, error) in
                        guard let strongSelf = self else { return }
                        if error == nil {
                            collection.id = id
                            strongSelf.allCollections.insert(collection, at: 0)
                            strongSelf.model?.save(completionHandler)
                        } else {
                            completionHandler(false, error)
                        }
                    }
                } else {
                    // save to collection
                    var collection = collections.first!
                    collection.itineraries.insert(strongSelf.model!, at: 0)
                    if collection.itineraries.count > 3 {
                        collection.itineraries = collection.itineraries[0..<3].map{$0}
                    }
                                    
                    SavedCollection.saveItinerary(collection) {[weak self] (result, error) in
                        if error == nil {
                            self?.model?.save(completionHandler)
                        } else {
                            completionHandler(false, error)
                        }
                    }
                }
            }
            
            if model!.itinerary.user.email.isEmpty {
                User.findById(model!.itinerary.user.id) {[weak self] (user, error) in
                    guard let strongSelf = self else { return }
                    if let user = user {
                        var itinerary = strongSelf.model!.itinerary
                        itinerary.user = user
                        strongSelf.model!.model.setModel(itinerary)
                    }
                    add()
                }
            } else {
                add()
            }
        } else {
            // Rename
            rename(completionHandler)
        }
    }
    
    func rename(_ completionHandler: @escaping RequestDidCompleteBlock) {
        // Rename
        if (collections.value.filter {$0.name.lowercased() == collectionName.value.lowercased()}).isEmpty {
            collectionModel?.name.accept(collectionName.value)
            collectionModel?.updateModel()
            
            SavedCollection.save(collectionModel!.model) {[weak self] (result, error) in
                guard let strongSelf = self else { return }
                NotificationCenter.default.post(name: .didCollectionDidUpdated, object: nil, userInfo: ["collection": strongSelf.collectionModel!.model, "action": "rename"])
                completionHandler(result, error)
            }
        } else {
            completionHandler(false, "A collection with the same Name already exist")
        }
    }
    
    func delete(_ completionHandler: @escaping RequestDidCompleteBlock) {
        
        SavedCollection.findItineraries(in: collectionModel!.model, paging: paging) { [weak self](itineraries, error) in
            guard let strongSelf = self else { return }
            strongSelf.handlePagingData(itineraries, br: strongSelf.allItineraries, paging: strongSelf.paging)
            if !strongSelf.paging.isMore.value {
                SavedCollection.delete(strongSelf.collectionModel!.model, itineraries: strongSelf.allItineraries.value) {[weak self] (result, error) in
                    guard let strongSelf = self else { return }
                    strongSelf.paging.start = 0
                    strongSelf.allItineraries.accept([])
                    completionHandler(result, error)
                }
                
            } else {
                strongSelf.delete(completionHandler)
            }
            
        }
    }
}

