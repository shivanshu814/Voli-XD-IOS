//
//  Keyword+Factory.swift
//  PineApple
//
//  Created by Tao Man Kit on 22/10/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import Firebase

extension Keyword {

    var collection: CollectionReference {
        return Firestore.firestore().collection("keywords")
    }
    
    var ref: DocumentReference {
        print(name)
        return Firestore.firestore().collection("keywords").document(name.lowercased().replacingOccurrences(of: "/", with: ""))
    }
        
}

// MARK: - Create
extension Keyword {
    static func create(_ keyword: Keyword, transaction: Transaction? = nil) {
        let ref = keyword.ref
        
        if transaction == nil {
            ref.setData(["name": keyword.name])
        } else {
            transaction?.setData([
                "name": keyword.name
            ], forDocument: ref)
        }
        
    }

}

// MARK: - Query
extension Keyword {
    static func findKeywords(_ keyword: String, paging: Paging? = nil, completionHandler: @escaping ([Keyword], Error?) -> Void) {
        Firestore.firestore().collection("keywords")
            .whereField("name", isGreaterThanOrEqualTo: keyword.lowercased())
            
            .order(by: "name")
            .limit(to: paging?.itemPerPage ?? ITEM_PER_PAGE)
            .getDocuments() { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                    completionHandler([], error)
                } else {
                    if querySnapshot!.documents.isEmpty {
                        completionHandler([], nil)
                    } else {
                        let keywords = querySnapshot!.documents.map{Keyword(data: $0.data())}
                        completionHandler(keywords, nil)
                    }
                }
        }
    }
}
