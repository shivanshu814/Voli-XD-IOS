//
//  User+Factory.swift
//  PineApple
//
//  Created by Tao Man Kit on 23/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import Alamofire
import Firebase

let follower_shards = "shards"
let sc_followingUserIds = "followingUserIds"
let sc_commentedItineraries = "commentedItineraries"
let sc_likedItineraries = "likedItineraries"
let sc_savedItineraries = "savedItineraries"
let sc_likedComments = "likedComments"
let sc_followingUsers = "followingUsers"

extension User {
    var collection: CollectionReference {
        return Firestore.firestore().collection("users")
    }
    
    var ref: DocumentReference {
        return Firestore.firestore().collection("users").document(id)
    }
}

// MARK: - Create
extension User {
    
    static func create(_ user: User, completionHandler: RequestDidCompleteBlock?) {
        let ref = user.ref
        Firestore.firestore().runTransaction({ (transaction, errorPointer) -> Any? in
            // user data
            transaction.setData([
                "id": user.id,
                "displayName": user.displayName,
                "firstName": user.firstName,
                "lastName": user.lastName,
                "profileImageUrl": user.profileImageUrl,
                "thumbnail": user.thumbnail,
                "location": user.location,
                "city": user.city,
                "state": user.city == "hong kong" ? "" : user.state,
                "country": user.country,
                "email": user.email,
                "countryCode": user.countryCode,
                "phone": user.phone,
                "tags": user.tags,
                "itineraryCount": 0,
                "followerCount": 0,
                "followingCount": 0,
                "about": user.about,
                "fbId": user.fbId,
                "isDirty": false,
                "setting": user.setting.map{[$0.title: $0.isEnabled]},
                "keywords": user.keywords,
                "loginType": user.loginType,
                "lastUpdated": Date().timeIntervalSince1970,
                "numShards": globalNumShards
            ], forDocument: ref)
            
            // follower count
            for i in 0...globalNumShards {
                let _ref = ref.collection(follower_shards).document(String(i))
                transaction.setData(["count": 0], forDocument: _ref)
            }
            
            let followingUserIdRef = ref.collection(sc_followingUserIds).document("list")
            transaction.setData(["ids": [String]()], forDocument: followingUserIdRef)
            
            let commentedItineraryRef = ref.collection(sc_commentedItineraries).document("list")
            transaction.setData(["ids": [String]()], forDocument: commentedItineraryRef)
            
            let likedItinerariesRef = ref.collection(sc_likedItineraries).document("list")
            transaction.setData(["ids": [String]()], forDocument: likedItinerariesRef)
            
            let saveItinerariesRef = ref.collection(sc_savedItineraries).document("list")
            transaction.setData(["ids": [String]()], forDocument: saveItinerariesRef)
            
            let likedcommentsRef = ref.collection(sc_likedComments).document("list")
            transaction.setData(["ids": [String]()], forDocument: likedcommentsRef)
            
            return nil
        }) { (object, error) in
            if let error = error {
                print("Transaction failed: \(error)")
                completionHandler?(false, error)
            } else {
                print("Transaction successfully committed!")
                completionHandler?(true, nil)
                // create keywords
                (user.keywords.map{Keyword(name: $0)}).forEach {
                    Keyword.create($0)
                }
            }
        }
    }
    
    static func addLikedItinerary(_ itinerary: Itinerary, completionHandler: @escaping RequestDidCompleteBlock) {
        if let currentUser = Globals.currentUser {
            
            Firestore.firestore().runTransaction({ (transaction, errorPointer) -> Any? in
                
                let ref = Firestore.firestore().collection("users")
                    .document(currentUser.id)
                    .collection(sc_likedItineraries)
                    .document("list")
                
                transaction.updateData(["ids": FieldValue.arrayUnion([itinerary.id])], forDocument: ref)
                
                Itinerary.incrementLike(of: itinerary, transaction: transaction)
            
                return nil
            }) { (object, error) in
                if let error = error {
                    print("Transaction failed: \(error)")
                    completionHandler(false, error)
                } else {
                    print("Transaction successfully committed!")
                    completionHandler(true, nil)
                    Itinerary.updateCount(of: .like, itinerary: itinerary)
                    
                    if itinerary.user.isCommentSaveLikeEnabled && !itinerary.isOwner {
                        PushNotificationManager.shared.sendPushNotification(to: itinerary.user.token, title: "", body: "\(Globals.currentUser!.displayName) liked on your itinerary \"\(itinerary.title)\"")
                    }
                }
            }
        }
    }
    
