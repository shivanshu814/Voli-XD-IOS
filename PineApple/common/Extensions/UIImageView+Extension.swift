//
//  UIImageView.swift
//  PineApple
//
//  Created by Tao Man Kit on 3/10/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import UIKit
import FirebaseUI
import Firebase
import FirebaseStorage

extension UIImageView {
    func loadImage(_ path: String) {
        if path.starts(with: "/") {
            if let image = UIImage(contentsOfFile: path) {
                self.image = image
            }
        } else {
            let storageRef = Storage.storage().reference()
            let reference = storageRef.child(path)
            sd_setImage(with: reference, placeholderImage: nil, completion: {[weak self] (image, error, cacheType, reference) in
                guard let strongSelf = self else { return }
                if image != nil {
                    strongSelf.image = image
                } else {
                    print(error?.localizedDescription ?? "")
                }
            })
        }
    }
}
