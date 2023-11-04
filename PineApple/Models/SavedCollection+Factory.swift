//
//  SavedCollection+Factory.swift
//  PineApple
//
//  Created by Tao Man Kit on 24/10/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import Firebase

extension SavedCollection {
    var collection: CollectionReference { return Firestore.firestore()
        .collection("users")
        .document(Globals.currentUser!.id)
        .collection("collections") }
    
    var ref: DocumentReference { return collection.document(id) }
}

// MARK: - Create
extension SavedCollection {
    static func create(_ savedCollection: SavedCollection, completionHandler: @escaping (String, Error?) -> Void) {
        let ref = savedCollection.collection.document()
        var newSavedCollection = savedCollection
        newSavedCollection.id = ref.documentID
        Firestore.firestore().runTransaction({ (transaction, errorPointer) -> Any? in
                                   
            var newItineraries = [ItineraryDetailViewModel]()
            if savedCollection.itineraries.count > 3 {
                newItineraries = savedCollection.itineraries[0..<3].map{$0}
            } else {
                newItineraries = savedCollection.itineraries
            }
            
            // collection data
            transaction.setData([
                "id": ref.documentID,
                "name": savedCollection.name,
                "itineraries": newItineraries.map{$0.itinerary.dict},
                "isDeleted": false,
                "lastUpdated": Date().timeIntervalSince1970,
                "createdDate": Date().timeIntervalSince1970
            ], forDocument: ref)
            
            // itineraries
            for itinerary in (savedCollection.itineraries.map{$0.itinerary}) {
                let id = Globals.currentUser!.id + "_" + itinerary.id
                var data = itinerary.dict
                data["uid"] = Globals.currentUser!.id
                data["cid"] = ref.documentID
                let itineraryRef = ref.collection("collection_itineraries").document(id)
                transaction.setData(data, forDocument: itineraryRef)
                                                 
                // add saved itinerary to user's saved itineraries
                User.addSavedItinerary(itinerary, collection: newSavedCollection, transaction: transaction)
            }
            
            
            return nil
        }) { (object, error) in
            if let error = error {
                print("Transaction failed: \(error)")
                completionHandler("", error)
            } else {
                print("Transaction successfully committed!")
                
                for itinerary in (savedCollection.itineraries.map{$0.itinerary}) {
                    Itinerary.updateCount(of: .save, itinerary: itinerary, collection: newSavedCollection)
                }
                completionHandler(ref.documentID, nil)
            }
        }
    }
}

// MARK: - Update
extension SavedCollection {
    
    static func save(_ savedCollection: SavedCollection, completionHandler: @escaping RequestDidCompleteBlock) {
        let ref = savedCollection.ref
        Firestore.firestore().runTransaction({ (transaction, errorPointer) -> Any? in
            
            transaction.updateData([
                         "name": savedCollection.name,
                         "lastUpdated": Date().timeIntervalSince1970
                         ], forDocument: ref)
            
            return nil
        }) { (object, error) in
                if let error = error {
                    print("Error writing document: \(error)")
                    completionHandler(false, error)
                } else {
                    print("Document successfully written!")
                    completionHandler(true, nil)
                }
        }
    }
    
    static func saveItinerary(_ savedCollection: SavedCollection, completionHandler: @escaping RequestDidCompleteBlock) {
        let ref = savedCollection.ref
        let itineraryDetailViewModel = savedCollection.itineraries.first!
        Firestore.firestore().runTransaction({ (transaction, errorPointer) -> Any? in
                        
            
            transaction.updateData([
                         "name": savedCollection.name,
                         "itineraries": savedCollection.itineraries.map{$0.itinerary.dict},
                         "lastUpdated": Date().timeIntervalSince1970
                         ], forDocument: ref)
            
            // itineraries
            
            let id = Globals.currentUser!.id + "_" + itineraryDetailViewModel.itinerary.id
            var data = itineraryDetailViewModel.itinerary.dict
            data["uid"] = Globals.currentUser!.id
            data["cid"] = ref.documentID
            let itineraryRef = ref.collection("collection_itineraries").document(id)
            transaction.setData(data, forDocument: itineraryRef)
            
            // add saved itinerary to user's saved itineraries
            User.addSavedItinerary(itineraryDetailViewModel.itinerary, collection: savedCollection, transaction: transaction)
            
            return nil
        }) { (object, error) in
                if let error = error {
                    print("Error writing document: \(error)")
                    completionHandler(false, error)
                } else {
                    print("Document successfully written!")
                    completionHandler(true, nil)
                    
                    Itinerary.updateCount(of: .save, itinerary: itineraryDetailViewModel.itinerary, collection: savedCollection)
                }
        }
    }
    