    static func removeLikedItinerary(_ itinerary: Itinerary, completionHandler: @escaping CountRequestDidCompleteBlock) {
        if let currentUser = Globals.currentUser {
            
            Firestore.firestore().runTransaction({ (transaction, errorPointer) -> Any? in
                
                let ref = Firestore.firestore().collection("users")
                    .document(currentUser.id)
                    .collection(sc_likedItineraries)
                    .document("list")
                
                transaction.updateData(["ids": FieldValue.arrayRemove([itinerary.id])], forDocument: ref)
                
                Itinerary.decrementLike(of: itinerary, transaction: transaction)
            
                return nil
            }) { (object, error) in
                if let error = error {
                    print("Transaction failed: \(error)")
                    completionHandler(0, error)
                } else {
                    print("Transaction successfully committed!")
                    Itinerary.updateCount(of: .like, itinerary: itinerary, isIncrement: false)
                }
            }
        }
    }
    
    static func addCommentedItinerary(_ itinerary: Itinerary, transaction: Transaction) {
        if let currentUser = Globals.currentUser {
            
            let ref = Firestore.firestore().collection("users")
                    .document(currentUser.id)
                    .collection(sc_commentedItineraries)
                    .document("list")
                
            transaction.updateData(["ids": FieldValue.arrayUnion([itinerary.id])], forDocument: ref)
            
            Itinerary.incrementComment(of: itinerary, transaction: transaction)
        }
        
    }
    
    static func addLikedComment(_ comment: Comment, itinerary: Itinerary, completionHandler: @escaping RequestDidCompleteBlock) {
        if let currentUser = Globals.currentUser {
            Firestore.firestore().runTransaction({ (transaction, errorPointer) -> Any? in
                let id = "\(itinerary.id)_\(comment.id)"
                let ref = Firestore.firestore().collection("users")
                    .document(currentUser.id)
                    .collection(sc_likedComments)
                    .document("list")
                
                transaction.updateData(["ids": FieldValue.arrayUnion([id])], forDocument: ref)
                
                Itinerary.incrementCommentLike(of: comment, itinerary: itinerary, transaction: transaction)
            
                return nil
            }) { (object, error) in
                if let error = error {
                    print("Transaction failed: \(error)")
                    completionHandler(false, error)
                } else {
                    print("Transaction successfully committed!")
                    completionHandler(true, error)
                    Itinerary.updateCount(of: .likeComment, itinerary: itinerary, comment: comment)
                }
            }
            return
        }
        completionHandler(false, nil)
    }
    
    static func removeLikedComment(_ comment: Comment, itinerary: Itinerary, completionHandler: @escaping RequestDidCompleteBlock) {
        if let currentUser = Globals.currentUser {
            
            Firestore.firestore().runTransaction({ (transaction, errorPointer) -> Any? in
                let id = "\(itinerary.id)_\(comment.id)"
                let ref = Firestore.firestore().collection("users")
                    .document(currentUser.id)
                    .collection(sc_likedComments)
                    .document("list")
                
                transaction.updateData(["ids": FieldValue.arrayRemove([id])], forDocument: ref)
                
                Itinerary.decrementCommentLike(of: comment, itinerary: itinerary, transaction: transaction)
            
                return nil
            }) { (object, error) in
                if let error = error {
                    print("Transaction failed: \(error)")
                    completionHandler(false, error)
                } else {
                    print("Transaction successfully committed!")
                    completionHandler(true, nil)
                    Itinerary.updateCount(of: .likeComment, itinerary: itinerary, comment: comment, isIncrement: false)
                }
            }
            return
        }
        completionHandler(false, nil)
    }

