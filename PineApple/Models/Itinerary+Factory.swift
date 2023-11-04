//
//  Itinerary+Factory.swift
//  PineApple
//
//  Created by Tao Man Kit on 28/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import Alamofire
import Firebase
import FirebaseFirestore

let liked_shards = "liked_shards"
let comment_shards = "comment_shards"
let saved_shards = "saved_shards"

extension Itinerary {
    
    enum CountField: Int {
        case like
        case save
        case comment
        case likeComment
        
        var fieldName: String {
            switch self {
            case .like: return "likeCount"
            case .save: return "savedCount"
            case .comment: return "commentCount"
            case .likeComment: return "likeCount"
            }
        }
    }
    
    var collection: CollectionReference { return Firestore.firestore().collection("itineraries") }
    
    var ref: DocumentReference { return collection.document(id) }
             
}

// MARK: - Create
extension Itinerary {
    
    static func create(_ itinerary: Itinerary, completionHandler: @escaping (String, Error?) -> Void) {
        let ref = itinerary.collection.document()
                        
        Firestore.firestore().runTransaction({ (transaction, errorPointer) -> Any? in
            // tags
            Tag.update(itinerary.tags.map{Tag(name: $0)}, transaction: transaction)
                        
            // data
            transaction.setData([
                "id": ref.documentID,
                "title": itinerary.title,
                "description": itinerary.description,
                "heroImage": itinerary.heroImage,
                "heroImageThumbnail": itinerary.heroImageThumbnail,
                "coverVideo": itinerary.coverVideo,
                "activities": itinerary.activities.map{$0.dict},
                "user": itinerary.user.short_dict,
                "isPrivate": itinerary.isPrivate,
                "isAllowContact": itinerary.isAllowContact,
                "duration": itinerary.duration,
                "distance": itinerary.distance,
                "likeCount" : 0,
                "commentCount" : 0,
                "savedCount" : 0,
                "createdDate": itinerary.createDate.timeIntervalSince1970,
                "location": itinerary.city,
                "state": itinerary.city == "hong kong" ? "" : itinerary.state,
                "country": itinerary.country,
                "tags": itinerary.tags,
                "searchTags": itinerary.tags.map{$0.lowercased()},
                "keywords": itinerary.keywords,
                "numShards": globalNumShards,
                "lastUpdated": Date().timeIntervalSince1970,
                "isDelete": false,
            ], forDocument: ref)
            
            // count
            for i in 0...globalNumShards {
                let _ref = ref.collection(liked_shards).document(String(i))
                transaction.setData(["count": 0], forDocument: _ref)
            }
            
            for i in 0...globalNumShards {
                let _ref = ref.collection(comment_shards).document(String(i))
                transaction.setData(["count": 0], forDocument: _ref)
            }
            
            for i in 0...globalNumShards {
                let _ref = ref.collection(saved_shards).document(String(i))
                transaction.setData(["count": 0], forDocument: _ref)
            }
                        
            // update user itineraries count
            if !itinerary.isPrivate {
                let userRef = Firestore.firestore().collection("users").document(itinerary.user.id)
                transaction.updateData(["itineraryCount": FieldValue.increment(Int64(1))], forDocument: userRef)
                
            }
            
            return nil
        }) { (object, error) in
            if let error = error {
                print("Transaction failed: \(error)")
                completionHandler("", error)
            } else {
                print("Transaction successfully committed!")
                // create keywords                
                (itinerary.keywords.map{Keyword(name: $0)}).forEach {
                    Keyword.create($0)
                }
                
                // update tag count
                for tag in (itinerary.tags.map{Tag(name: $0)}) {
                    Tag.updateTagCount(tag)
                }
                
                completionHandler(ref.documentID, nil)
                
                if let user = Globals.currentUser, !itinerary.isPrivate {
                    PushNotificationManager.shared.sendGroupPushNotification(userId: user.id, title: "", body: "\(user.displayName) has published a new itinerary \"\(itinerary.title)\".")                    
                }
            }
        }
    }
    
