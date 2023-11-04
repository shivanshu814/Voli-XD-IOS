//
//  SavedCollectionDetailViewModel.swift
//  PineApple
//
//  Created by Tao Man Kit on 4/10/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class SavedCollectionDetailViewModel: ViewModel {
    private var _model: SavedCollection
    var model: SavedCollection { return _model }
    var itineraries = BehaviorRelay<[ItineraryDetailViewModel]>(value: [])    
    var name = BehaviorRelay<String>(value: "")
    var paging = Paging()
    var isAnimated = true
    
    init(model: SavedCollection) {
        self._model = model
        setup(with: model)
    }
}

// MARK: - ViewModel
extension SavedCollectionDetailViewModel {
    func setup(with model: SavedCollection) {
        name.accept(_model.name)
    }
    
    func updateModel() {
        _model.name = name.value
    }
}

// MARK: - Public
extension SavedCollectionDetailViewModel {
    
    func refresh(_ itinerary: Itinerary) {
        if let index = (itineraries.value.map{$0.itinerary}).firstIndex(of: itinerary) {
            itineraries.value[index].model.setup(with: itinerary)            
        }
    }
    
    func refresh(_ collection: SavedCollection, unsavedItinerary: Itinerary? = nil) {
        guard model == collection && !collection.itineraries.isEmpty else { return }
        
        var newItineraries = itineraries.value
        if unsavedItinerary == nil {
            newItineraries.append(collection.itineraries.first!)
        } else {
            newItineraries.removeObject(ItineraryDetailViewModel(itinerary: unsavedItinerary!))
        }
                
        itineraries.accept(newItineraries)
        
    }
    
    func getItineraries(_ completionHandler: @escaping RequestDidCompleteBlock) {
        SavedCollection.findItineraries(in: model, paging: paging) { [weak self] (itineraries, error) in
            guard let strongSelf = self else { return }
            if let error = error {
                completionHandler(false, error)
            } else {
                let newItineraries = itineraries.map{ItineraryDetailViewModel(itinerary: $0)}
                let collectionRef = SavedCollection(id: strongSelf.model.id, name: strongSelf.model.name, itineraries: [])
                for i in 0..<newItineraries.count {
                    var newItinerary = newItineraries[i].itinerary
                    newItinerary.updateLikeCommentSave()
                    newItineraries[i].model.setup(with: newItinerary)
                    newItineraries[i].collection = collectionRef
                }
                strongSelf.handlePagingData(newItineraries, br: strongSelf.itineraries, paging: strongSelf.paging)
                completionHandler(true, nil)
            }
        }
    }
    
    
    func remove(itinerary: ItineraryDetailViewModel) {
        var newItineraries = itineraries.value
        newItineraries.removeObject(itinerary)
        itineraries.accept(newItineraries)
    }
}