    static func addSavedItinerary(_ itinerary: Itinerary, collection: SavedCollection, transaction: Transaction) {
        
        if let currentUser = Globals.currentUser {
            
            let id = itinerary.id
            let ref = Firestore.firestore().collection("users")
                .document(currentUser.id)
                .collection(sc_savedItineraries)
                .document("list")
            
            transaction.updateData(["ids": FieldValue.arrayUnion(["\(id)_\(collection.id)"])], forDocument: ref)
            
            Itinerary.incrementSaved(of: itinerary, transaction: transaction)
            
            if itinerary.user.isCommentSaveLikeEnabled && !itinerary.isOwner {
                PushNotificationManager.shared.sendPushNotification(to: itinerary.user.token, title: "", body: "\(Globals.currentUser!.displayName) saved on your itinerary \"\(itinerary.title)\"")
            }
        }
    }
    
    static func removeSavedItinerary(_ itinerary: Itinerary, collection: SavedCollection, transaction: Transaction) {
        if let currentUser = Globals.currentUser {
            
            let id = itinerary.id
            let ref = Firestore.firestore().collection("users")
                .document(currentUser.id)
                .collection(sc_savedItineraries)
                .document("list")
            
            transaction.updateData(["ids": FieldValue.arrayRemove(["\(id)_\(collection.id)"])], forDocument: ref)
            
            Itinerary.decrementSaved(of: itinerary, transaction: transaction)
        }
    }
    
    static func reportAbuse(_ user: User, completionHandler: @escaping RequestDidCompleteBlock) {
        Firestore.firestore().collection("abuseUsers")
            .document(user.id)
            .setData(["id": user.id]
                      ) { err in
                        if let err = err {
                            print("Error writing document: \(err)")
                            completionHandler(false, err)
                        } else {
                            print("Document successfully written!")
                            completionHandler(true, nil)
                        }
        }
        completionHandler(false, nil)
    }
}

// MARK: - Query
extension User {
    
    static func currentUser(_ completionHandler: @escaping RequestDidCompleteBlock) {
        if let uid = Auth.auth().currentUser?.uid {
//            User.findById("b4MtTWa4PoPAtcnPN4xwP09vmbZ2") { (user, error) in
            User.findById(uid) { (user, error) in
                if let user = user {
                    var count = 0
                    Globals.currentUser = user
                    UserDefaults.standard.set("true", forKey: "isLogined")
                    func checkIfFinished() {
                        synced(self) {
                            count += 1
                            if count == 5 {
                                DispatchQueue.main.async {
                                    NotificationCenter.default.post(name: .didLogin, object: nil)
                                    completionHandler(true, nil)
                                }
                            }
                        }
                    }
                                        
                    User.getFollowingUserId(nil) { (_, _) in checkIfFinished() }
                    User.getSavedItineraries(user) { (_, _) in checkIfFinished() }
                    User.getCommentedItineraries(user) { (_, _) in checkIfFinished() }
                    User.getLikedItineraries(user) { (_, _) in checkIfFinished() }
                    User.getLikedComments(user) { (_, _) in checkIfFinished() }
                                        
                } else {
                    completionHandler(false, error)
                }
            }
        } else {
            completionHandler(false, nil)
        }
    }
    
    static func checkIfFollowing(_ id: String, completionHandler: @escaping RequestDidCompleteBlock) {
        if let currentUser = Globals.currentUser {
            Firestore.firestore().collection("users")
                .document(currentUser.id)
                .collection(sc_followingUsers).whereField("id", isEqualTo: id).getDocuments { (querySnapshot, error) in
                    completionHandler(!(querySnapshot?.documents.isEmpty ?? true), error)
            }
        } 
    }
    