    static func remove(itinerary: Itinerary, from savedCollection: SavedCollection, completionHandler: @escaping RequestDidCompleteBlock) {
        let ref = savedCollection.ref
        
        Firestore.firestore().runTransaction({ (transaction, errorPointer) -> Any? in
            transaction.updateData([
                "itineraries": savedCollection.itineraries.map{$0.itinerary.dict},
                "lastUpdated": Date().timeIntervalSince1970
            ], forDocument: ref)
            
            // itineraries
            let id = Globals.currentUser!.id + "_" + itinerary.id
            let itineraryRef = ref.collection("collection_itineraries").document(id)
            transaction.deleteDocument(itineraryRef)
            
            // remove saved itinerary to user's saved itineraries
            User.removeSavedItinerary(itinerary, collection: savedCollection, transaction: transaction)
            
            return nil
        }) { (object, error) in
            if let error = error {
                print("Error writing document: \(error)")
                completionHandler(false, error)
            } else {
                print("Document successfully written!")
                Itinerary.updateCount(of: .save, itinerary: itinerary, collection: savedCollection, isIncrement: false)
                NotificationCenter.default.post(name: .didCollectionDidUpdated, object: nil, userInfo: ["collection": savedCollection, "unsavedItinerary": itinerary])
                completionHandler(true, nil)
                
            }
        }
    }
    
    static func delete(_ savedCollection: SavedCollection, itineraries: [Itinerary], completionHandler: @escaping RequestDidCompleteBlock) {
        let ref = savedCollection.ref
        
        Firestore.firestore().runTransaction({ (transaction, errorPointer) -> Any? in

            transaction.updateData([
                "isDeleted": true,
                "lastUpdated": Date().timeIntervalSince1970
            ], forDocument: ref)
            
            // remove saved itinerary to user's saved itineraries
            for itinerary in itineraries {
                User.removeSavedItinerary(itinerary, collection: savedCollection, transaction: transaction)
            }

            return nil
        }) { (object, error) in
            if let error = error {
                print("Error writing document: \(error)")
                completionHandler(false, error)
            } else {
                print("Document successfully written!")
                for itinerary in itineraries {
                    var newItinerary = itinerary
                    newItinerary.savedCount -= 1
                    Itinerary.updateCount(of: .save, itinerary: itinerary, collection: savedCollection, isIncrement: false)
                    NotificationCenter.default.post(name: .didItineraryDidUpdated, object: nil, userInfo: ["itinerary": newItinerary])
                }
                
                var newSavedCollection = savedCollection
                newSavedCollection.isDeleted = true
                NotificationCenter.default.post(name: .didCollectionDidUpdated, object: nil, userInfo: ["collection": newSavedCollection])
                completionHandler(true, nil)
                
            }
        }
    }
}

// MARK: - Query
extension SavedCollection {
    static func findByUserId(_ id: String, paging: Paging? = nil, completionHandler: @escaping ([SavedCollection], Error?) -> Void) {
        if let currentUser = Globals.currentUser {
            var query = Firestore.firestore().collection("users")
                .document(currentUser.id)
                .collection("collections")
                .whereField("isDeleted", isEqualTo: false)
                .order(by: "createdDate", descending: true)
            
            if let lastDocumentSnapshot = paging?.lastDocumentSnapshot {
                query = query.start(afterDocument: lastDocumentSnapshot)
            }
            
            query.limit(to: paging?.itemPerPage ?? ITEM_PER_PAGE)
                .getDocuments() { (querySnapshot, error) in
                    if let error = error {
                        print("Error getting documents: \(error)")
                        completionHandler([], error)
                    } else {
                        if querySnapshot!.documents.isEmpty {
                            paging?.isMore.accept(false)
                            completionHandler([], nil)
                        } else {
                            let collections = querySnapshot!.documents.map{SavedCollection(data: $0.data())}
                            
                            if let paging = paging {
                                paging.lastDocumentSnapshot = querySnapshot!.documents.last
                                paging.isMore.accept(collections.count >= paging.itemPerPage)
                            }
                            completionHandler(collections, nil)
                        }
                    }
            }
            
        }
    }
    
    static func findItineraries(in collection: SavedCollection, userId: String? = nil, paging: Paging? = nil, completionHandler: @escaping ([Itinerary], Error?) -> Void) {
        if let currentUser = Globals.currentUser {
            var query = Firestore.firestore().collection("users")
                .document(userId == nil ? currentUser.id : userId!)
                .collection("collections")
                .document(collection.id)
                .collection("collection_itineraries")
                .order(by: "createdDate", descending: true)
            
            if let lastDocumentSnapshot = paging?.lastDocumentSnapshot {
                query = query.start(afterDocument: lastDocumentSnapshot)
            }
            
            query.limit(to: paging?.itemPerPage ?? ITEM_PER_PAGE)
                .getDocuments() { (querySnapshot, error) in
                    if let error = error {
                        print("Error getting documents: \(error)")
                        completionHandler([], error)
                    } else {
                        if querySnapshot!.documents.isEmpty {
                            paging?.isMore.accept(false)
                            completionHandler([], nil)
                        } else {
                            let itineraries = querySnapshot!.documents.map{Itinerary(data: $0.data())}
                            
                            if let paging = paging {
                                paging.lastDocumentSnapshot = querySnapshot!.documents.last
                                paging.isMore.accept(itineraries.count >= paging.itemPerPage)
                            }
                            completionHandler(itineraries, nil)
                            
                        }
                    }
            }
            
        }
    }
}
