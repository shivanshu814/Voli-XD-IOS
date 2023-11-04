//
//  ATChatMessage.swift
//  ChatApp
//
//  Created by Florian Marcu on 8/20/18.
//  Copyright © 2018 Instamobile. All rights reserved.
//

import Firebase
import FirebaseFirestore
import MessageKit


class ATChatMessage: ATCGenericBaseModel, MessageType {
    var sender: SenderType {
        return Sender(id: atcSender.uid ?? "No Id", displayName: atcSender.uid ?? "No Name")
    }
    
    var id: String?
    
    var sentDate: Date
    
    var kind: MessageKind
    
    //  lazy var sender: Sender = Sender(id: atcSender.uid ?? "No Id", displayName: atcSender.uid ?? "No Name")
    
    var atcSender: ATCUser
    var recipient: ATCUser
    var seenByRecipient: Bool
    
    var messageId: String {
        return id ?? UUID().uuidString
    }
    
    var image: UIImage? = nil
    //  var downloadURL: URL? = nil
    var downloadURL: String? = nil
    let content: String
    
    init(messageKind: MessageKind, createdAt: Date, atcSender: ATCUser, recipient: ATCUser, seenByRecipient: Bool) {
        self.kind = messageKind
        self.sentDate = createdAt
        self.atcSender = atcSender
        self.recipient = recipient
        self.seenByRecipient = seenByRecipient
        
        switch messageKind {
        case .attributedText(let attributedText):
            self.content = attributedText.string
        case .photo(let item):
            self.image = item.image
            self.content = ""
        default:
            self.content = ""
        }
    }
    
      init(user: ATCUser, image: UIImage) {
        self.image = image
        content = ""
        sentDate = Date()
        id = nil
        self.kind = .text("")
        self.atcSender = user
        self.recipient = user
        self.seenByRecipient = true
      }
    
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let timeInterval = data["created"] as? TimeInterval else {
            return nil
        }
        let sentDate = Date(timeIntervalSince1970: timeInterval)
        guard let senderID = data["senderID"] as? String else {
            return nil
        }
        guard let senderFirstName = data["senderFirstName"] as? String else {
            return nil
        }
        guard let senderLastName = data["senderLastName"] as? String else {
            return nil
        }
        guard let senderProfilePictureURL = data["senderProfilePictureURL"] as? String else {
            return nil
        }
        guard let recipientID = data["recipientID"] as? String else {
            return nil
        }
        guard let recipientFirstName = data["recipientFirstName"] as? String else {
            return nil
        }
        guard let recipientLastName = data["recipientLastName"] as? String else {
            return nil
        }
        guard let recipientProfilePictureURL = data["recipientProfilePictureURL"] as? String else {
            return nil
        }
        
        id = document.documentID
        
        self.sentDate = sentDate
        self.atcSender = ATCUser(uid: senderID, firstName: senderFirstName, lastName: senderLastName, avatarURL: senderProfilePictureURL)
        self.recipient = ATCUser(uid: recipientID, firstName: recipientFirstName, lastName: recipientLastName, avatarURL: recipientProfilePictureURL)
        
        if let content = data["content"] as? String {
            self.content = content
            downloadURL = nil
            
            let textKind = MessageKind.attributedText(NSAttributedString(string: content, attributes: Styles.multipleLineTextAttributes))
            self.kind = textKind
            
        } else if let urlString = data["url"] as? String {
            downloadURL = urlString
            self.content = ""
            let item = ATCMediaItem(url: URL(string: urlString), image: nil, placeholderImage: UIImage(), size: CGSize(width: 200, height: 200))
            self.kind = .photo(item)
        } else {
            return nil
        }
        
        self.seenByRecipient = true
    }
    
    required init(jsonDict: [String: Any]) {
        fatalError()
    }
    
    var description: String {
        return self.messageText
    }
    
    var messageText: String {
        switch kind {
        case .text(let text):
            return text
        case .attributedText(let text):
            return text.string
        default:
            return ""
        }
    }
    
    var channelId: String {
        let id1 = (recipient.uid ?? "")
        let id2 = (atcSender.uid ?? "")
        return "\(id1):\(id2)"
    }
}

extension ATChatMessage: DatabaseRepresentation {
    
    var representation: [String : Any] {
        var rep: [String : Any] = [
            "created": sentDate.timeIntervalSince1970,
            "senderID": atcSender.uid ?? "",
            "senderFirstName": atcSender.firstName ?? "",
            "senderLastName": atcSender.lastName ?? "",
            "senderProfilePictureURL": atcSender.profilePictureURL ?? "",
            "recipientID": recipient.uid ?? "",
            "recipientFirstName": recipient.firstName ?? "",
            "recipientLastName": recipient.lastName ?? "",
            "recipientProfilePictureURL": recipient.profilePictureURL ?? "",
        ]
        
        if let url = downloadURL {
            rep["url"] = url
        } else {
            rep["content"] = content
        }
        return rep
    }
    
}

extension ATChatMessage: Comparable {
    
    static func == (lhs: ATChatMessage, rhs: ATChatMessage) -> Bool {
        return lhs.id == rhs.id
    }
    
    static func < (lhs: ATChatMessage, rhs: ATChatMessage) -> Bool {
        return lhs.sentDate < rhs.sentDate
    }
}

import Foundation

protocol DatabaseRepresentation {
    var representation: [String: Any] { get }
}