    static func getFollowingUser(_ user: User, paging: Paging, completionHandler: @escaping (User, Error?) -> Void) {
        var query = Firestore.firestore().collection("users")
            .document(user.id)
            .collection(sc_followingUsers)
            .order(by: "displayName")
            
        
        if let lastDocumentSnapshot = paging.lastDocumentSnapshot {
            query = query.start(afterDocument: lastDocumentSnapshot)
        }
            
        query.limit(to: paging.itemPerPage)
            .getDocuments() { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                completionHandler(user, error)
            } else {
                var users = [User]()
                if querySnapshot!.documents.isEmpty {
                    paging.isMore.accept(false)
                    completionHandler(user, nil)
                } else {
                    querySnapshot!.documents.forEach {
                        users.append(User(data: $0.data()))
                    }
                    var newUser = user
                    if paging.start > 0 {
                        newUser.followingUsers.append(contentsOf: users)
                    } else {
                        newUser.followingUsers = users
                    }
                    
                    paging.lastDocumentSnapshot = querySnapshot!.documents.last
                    paging.isMore.accept(querySnapshot!.documents.count >= paging.itemPerPage)
                    paging.start += 1
                    completionHandler(newUser, nil)
                }
            }
        }
    }
    
    static func findFollowingUser(_ user: User, searchName: String, paging: Paging, completionHandler: @escaping ([User], Error?) -> Void) {
        var query = Firestore.firestore().collection("users")
            .document(user.id)
            .collection(sc_followingUsers)
            .whereField("searchName", isGreaterThanOrEqualTo: searchName)
            .order(by: "searchName")
                    
        
        if let lastDocumentSnapshot = paging.lastDocumentSnapshot {
            query = query.start(afterDocument: lastDocumentSnapshot)
        }
            
        query.limit(to: paging.itemPerPage)
            .getDocuments() { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                completionHandler([], error)
            } else {
                var users = [User]()
                if querySnapshot!.documents.isEmpty {
                    paging.isMore.accept(false)
                    completionHandler([], nil)
                } else {
                    querySnapshot!.documents.forEach {
                        users.append(User(data: $0.data()))
                    }
                    paging.lastDocumentSnapshot = querySnapshot!.documents.last
                    paging.isMore.accept(users.count >= paging.itemPerPage)
                    completionHandler(users, nil)
                }
            }
        }
    }
    
    static func getFollowingUserId(_ user: User?, completionHandler: @escaping ([String], Error?) -> Void) {
        if let _user = user ?? Globals.currentUser {
            Firestore.firestore().collection("users")
                .document(_user.id)
                .collection(sc_followingUserIds)
                .document("list")
                .getDocument() { (querySnapshot, error) in
                    if let error = error {
                        print("Error getting documents: \(error)")
                        completionHandler([], error)
                    } else {
                        let item = querySnapshot?.data()
                        let users = item?["ids"] as? [String] ?? []
                        if user == nil {
                            Globals.currentUser?.followingUserIds = users
                        }
                        completionHandler(users, nil)
                        
                    }
            }
        } else {
            completionHandler([], "no user")
        }
        
    }
    
    static func getCommentedItineraries(_ user: User, completionHandler: RequestDidCompleteBlock? = nil) {
        Firestore.firestore().collection("users")
            .document(user.id)
            .collection(sc_commentedItineraries)
            .document("list")
            .getDocument() { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                    completionHandler?(false, error)
                } else {
                    let item = querySnapshot?.data()
                    let itineraries = item?["ids"] as? [String] ?? []
                    Globals.currentUser?.commentedItineraries = itineraries
                    completionHandler?(true, nil)
                }
        }
    }
    
    static func getLikedItineraries(_ user: User, completionHandler: RequestDidCompleteBlock? = nil) {
        Firestore.firestore().collection("users")
            .document(user.id)
            .collection(sc_likedItineraries)
            .document("list")
            .getDocument() { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                completionHandler?(false, error)
            } else {
                let item = querySnapshot?.data()
                let itineraries = item?["ids"] as? [String] ?? []
                Globals.currentUser?.likedItineraries = itineraries
                completionHandler?(true, nil)
            }
        }
    }
    
    static func getSavedItineraries(_ user: User, completionHandler: RequestDidCompleteBlock? = nil) {
        Firestore.firestore().collection("users")
            .document(user.id)
            .collection(sc_savedItineraries)
            .document("list")
            .getDocument() { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                completionHandler?(false, error)
            } else {
                let item = querySnapshot?.data()
                let itineraries: [[String: String]] = (item?["ids"] as? [String] ?? []).map{[$0.components(separatedBy: "_")[0]: $0.components(separatedBy: "_")[1]]}
                Globals.currentUser?.savedItineraries = itineraries
                completionHandler?(true, nil)
            }
        }
    }
    
    static func getLikedComments(_ user: User, completionHandler: RequestDidCompleteBlock? = nil) {
        Firestore.firestore().collection("users")
            .document(user.id)
            .collection(sc_likedComments)
            .document("list")
            .getDocument() { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                completionHandler?(false, error)
            } else {
                let item = querySnapshot?.data()
                let comments = item?["ids"] as? [String] ?? []
                Globals.currentUser?.likedComments = comments
                completionHandler?(true, nil)
            }
        }
    }
    
    static func findByEmail(_ email: String, completionHandler: @escaping (User?, Error?) -> Void) {
        Firestore.firestore().collection("users")
            .whereField("email", isEqualTo: email)
            .limit(to: 1)
            .getDocuments() { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                    completionHandler(nil, error)
                } else {
                    if querySnapshot!.documents.isEmpty {
                        completionHandler(nil, nil)
                    } else {
                        let user = User(data: querySnapshot!.documents.first!.data())
                        completionHandler(user, nil)
                    }
                }
        }
    }
    
    static func findById(_ id: String, completionHandler: @escaping (User?, Error?) -> Void) {
        Firestore.firestore().collection("users").document(id).getDocument { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                    completionHandler(nil, error)
                } else {
                    if let data = querySnapshot!.data() {
                        let user = User(data: data)
                        completionHandler(user, nil)
                    } else {
                        completionHandler(nil, nil)
                    }
                }
        }
    }
    
    static func findRecommendUserByCity(_ city: String, state: String, country: String, paging: Paging? = nil, completionHandler: @escaping ([User], Error?) -> Void) {
        
        var query = Firestore.firestore().collection("users")
            .whereField("city", isEqualTo: city)
            .whereField("state", isEqualTo: state)
            .whereField("country", isEqualTo: country)
            .order(by: "followerCount", descending: true)
        
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
                        let users = querySnapshot!.documents.map{User(data: $0.data())}
                        if let paging = paging {
                            paging.lastDocumentSnapshot = querySnapshot!.documents.last
                            paging.isMore.accept(users.count >= paging.itemPerPage)
                        }
                        completionHandler(users, nil)
                    }
                }
        }
    }
    
    static func findPopularUsers(_ paging: Paging? = nil, completionHandler: @escaping ([User], Error?) -> Void) {
        
        var query = Firestore.firestore().collection("users")            
            .order(by: "followerCount", descending: true)
        
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
                        let users = querySnapshot!.documents.map{User(data: $0.data())}
                        if let paging = paging {
                            paging.lastDocumentSnapshot = querySnapshot!.documents.last
                            paging.isMore.accept(users.count >= paging.itemPerPage)
                        }
                        completionHandler(users, nil)
                    }
                }
        }
    }
    
    static func findByKeyword(_ keyword: Keyword, paging: Paging? = nil, completionHandler: @escaping ([User], Error?) -> Void) {
            
        var query = Firestore.firestore().collection("users")
            .whereField("keywords", arrayContains: keyword.name)
            .order(by: "followerCount", descending: true)
        
        if let lastDocumentSnapshot = paging?.lastDocumentSnapshot {
            query = query.start(afterDocument: lastDocumentSnapshot)
        }
            
        query.limit(to: paging?.itemPerPage ?? 10)
            .getDocuments() { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                completionHandler([], error)
            } else {
                if querySnapshot!.documents.isEmpty {
                    paging?.isMore.accept(false)
                    completionHandler([], nil)
                } else {
                    let users = querySnapshot!.documents.map{User(data: $0.data())}
                    
                    if let paging = paging {
                        paging.lastDocumentSnapshot = querySnapshot!.documents.last
                        paging.isMore.accept(users.count >= paging.itemPerPage)
                    }
                    completionHandler(users, nil)
                }
            }
        }
    }
}