    static func createComment(_ itinerary: Itinerary, comment: Comment, completionHandler: ((String, Error?) -> Void)?) {
        
        guard let currentUser = Globals.currentUser else { return }
        
        let ref = itinerary.ref
            .collection("comments")
            .document()

        Firestore.firestore().runTransaction({ (transaction, errorPointer) -> Any? in
            // data
            transaction.setData([
                "id": ref.documentID,
                "user": currentUser.short_dict,
                "message": comment.message,
                "likeCount": 0,
                "date": Date().timeIntervalSince1970,
                "tags": comment.tags,
                "numShards": globalNumShards,
                "createdDate": Date().timeIntervalSince1970
            ], forDocument: ref)
            
            // count
            for i in 0...globalNumShards {
                let _ref = ref.collection(liked_shards).document(String(i))
                transaction.setData(["count": 0], forDocument: _ref)
            }
            
            User.addCommentedItinerary(itinerary, transaction: transaction)
            
            return nil
        }) { (object, error) in
            if let error = error {
                print("Transaction failed: \(error)")
                completionHandler?("", error)
            } else {
                print("Transaction successfully committed!")
                completionHandler?(ref.documentID, nil)
                Itinerary.updateCount(of: .comment, itinerary: itinerary)
                
                if itinerary.user.isCommentSaveLikeEnabled && !itinerary.isOwner {
                    PushNotificationManager.shared.sendPushNotification(to: itinerary.user.token, title: "", body: "\(Globals.currentUser!.displayName) commented on your itinerary \"\(itinerary.title)\"")
                }
            }
        }
    }
}

