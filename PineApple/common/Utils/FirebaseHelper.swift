//
//  FirebaseHelper.swift
//  PineApple
//
//  Created by Tao Man Kit on 23/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import Firebase

class FirebaseHelper {
    static func getSharedCount(ref: DocumentReference, shards: String = "shards", completionHandler: @escaping (Int, Error?) -> Void) {
        ref.collection(shards).getDocuments() { (querySnapshot, error) in
            var totalCount = 0
            if let error = error {
                print(error.localizedDescription)
                completionHandler(-1, error)
            } else {
                for document in querySnapshot!.documents {
                    let count = document.data()["count"] as! Int
                    totalCount += count
                }
            }
            
            print("Total count is \(totalCount)")
            completionHandler(totalCount, nil)
        }
    }
    
    static func updateCounter(ref: DocumentReference, shards: String = "shards", shardId: Int? = nil, value: Int, transaction: Transaction? = nil) {
        let shardId = shardId ?? Int(arc4random_uniform(UInt32(globalNumShards)))
        let shardRef = ref.collection(shards).document(String(shardId))
        
        if transaction == nil {
            shardRef.updateData(["count": FieldValue.increment(Int64(value))])
        } else {
            transaction?.updateData(["count": FieldValue.increment(Int64(value))], forDocument: shardRef)
        }
    }
    
//    static func delete(collection: CollectionReference, batchSize: Int = 100) {
//        // Limit query to avoid out-of-memory errors on large collections.
//        // When deleting a collection guaranteed to fit in memory, batching can be avoided entirely.
//        collection.limit(to: batchSize).getDocuments { (docset, error) in
//            // An error occurred.
//            let docset = docset
//            
//            let batch = collection.firestore.batch()
//            docset?.documents.forEach { batch.deleteDocument($0.reference) }
//            
//            batch.commit {_ in
//                self.delete(collection: collection, batchSize: batchSize)
//            }
//        }
//    }
}