// MARK: - Update
extension User {
    
    static func debug() {
//        Firestore.firestore().collection("users")
//            .limit(to: 200).getDocuments { (querySnapshot, error) in
//                let users = querySnapshot!.documents.map{User(data: $0.data())}
//
//                users.forEach {
//                    $0.ref.updateData(["searchName": $0.displayName.lowercased()])
//                }
//        }
        
        Firestore.firestore().collection("users")
            .limit(to: 200).getDocuments { (querySnapshot, error) in
                let users = querySnapshot!.documents.map{User(data: $0.data())}
                users.forEach {
                    let id = $0.id
                    Firestore.firestore().collection("users").document($0.id).collection("followingUsers").limit(to: 200).getDocuments { (querySnapshot, error) in
                        for doc in querySnapshot!.documents {

                            let user = User(data: doc.data())
                            Firestore.firestore()
                                .collection("users")
                                .document(id)
                                .collection("followingUsers")
                                .document(doc.documentID)
                                .updateData(["searchName": user.displayName.lowercased(), "fId": id])
                        }

                    }
                }
        }
        
//        Firestore.firestore().collectionGroup("followingUsers").limit(to: 200)
//            .getDocuments { (querySnapshot, error) in
//                querySnapshot!.documents.forEach {
//                    let user = User(data: $0.data())
//                    Firestore.firestore().collection("users")
//                        .document(user.id)
//                        .collection("followingUsers")
//                        .document(user.id)
//                        .updateData(["searchName": user.displayName.lowercased(), "fId": user.id])
//                }
////            let users = querySnapshot!.documents.map{User(data: $0.data())}
////            users.forEach {
////                Firestore.firestore().collection("users").document(id).collection()
////                $0.ref.updateData(["searchName": $0.displayName.lowercased()])
////            }
//        }

    }
    
