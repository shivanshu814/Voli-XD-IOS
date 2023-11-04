//
//  Tag+Factory.swift
//  PineApple
//
//  Created by Tao Man Kit on 22/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import Firebase

let tag_shards = "shards"

extension Tag {
    
    var collection: CollectionReference {
        return Firestore.firestore().collection("tags")
    }
    
    var ref: DocumentReference {
        return Firestore.firestore().collection("tags").document(name.lowercased().replacingOccurrences(of: "/", with: ""))
    }
    
}

// MARK: - Create
extension Tag {

    static func create(_ tag: Tag, isItinerary: Bool = true, transaction: Transaction) {
        
        let ref = tag.ref
        transaction.setData([
            "name": tag.name,
            "taggedCount": isItinerary ? 1 : 0,
            "keywords": tag.keywords,
            "numShards": globalNumShards
        ], forDocument: ref)
        
        // count
        for i in 0...globalNumShards {
            let _ref = ref.collection(tag_shards).document(String(i))
            transaction.setData(["count": i == 0 ? 1 : 0], forDocument: _ref)
        }
    }
}

// MARK: - Update
extension Tag {
    static func update(_ newTags: [Tag], deletedTags: [Tag] = [], isItinerary: Bool = true, transaction: Transaction) {
        var tagsToBeUpdate = [Tag]()
        var tagsToBeCreate = [Tag]()
        var shardIds = [Int]()
        
        newTags.forEach {
            let shardId = Int(arc4random_uniform(UInt32(globalNumShards)))
            let shardRef = $0.ref.collection("shards").document(String(shardId))
            if (try? transaction.getDocument(shardRef).exists) ?? false {
                tagsToBeUpdate.append($0)
                shardIds.append(shardId)
            } else {
                tagsToBeCreate.append($0)
            }
        }
        
        for tag in deletedTags {
            Tag.decrementTagCount(of: tag, transaction: transaction)
        }
        
        for (index, tag) in tagsToBeUpdate.enumerated() {
            Tag.incrementTagCount(of: tag, shardId: shardIds[index], transaction: transaction)
        }
        
        for tag in tagsToBeCreate {
            Tag.create(tag, transaction: transaction)
        }
    }
}

// MARK: - Query
extension Tag {
    static func isExist(_ tag: Tag, completionHandler: @escaping (Bool, Error?) -> Void) {
        let ref = tag.ref
        ref.getDocument { (querysnapshot, error) in
            if error != nil {
                print("Document Error: ", error!)
                completionHandler(false, error)
            } else {
                if let querysnapshot = querysnapshot, querysnapshot.exists {
                    completionHandler(true, error)
                } else {
                    completionHandler(false, error)
                }
            }
        }
    }
    
    static func findPropularTags(by option: ItineraryFilterOption, paging: Paging? = nil, completionHandler: @escaping ([Tag], Error?) -> Void) {
        
        Firestore.firestore().collection("tags")
            .order(by: "taggedCount", descending: true)
            .limit(to: paging?.itemPerPage ?? ITEM_PER_PAGE)
            .getDocuments() { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                    completionHandler([], error)
                } else {
                    if querySnapshot!.documents.isEmpty {
                        completionHandler([], nil)
                    } else {
                        let tags = querySnapshot!.documents.map{Tag(data: $0.data())}
                        completionHandler(tags, nil)
                    }
                }
        }
    }
    
    static func findFeaturedTags(_ paging: Paging? = nil, completionHandler: @escaping ([Tag], Error?) -> Void) {
        Firestore.firestore().collection("featuredTags")
            .getDocuments() { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                    completionHandler([], error)
                } else {
                    if querySnapshot!.documents.isEmpty {
                        completionHandler([], nil)
                    } else {
                        let tags = querySnapshot!.documents.map{Tag(data: $0.data())}
                        completionHandler(tags, nil)
                    }
                }
        }
    }

    static func findByKeyword(_ keyword: Keyword, paging: Paging? = nil, completionHandler: @escaping ([Tag], Error?) -> Void) {
            
        var query = Firestore.firestore().collection("tags")
            .whereField("keywords", arrayContains: keyword.name)
            .whereField("taggedCount", isGreaterThan: 0)
            .order(by: "taggedCount", descending: true)
        
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
                    let tags = querySnapshot!.documents.map{Tag(data: $0.data())}
                    
                    if let paging = paging {
                        paging.lastDocumentSnapshot = querySnapshot!.documents.last
                        paging.isMore.accept(tags.count >= paging.itemPerPage)
                    }
                    completionHandler(tags, nil)
                }
            }
        }
    }
}

// MARK: - Count
extension Tag {
    
    static func updateTagCount(_ tag: Tag) {
        let ref = tag.ref
        FirebaseHelper.getSharedCount(ref: ref, shards: tag_shards) { (count, error) in
            if error == nil {
                ref.updateData(["taggedCount": count]) { (error) in
                    if let error = error {
                        print("Transaction failed: \(error)")
                    } else {
                        print("Transaction successfully committed!")
                    }
                }
            }
        }
    }
    
    static func incrementTagCount(of tag: Tag, shardId: Int? = nil, transaction: Transaction? = nil) {
        FirebaseHelper.updateCounter(ref: tag.ref, shardId: shardId, value: 1, transaction: transaction)
    }
    
    static func decrementTagCount(of tag: Tag, shardId: Int? = nil, transaction: Transaction? = nil) {
        FirebaseHelper.updateCounter(ref: tag.ref, shardId: shardId, value: -1, transaction: transaction)
    }
}
