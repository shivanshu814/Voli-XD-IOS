//
//  ATCRemoteData.swift
//  ChatApp
//
//  Created by Dan Burkhardt on 3/20/19.
//  Copyright © 2019 Instamobile. All rights reserved.
//

import Foundation
import Firebase

class ATCRemoteData{
    
    let db = Firestore.firestore()
    
    func searchChannels(_ keyword: String, userIndex: Int = 0, completionHandler: @escaping ([ATCChatChannel], Error?) -> Void) {
        db.collection("channels")
            .whereField("userIds", arrayContains: Globals.currentUser!.id)
            .whereField(userIndex == 1 ? "user1Name" : "user2Name", isGreaterThanOrEqualTo: keyword)
            .order(by: userIndex == 1 ? "user1Name" : "user2Name", descending: true)
            .limit(to: searchItemPerPage)
            .getDocuments() { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                    completionHandler([], error)
                } else {
                    if querySnapshot!.documents.isEmpty {
                        completionHandler([], nil)
                    } else {
                        let channels = querySnapshot!.documents.map{ATCChatChannel(document: $0)}                                                
                        completionHandler(channels, nil)
                    }
                }
        }
    }
        
    func getMyChannels(_ paging: Paging? = nil, completionHandler: @escaping ([ATCChatChannel], Error?) -> Void) {
        var query = db.collection("channels")
            .whereField("userIds", arrayContains: Globals.currentUser!.id)
            .order(by: "lastUpdated", descending: true)
        
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
                        let channels = querySnapshot!.documents.map{ATCChatChannel(document: $0)}
                        
                        if let paging = paging {
                            paging.lastDocumentSnapshot = querySnapshot!.documents.last
                            paging.isMore.accept(channels.count >= paging.itemPerPage)
                        }
                        completionHandler(channels, nil)
                    }
                }
        }
    }
    
    func getChannelById(_ id: String, completionHandler: @escaping (ATCChatChannel?, Error?) -> Void){
        db.collection("channels")
            .document(id)
            .getDocument { (document, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                    completionHandler(nil, error)
                } else {
                    let channel = ATCChatChannel(data: document!.data()!)
                    completionHandler(channel, nil)
                }
        }
    }
    
    func getChannelByUser(_ user: User, isSender: Bool = false, completionHandler: @escaping (ATCChatChannel?, Error?) -> Void){
        if let currentUser = Globals.currentUser {
            db.collection("channels")
                .whereField("user1", isEqualTo: isSender ? currentUser.id : user.id)
                .whereField("user2", isEqualTo: isSender ? user.id : currentUser.id)
                .limit(to: 1)
                    .getDocuments() { (querySnapshot, error) in
                        if let error = error {
                            print("Error getting documents: \(error)")
                            completionHandler(nil, error)
                        } else {
                            if querySnapshot!.documents.isEmpty {
                                if !isSender {
                                    ATCRemoteData().getChannelByUser(user, isSender: true, completionHandler: completionHandler)
                                } else {
                                    completionHandler(nil, nil)
                                }
                            } else {
                                let channel = querySnapshot!.documents.map{ATCChatChannel(document: $0)}.first
                                completionHandler(channel, nil)
                            }
                        }
                }
        } else {
            completionHandler(nil, "Empty user")
        }
        
    }
            
    func getMessages(_ channel: ATCChatChannel, paging: Paging, completionHandler: @escaping ([ATChatMessage]?, Error?) -> Void) {
        var query = db.collection("channels")
            .document(channel.id)
            .collection("thread")
            .order(by: "created", descending: true)
        
        if let lastDocumentSnapshot = paging.lastDocumentSnapshot {
            query = query.start(afterDocument: lastDocumentSnapshot)
        }
        
        query.limit(to: paging.itemPerPage)
            .getDocuments() { (querySnapshot, error) in
                if querySnapshot!.documents.isEmpty {
                    paging.isMore.accept(false)
                    completionHandler([], nil)
                } else {
                    
                    let messages = querySnapshot!.documents.map{ATChatMessage(document: $0)!}
                    
                    paging.lastDocumentSnapshot = querySnapshot!.documents.last
                    paging.isMore.accept(messages.count >= paging.itemPerPage)
                    completionHandler(messages, nil)
                }
        }
    }
    
    func checkPath(path: [String], dbRepresentation: [String:Any], completionhandler: ((String?, Error?) -> Void)? = nil){
        var dbRepresentation = dbRepresentation
        print("checking for channelID: \(path[1])")
        var channelIDRef: DocumentReference
        if path[1].isEmpty {
            channelIDRef = self.db.collection(path[0]).document()
            dbRepresentation["id"] = channelIDRef.documentID
        } else {
            channelIDRef = self.db.collection(path[0]).document(path[1])
        }
        
        channelIDRef.getDocument { (document, error) in
            if let document = document, document.exists {
                
                print("chat thread exists for \(dbRepresentation)")
                // Uncomment to see the data description
                //let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                completionhandler?(channelIDRef.documentID, nil)
            } else {
                print("adding indexable values to the database representation")
                                                
                channelIDRef.setData(dbRepresentation) { err in
                    if let err = err {
                        print("Firestore error returned when creating chat thread!: \(err)")
                        completionhandler?(nil, error)
                    } else {
                        print("chat thread successfully created")
                        completionhandler?(channelIDRef.documentID, nil)
                    }
                }
            }
        }
    }
    
    func updateChannel(path: [String], message: String, date: Date, userIndex: Int, completionhandler:  RequestDidCompleteBlock? = nil) {
        let channelIDRef = self.db.collection(path[0]).document(path[1])
        channelIDRef.updateData([
            "lastMessage": message,
            "lastUpdated": date.timeIntervalSince1970,
            "\(userIndex == 1 ? "unreadCount2" : "unreadCount1")": FieldValue.increment(Int64(1))
        ])
    }
    
    func readChannel(path: [String], userIndex: Int, completionhandler: RequestDidCompleteBlock? = nil) {
        let channelIDRef = self.db.collection(path[0]).document(path[1])
        channelIDRef.updateData([
            "\(userIndex == 1 ? "unreadCount1" : "unreadCount2")": 0
        ])
    }
   
    
    func sendMessage(_ message: ATChatMessage, channel: ATCChatChannel, title: String, type: String = "", completionhandler: RequestDidCompleteBlock? = nil) {
        
        var channel = channel
        
        let send = {[weak self] (message: ATChatMessage, channel: ATCChatChannel, completionhandler: RequestDidCompleteBlock?) -> Void in
            guard let strongSelf = self else { return }
            let reference = strongSelf.db.collection(["channels", channel.id, "thread"].joined(separator: "/"))
            reference.addDocument(data: message.representation) { error in
                if let e = error {
                    print("Error sending message: \(e.localizedDescription)")
                    completionhandler?(false, e)
                }
                
                let content = message.image == nil ? message.content : "Photo"
                ATCRemoteData().updateChannel(path: ["channels", channel.id], message: content, date: message.sentDate, userIndex: channel.userIndex)
                if let currentUser = Globals.currentUser {
                    if !channel.token.isEmpty {
                        let title = "\(currentUser.displayName) shared \(type) \"\(title)\" with you"
                        PushNotificationManager.shared.sendPushNotification(to: channel.token, title: "", body: title, data: ["channel" : channel.id])
                    }
                    completionhandler?(true, nil)
                }
            }
        }
        
        if channel.id.isEmpty {
            checkPath(path: ["channels", channel.id, "thread"], dbRepresentation: channel.representation) { (id, error) in
                if let error = error {
                    completionhandler?(false, error)
                } else {
                    channel.id = id!
                    send(message, channel, completionhandler)
                }
            }
        } else {
            send(message, channel, completionhandler)
        }
        
                
    }
    
}