    static func updateProfileImage(_ user: User, completionHandler: @escaping RequestDidCompleteBlock) {
        if let currentUser = Globals.currentUser {
            Firestore.firestore()
                .collection("users")
                .document(currentUser.id)
                .updateData([
                             "profileImageUrl": user.profileImageUrl,
                             "thumbnail": user.thumbnail,
                             "lastUpdated": Date().timeIntervalSince1970,
                             "isDirty": true
                             ]
                ) { err in
                    if let err = err {
                        print("Error writing document: \(err)")
                        completionHandler(false, err)
                    } else {
                        print("Document successfully written!")
                        Globals.currentUser = user
                        completionHandler(true, nil)
                        
                        refreshUser(user)
                                                
                    }
            }
            
            
        } else {
            completionHandler(false, nil)
        }
    }
    
    static func updateTags(_ tags: [Tag], deletedTags: [Tag] = [], user: User, completionHandler: @escaping RequestDidCompleteBlock) {
        let ref = user.ref
        Firestore.firestore().runTransaction({ (transaction, errorPointer) -> Any? in
            // tags
//            Tag.update(tags, deletedTags: deletedTags, transaction: transaction)
                        
            // data
            transaction.updateData([
                "keywords": user.keywords,
                "tags": user.tags,
                "lastUpdated": Date().timeIntervalSince1970
            ], forDocument: ref)
            
            return nil
        }) { (object, error) in
            if let error = error {
                print("Transaction failed: \(error)")
                completionHandler(false, error)
            } else {
                print("Transaction successfully committed!")
                completionHandler(true, nil)
                // create keywords
                (user.keywords.map{Keyword(name: $0)}).forEach {
                    Keyword.create($0)
                }
            }
        }
    }
    
    static func updateAbout(_ user: User, completionHandler: @escaping RequestDidCompleteBlock) {
        if let currentUser = Globals.currentUser {
            Firestore.firestore()
                .collection("users")
                .document(currentUser.id)
                .updateData([
                             "about": user.about,
                             "lastUpdated": Date().timeIntervalSince1970,
                             "isDirty": user.isDirty
                             ]
                ) { err in
                    if let err = err {
                        print("Error writing document: \(err)")
                        completionHandler(false, err)
                    } else {
                        print("Document successfully written!")
                        Globals.currentUser = user
                        completionHandler(true, nil)                        
                    }
            }
        } else {
            completionHandler(false, nil)
        }
    }
    
