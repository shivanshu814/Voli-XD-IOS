//
//  ATCChatChannel.swift
//  ChatApp
//
//  Created by Florian Marcu on 8/26/18.
//  Copyright © 2018 Instamobile. All rights reserved.
//

import FirebaseFirestore

struct ATCChatChannel {

    var id: String
    var users: [User]
    var user1: String
    var user2: String
    var user1Name: String
    var user2Name: String
    var userIds: [String]
    var lastUpdated: Date
    var createdDate: Date
    var unreadCount1: Int = 0
    var unreadCount2: Int = 0
    var lastMessage = ""
    var name: String {
        var _name = ""
        for user in users {
            if user.id != Globals.currentUser?.id {
                _name = user.displayName
                break
            }
        }
        return _name
    }
    var recipient: ATCUser {
        return users.filter{$0.id != Globals.currentUser!.id}.first!.atcUser
    }
    var userIndex: Int {
        return user1 == Globals.currentUser!.id ? 1 : 2
    }
    var token: String!
    
//    init(id: String, name: String) {
//        self.id = id
//        self.users = []
//        self.lastUpdated = Date()
//        self.createdDate = Date()
//        self.userIds = []
//    }

    init(users: [User]) {
        self.id = ""
        self.users = users
        self.user1 = users.first!.id
        self.user2 = users.last!.id
        self.user1Name = users.first!.displayName.lowercased()
        self.user2Name = users.last!.displayName.lowercased()
        self.lastUpdated = Date()
        self.createdDate = Date()
        self.userIds = users.map {$0.id}
    }
    
    
    init(id: String, users: [User]) {
        self.id = id
        self.users = users
        self.user1 = users.first!.id
        self.user2 = users.last!.id
        self.user1Name = users.first!.displayName.lowercased()
        self.user2Name = users.last!.displayName.lowercased()
        self.lastUpdated = Date()
        self.createdDate = Date()
        self.userIds = users.map {$0.id}
    }

    init(document: QueryDocumentSnapshot) {
        let data = document.data()
        id = document.documentID
        self.users = (data["users"] as? [[String : Any]] ?? []).map{User(data: $0)}
        self.user1 = data["user1"] as? String ?? ""
        self.user2 = data["user2"] as? String ?? ""
        self.user1Name = data["user1Name"] as? String ?? ""
        self.user2Name = data["user2Name"] as? String ?? ""
        self.userIds = data["userIds"] as? [String] ?? []
        self.unreadCount1 = data["unreadCount1"] as? Int ?? 0
        self.unreadCount2 = data["unreadCount2"] as? Int ?? 0
        self.lastUpdated = Date(timeIntervalSince1970: data["lastUpdated"] as? TimeInterval ?? 0)
        self.createdDate = Date(timeIntervalSince1970: data["createdDate"] as? TimeInterval ?? 0)
        self.lastMessage = data["lastMessage"] as? String ?? ""
    }
    
    init(data: [String : Any]) {        
        self.id = data["id"] as? String ?? ""
        self.users = (data["users"] as? [[String : Any]] ?? []).map{User(data: $0)}
        self.user1 = data["user1"] as? String ?? ""
        self.user2 = data["user2"] as? String ?? ""
        self.user1Name = data["user1Name"] as? String ?? ""
        self.user2Name = data["user2Name"] as? String ?? ""
        self.userIds = data["userIds"] as? [String] ?? []
        self.unreadCount1 = data["unreadCount1"] as? Int ?? 0
        self.unreadCount2 = data["unreadCount2"] as? Int ?? 0
        self.lastUpdated = Date(timeIntervalSince1970: data["lastUpdated"] as? TimeInterval ?? 0)
        self.createdDate = Date(timeIntervalSince1970: data["createdDate"] as? TimeInterval ?? 0)
        self.lastMessage = data["lastMessage"] as? String ?? ""
    }
}

extension ATCChatChannel: DatabaseRepresentation {

    var representation: [String : Any] {
        var rep: [String : Any] = ["id": id]
        rep["users"] = users.map{$0.chat_dict}
        rep["userIds"] = userIds
        rep["user1"] = user1
        rep["user2"] = user2
        rep["user1Name"] = user1Name
        rep["user2Name"] = user2Name
        rep["lastUpdated"] = lastUpdated.timeIntervalSince1970
        rep["createdDate"] = createdDate.timeIntervalSince1970
        rep["unreadCount1"] = unreadCount1
        rep["unreadCount2"] = unreadCount2
        return rep
    }

}

extension ATCChatChannel: Comparable {

    static func == (lhs: ATCChatChannel, rhs: ATCChatChannel) -> Bool {
        return lhs.id == rhs.id
    }

    static func < (lhs: ATCChatChannel, rhs: ATCChatChannel) -> Bool {
        return lhs.lastUpdated < rhs.lastUpdated
    }

}
