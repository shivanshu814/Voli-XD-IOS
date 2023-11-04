//
//  Comment.swift
//  PineApple
//
//  Created by Tao Man Kit on 8/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation

struct Comment {
    var id: String
    var user = User()
    var message: String
    var likeCount: Int
    var date: Date
    var tags: [String]
    var isLike = false

    // MARK: - Init
    init(id: String, user: User, message: String, likeCount: Int, date: Date, tags: [String]) {
        self.id = id
        self.user = user
        self.message = message
        self.likeCount = likeCount
        self.date = date
        self.tags = tags
    }
    
    init(data: [String : Any]) {
        self.id = data["id"] as? String ?? ""
        if let _user = data["user"] as? [String : Any] {
            self.user = User(data: _user)
        }
        self.message = data["message"] as? String ?? ""
        self.likeCount = data["likeCount"] as? Int ?? 0
        self.date = Date(timeIntervalSince1970: data["createdDate"] as? TimeInterval ?? 0)
        self.tags = data["tags"] as? [String] ?? []
    }
    
}

extension Comment: Equatable {
    static func == (lhs: Comment, rhs: Comment) -> Bool {
        return lhs.id == rhs.id
    }
}