    static func updateToken(_ user: User, completionHandler: RequestDidCompleteBlock?) {
        Firestore.firestore()
            .collection("users")
            .document(user.id)
            .updateData(["token": user.token,
                         "lastUpdated": Date().timeIntervalSince1970]
            ) { err in
                if let err = err {
                    print("Error writing document: \(err)")
                    completionHandler?(false, err)
                } else {
                    print("Document successfully written!")
                    completionHandler?(true, nil)
                }
        }
    }
    
    static func update(_ user: User, completionHandler: @escaping RequestDidCompleteBlock) {
        if let currentUser = Globals.currentUser {
            Firestore.firestore()
                .collection("users")
                .document(currentUser.id)
                .updateData([
                             "displayName": user.displayName,
                             "firstName": user.firstName,
                             "lastName": user.lastName,
                             "profileImageUrl": user.profileImageUrl,
                             "thumbnail": user.thumbnail,
                             "city": user.city,
                             "email": user.email,
                             "countryCode": user.countryCode,
                             "phone": user.phone,
                             "about": user.about,
                             "setting": user.setting.map{[$0.title: $0.isEnabled]},
                             "keywords": user.keywords,
                             "lastUpdated": Date().timeIntervalSince1970,
                             "isDirty": user.isDirty
                             ]
                ) { err in
                    if let err = err {
                        print("Error writing document: \(err)")
                        completionHandler(false, err)
                    } else {
                        print("Document successfully written!")
                        Globals.currentUser = user
                        completionHandler(true, nil)
                        // create keywords
                        (user.keywords.map{Keyword(name: $0)}).forEach {
                            Keyword.create($0)
                        }
                        
                        if user.isDirty {
                            refreshUser(user)
                        }
                    }
            }
        } else {
            completionHandler(false, nil)
        }
    }
    
    static func updateSetting(_ user: User, completionHandler: @escaping RequestDidCompleteBlock) {
        if let currentUser = Globals.currentUser {
            Firestore.firestore()
                .collection("users")
                .document(currentUser.id)
                .updateData([
                             "setting": user.setting.map{[$0.title: $0.isEnabled]}
                             ]
                ) { err in
                    if let err = err {
                        print("Error writing document: \(err)")
                        completionHandler(false, err)
                    } else {
                        print("Document successfully written!")
                        completionHandler(true, nil)
                    }
            }
        } else {
            completionHandler(false, nil)
        }
    }
    
    static func followUser(_ user: User, completionHandler: @escaping RequestDidCompleteBlock) {
        if let currentUser = Globals.currentUser {
            let ref = Firestore.firestore().collection("users")
                .document(currentUser.id)
                .collection(sc_followingUsers)
                .document(user.id)
            
            Firestore.firestore().runTransaction({ (transaction, errorPointer) -> Any? in
                // data
                transaction.setData(["id": user.id,
                                     "displayName": user.displayName,
                                     "profileImageUrl": user.profileImageUrl,
                                     "location": user.location,
                                     "thumbnail": user.thumbnail,
                                     "email": user.email,
                                     "phone": user.phone,
                                     "fbId": user.fbId,
                                     "fId": currentUser.id,
                                     "searchName": user.displayName.lowercased()], forDocument: ref)
                
                incrementFollower(of: user, transaction: transaction)
                                
                let ref = Firestore.firestore().collection("users")
                    .document(currentUser.id)
                    .collection(sc_followingUserIds)
                    .document("list")
                transaction.updateData(["ids": FieldValue.arrayUnion([user.id])], forDocument: ref)
                
                let userRef = Firestore.firestore().collection("users").document(currentUser.id)
                transaction.updateData(["followingCount": FieldValue.increment(Int64(1))], forDocument: userRef)
                
                return nil
            }) { (object, error) in
                if let error = error {
                    print("Transaction failed: \(error)")
                    completionHandler(false, error)
                } else {
                    print("Transaction successfully committed!")
                    completionHandler(true, nil)
                    Globals.currentUser?.followingUserIds.append(user.id)
                    User.updateFollowerCount(user)
                    
                    PushNotificationManager.shared.addToGroupNotification(user.id)
                    
                    
                    if user.isNewfollowerEnabled {
                        PushNotificationManager.shared.sendPushNotification(to: user.token, title: "", body: "\(Globals.currentUser!.displayName) has started following you.")
                    }
                }
            }
                        
        } else {
            completionHandler(false, nil)
        }
        
    }
    