// MARK: - Query
extension Itinerary {
    static func find(by option: ItineraryFilterOption, filterId: String? = nil, paging: Paging? = nil, completionHandler: @escaping ([Itinerary], Error?) -> Void) {
            
        var query = Firestore.firestore().collection("itineraries")
            .whereField("isPrivate", isEqualTo: false)
            .whereField("isDelete", isEqualTo: false)
        
        if !option.location.isEmpty {
            query = query
                .whereField("country", isEqualTo: option.country.lowercased())
                .whereField("state", isEqualTo: option.state.lowercased())
                .whereField("location", isEqualTo: option.location.lowercased())                
        }
                
        if !option.tags.isEmpty {
            query = query.whereField("searchTags", arrayContains: option.tags.first!.lowercased())
        }
        
        query = query.order(by: option.sortBy.fieldName, descending: option.sortBy.descending)
            
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
                    var itineraries = querySnapshot!.documents.map{Itinerary(data: $0.data())}
                    if let filterId = filterId {
                        itineraries = itineraries.filter {$0.id != filterId}
                    }
                    if let paging = paging {
                        paging.lastDocumentSnapshot = querySnapshot!.documents.last
                        paging.isMore.accept(itineraries.count >= paging.itemPerPage)
                    }                    
                    completionHandler(itineraries, nil)
                }
            }
        }
    }
    
    static func findByUserId(_ id: String, filterId: String? = nil, paging: Paging? = nil, completionHandler: @escaping ([Itinerary], Error?) -> Void) {
        
        var query = Firestore.firestore().collection("itineraries")
            .whereField("user.id", isEqualTo: id)
            .whereField("isDelete", isEqualTo: false)
            
        if id != Globals.currentUser?.id {
            query = query.whereField("isPrivate", isEqualTo: false)
                
        }
        
        query = query.order(by: "createdDate", descending: true)
        
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
                        var itineraries = querySnapshot!.documents.map{Itinerary(data: $0.data())}
                        if let filterId = filterId {
                            itineraries = itineraries.filter {$0.id != filterId}
                        }
                        
                        if let paging = paging {
                            paging.lastDocumentSnapshot = querySnapshot!.documents.last
                            paging.isMore.accept(itineraries.count >= paging.itemPerPage)
                        }
                        completionHandler(itineraries, nil)
                    }
                }
        }
    }
    
    static func findById(_ id: String, completionHandler: @escaping (Itinerary?, Error?) -> Void) {
        Firestore.firestore().collection("itineraries").document(id)
            .getDocument(completion: { (querySnapshot, error) in
                if let data = querySnapshot?.data() {
                    let itinerary = Itinerary(data: data)
                    completionHandler(itinerary, nil)
                } else {
                    completionHandler(nil, error ?? "Server error")
                }
        })
                        
    }
    
    static func findComments(_ itinerary: Itinerary, paging: Paging, completionHandler: @escaping ([Comment], Error?) -> Void) {

        var query = itinerary.ref
            .collection("comments")
            .order(by: "createdDate", descending: true)
        
        if let lastDocumentSnapshot = paging.lastDocumentSnapshot {
            query = query.start(afterDocument: lastDocumentSnapshot)
        }
        
        query.limit(to: paging.itemPerPage)
            .getDocuments() { (querySnapshot, error) in
                if querySnapshot!.documents.isEmpty {
                    paging.isMore.accept(false)
                    completionHandler([], nil)
                } else {
                    let comments = querySnapshot!.documents.map{Comment(data: $0.data())}
                    
                    paging.lastDocumentSnapshot = querySnapshot!.documents.last
                    paging.isMore.accept(comments.count >= paging.itemPerPage)
                    completionHandler(comments, nil)
                }
        }
                        
    }
    
    static func findPopularItineraries(_ paging: Paging? = nil, completionHandler: @escaping ([Itinerary], Error?) -> Void) {
            
        var query = Firestore.firestore().collection("itineraries")
            .whereField("isPrivate", isEqualTo: false)
            .whereField("isDelete", isEqualTo: false)
            .order(by: "likeCount", descending: true)
            
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
    
    static func findByKeyword(_ keyword: Keyword, paging: Paging? = nil, completionHandler: @escaping ([Itinerary], Error?) -> Void) {
            
        var query = Firestore.firestore().collection("itineraries")
            .whereField("isPrivate", isEqualTo: false)
            .whereField("isDelete", isEqualTo: false)
            .whereField("keywords", arrayContains: keyword.name)
            .order(by: "likeCount", descending: true)
        
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

// MARK: - Update
extension Itinerary {
    
    static func debug() {
        Firestore.firestore().collection("itineraries")
            .limit(to: 100).getDocuments { (querySnapshot, error) in
                let itineraries = querySnapshot!.documents.map{Itinerary(data: $0.data())}
                
                itineraries.forEach {
                    $0.ref.updateData(["isDelete": false])
                }
        }
    }
    
    static func update(_ itinerary: Itinerary, privateChanged: Bool, tags: [Tag], deletedTags: [Tag] = [], completionHandler: @escaping RequestDidCompleteBlock) {
        let ref = itinerary.ref
        Firestore.firestore().runTransaction({ (transaction, errorPointer) -> Any? in
            
            // tags
            Tag.update(tags, deletedTags: deletedTags, transaction: transaction)
            
            // data
            transaction.updateData([
                "title": itinerary.title,
                "description": itinerary.description,
                "heroImage": itinerary.heroImage,
                "heroImageThumbnail": itinerary.heroImageThumbnail,
                "coverVideo": itinerary.coverVideo,
                "activities": itinerary.activities.map{$0.dict},
                "user": itinerary.user.short_dict,
                "isPrivate": itinerary.isPrivate,
                "isAllowContact": itinerary.isAllowContact,
                "duration": itinerary.duration,
                "distance": itinerary.distance,
                "location": itinerary.city,
                "state": itinerary.state,
                "country": itinerary.country,
                "tags": itinerary.tags,
                "searchTags": itinerary.tags.map{$0.lowercased()},
                "keywords": itinerary.keywords,
                "lastUpdated": Date().timeIntervalSince1970
            ], forDocument: ref)
            
            // update user itineraries count
            
            if privateChanged {
                let userRef = Firestore.firestore().collection("users").document(itinerary.user.id)
                transaction.updateData(["itineraryCount": FieldValue.increment(Int64(itinerary.isPrivate ? -1 : 1))], forDocument: userRef)                
            }
            
            return nil
        }) { (object, error) in
            if let error = error {
                print("Transaction failed: \(error)")
                completionHandler(false, error)
            } else {
                print("Transaction successfully committed!")
                // create keywords
                (itinerary.keywords.map{Keyword(name: $0)}).forEach {
                    Keyword.create($0)
                }
                // update tag count
                for tag in tags {
                    Tag.updateTagCount(tag)
                }
                for deletedTags in tags {
                    Tag.updateTagCount(deletedTags)
                }
                completionHandler(true, nil)
                NotificationCenter.default.post(name: .didItineraryDidUpdated, object: nil, userInfo: ["itinerary": itinerary])
                
            }
        }
    }
        
    static func refreshItinerary(_ itinerary: Itinerary, type: CountField, count: Int) {
        var parameters:[String: Any] = ["id": itinerary.id]
        switch type {
        case .comment: parameters["commentCount"] = count
        case .like: parameters["likeCount"] = count
        case .save: parameters["savedCount"] = count
        default:
            break
        }
        Alamofire.request(URL(string: URL_UPDATE_ITINERARY)!, method: .post, parameters: parameters, encoding: JSONEncoding.default).response { (response) in            
        }
    }
    
    static func delete(_ itinerary: Itinerary, completionHandler: @escaping RequestDidCompleteBlock) {
        let ref = itinerary.ref
        
        Firestore.firestore().runTransaction({ (transaction, errorPointer) -> Any? in

            transaction.updateData([
                "isDelete": true,
                "lastUpdated": Date().timeIntervalSince1970
            ], forDocument: ref)
            
            if !itinerary.isPrivate {
                let userRef = Firestore.firestore().collection("users").document(itinerary.user.id)
                transaction.updateData(["itineraryCount": FieldValue.increment(Int64(-1))], forDocument: userRef)                
            }

            return nil
        }) { (object, error) in
            if let error = error {
                print("Error writing document: \(error)")
                completionHandler(false, error)
            } else {
                print("Document successfully written!")
                var newItinerary = itinerary
                newItinerary.isDeleted = true
                NotificationCenter.default.post(name: .didItineraryDidUpdated, object: nil, userInfo: ["itinerary": newItinerary])
                completionHandler(true, nil)
                
            }
        }
    }
}

// MARK: - Count
extension Itinerary {
    
    static func updateCount(of type: CountField, itinerary: Itinerary, comment: Comment? = nil, collection: SavedCollection? = nil, isIncrement: Bool = true) {
        var shards = "shards"
        var ref = itinerary.ref
        switch type {
        case .like:
            if isIncrement {
                Globals.currentUser?.likedItineraries.append(itinerary.id)
            } else {
                Globals.currentUser?.likedItineraries.removeObject(itinerary.id)
            }
            shards = liked_shards
        case .likeComment:
            let id = itinerary.id + "_" + comment!.id
            if isIncrement {
                Globals.currentUser?.likedComments.append(id)
            } else {
                Globals.currentUser?.likedComments.removeObject(id)
            }
            shards = liked_shards
            ref = itinerary.ref.collection("comments").document(comment!.id)
        case .save:
            if isIncrement {
                Globals.currentUser?.savedItineraries.append([itinerary.id: collection!.id])
            } else {
                Globals.currentUser?.savedItineraries.removeObject([itinerary.id: collection!.id])
            }
            shards = saved_shards
        case .comment:
            Globals.currentUser?.commentedItineraries.append(itinerary.id)
            shards = comment_shards
        }
        
        FirebaseHelper.getSharedCount(ref: ref, shards: shards) { (count, error) in
            var newItinerary = itinerary
            var newComment = comment
            if error != nil {
                switch type {
                case .like:
                    newItinerary.likeCount += isIncrement ? 1 : -1
                    newItinerary.isLike = isIncrement
                case .comment:
                    newItinerary.commentCount += isIncrement ? 1 : -1
                    newItinerary.isCommented = isIncrement
                case .save:
                    newItinerary.savedCount += isIncrement ? 1 : -1
                    newItinerary.isSave = isIncrement
                case .likeComment:
                    newComment?.likeCount = isIncrement ? 1 : -1
                    NotificationCenter.default.post(name: .didCommentDidUpdated, object: nil, userInfo: ["comment": newComment!])
                    return
                }
                
                NotificationCenter.default.post(name: .didItineraryDidUpdated, object: nil, userInfo: ["itinerary": newItinerary])
            } else {
                Itinerary.increaseCount(ref, field: type, value: count) { (result, error) in
                    
                    Itinerary.refreshItinerary(newItinerary, type: type, count: count)
                    
                    switch type {
                    case .like:
                        newItinerary.likeCount = count
                        newItinerary.isLike = isIncrement
                    case .comment:
                        newItinerary.commentCount = count
                        newItinerary.isCommented = isIncrement
                    case .save:
                        newItinerary.savedCount = count
                        newItinerary.isSave = isIncrement
                    case .likeComment:
                        newComment?.likeCount = count
                        newComment?.isLike = isIncrement
                        NotificationCenter.default.post(name: .didCommentDidUpdated, object: nil, userInfo: ["comment": newComment!])
                        return
                    }
                    
                    NotificationCenter.default.post(name: .didItineraryDidUpdated, object: nil, userInfo: ["itinerary": newItinerary])
                }
            }
        }
    }
    
    static func increaseCount(_ ref: DocumentReference, field: CountField, value: Int, completionHandler:  RequestDidCompleteBlock?) {
        ref.updateData([field.fieldName: value]) { (error) in
            if let error = error {
                print("Transaction failed: \(error)")
                completionHandler?(false, error)
            } else {
                print("Transaction successfully committed!")
                completionHandler?(true, nil)
            }
        }
    }
    
    static func incrementLike(of itinerary: Itinerary, transaction: Transaction? = nil) {
        FirebaseHelper.updateCounter(ref: itinerary.ref, shards: liked_shards, value: 1, transaction: transaction)
    }
    
    static func decrementLike(of itinerary: Itinerary, transaction: Transaction? = nil) {
        FirebaseHelper.updateCounter(ref: itinerary.ref, shards: liked_shards, value: -1, transaction: transaction)
    }
    
    static func incrementComment(of itinerary: Itinerary, transaction: Transaction? = nil) {
        FirebaseHelper.updateCounter(ref: itinerary.ref, shards: comment_shards, value: 1, transaction: transaction)
    }
    
    static func decrementComment(of itinerary: Itinerary, transaction: Transaction? = nil) {
        FirebaseHelper.updateCounter(ref: itinerary.ref, shards: comment_shards, value: -1, transaction: transaction)
    }
    
    static func incrementSaved(of itinerary: Itinerary, transaction: Transaction? = nil) {
        FirebaseHelper.updateCounter(ref: itinerary.ref, shards: saved_shards, value: 1, transaction: transaction)
    }
    
    static func decrementSaved(of itinerary: Itinerary, transaction: Transaction? = nil) {
        FirebaseHelper.updateCounter(ref: itinerary.ref, shards: saved_shards, value: -1, transaction: transaction)
    }
    
    static func incrementCommentLike(of comment: Comment, itinerary: Itinerary, transaction: Transaction? = nil) {
        let ref = itinerary.ref
            .collection("comments")
            .document(comment.id)
        FirebaseHelper.updateCounter(ref: ref, shards: liked_shards, value: 1, transaction: transaction)
    }
    
    static func decrementCommentLike(of comment: Comment, itinerary: Itinerary, transaction: Transaction? = nil) {
        let ref = itinerary.ref
            .collection("comments")
            .document(comment.id)
        FirebaseHelper.updateCounter(ref: ref, shards: liked_shards, value: -1, transaction: transaction)
    }
}