    static func unfollowUser(_ user: User, completionHandler: @escaping RequestDidCompleteBlock) {
        if let currentUser = Globals.currentUser {
            let ref = Firestore.firestore().collection("users")
                .document(currentUser.id)
                .collection(sc_followingUsers)
                .document(user.id)
            
            Firestore.firestore().runTransaction({ (transaction, errorPointer) -> Any? in
                // data
                transaction.deleteDocument(ref)

                decrementFollower(of: user, transaction: transaction)
                
                let ref = Firestore.firestore().collection("users")
                    .document(currentUser.id)
                    .collection(sc_followingUserIds)
                    .document("list")
                transaction.updateData(["ids": FieldValue.arrayRemove([user.id])], forDocument: ref)
                
                let userRef = Firestore.firestore().collection("users").document(currentUser.id)
                transaction.updateData(["followingCount": FieldValue.increment(Int64(-1))], forDocument: userRef)
                
                return nil
            }) { (object, error) in
                if let error = error {
                    print("Transaction failed: \(error)")
                    completionHandler(false, error)
                } else {
                    print("Transaction successfully committed!")
                    completionHandler(true, nil)
                    Globals.currentUser?.followingUserIds.removeObject(user.id)
                    User.updateFollowerCount(user, isIncrement: false)
                    
                    PushNotificationManager.shared.removeFromGroupNotification(user.id)
                }
            }
                        
        } else {
            completionHandler(false, nil)
        }
        
    }
    
    static func refreshUser(_ user: User) {
        Alamofire.request(URL(string: URL_UPDATE_USER)!, method: .post, parameters: user.short_dict, encoding: JSONEncoding.default).response { (response) in
            print(response)
        }
        
        Alamofire.request(URL(string: URL_UPDATE_FOLLOWING)!, method: .post, parameters: user.short_dict, encoding: JSONEncoding.default).response { (response) in
            print(response)
        }
        
        Alamofire.request(URL(string: URL_UPDATE_CHANNELS)!, method: .post, parameters: user.short_dict, encoding: JSONEncoding.default).response { (response) in
            print(response)
        }
    }
    
}

// MARK: - Count
extension User {
    
    static func updateFollowerCount(_ user: User, isIncrement: Bool = true) {
        if isIncrement {
            Globals.currentUser?.followingUsers.append(user)
        } else {
            Globals.currentUser?.followingUsers.removeObject(user)
        }
        var newUser = user
        FirebaseHelper.getSharedCount(ref: user.ref, shards: follower_shards) { (count, error) in
            if error != nil {
                newUser.followerCount = isIncrement ? 1 : -1
                NotificationCenter.default.post(name: .didUserDidUpdated, object: nil, userInfo: ["user": newUser])
            } else {
                User.increaseFollowerCount(user, value: count) { (result, error) in
                    newUser.followerCount = count
                    NotificationCenter.default.post(name: .didUserDidUpdated, object: nil, userInfo: ["user": newUser])
                }
            }
        }
    }
    
    static func increaseFollowerCount(_ user: User, value: Int, completionHandler:  RequestDidCompleteBlock?) {
        user.ref.updateData(["followerCount": value]) { (error) in
            if let error = error {
                print("Transaction failed: \(error)")
                completionHandler?(false, error)
            } else {
                print("Transaction successfully committed!")
                completionHandler?(true, nil)
            }
        }
    }
        
    static func incrementFollower(of user: User, transaction: Transaction? = nil) {
        FirebaseHelper.updateCounter(ref: user.ref, value: 1, transaction: transaction)
    }
    
    static func decrementFollower(of user: User, transaction: Transaction? = nil) {
        FirebaseHelper.updateCounter(ref: user.ref, value: -1, transaction: transaction)
    }
}
