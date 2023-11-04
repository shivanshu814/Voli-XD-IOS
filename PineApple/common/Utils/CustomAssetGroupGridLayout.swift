//
//  CustomAssetGroupGridLayout.swift
//  PineApple
//
//  Created by Tao Man Kit on 1/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import UIKit

open class CustomAssetGroupGridLayout: UICollectionViewFlowLayout {
    
    open override func prepare() {
        super.prepare()
        
        var minItemWidth: CGFloat = 90
        if UI_USER_INTERFACE_IDIOM() == .pad {
            minItemWidth = 110
        }
        
        let interval: CGFloat = 1
        self.minimumInteritemSpacing = interval
        self.minimumLineSpacing = interval
        
        let contentWidth = self.collectionView!.bounds.width
        
        let itemCount = Int(floor(contentWidth / minItemWidth))
        var itemWidth = (contentWidth - interval * (CGFloat(itemCount) - 1)) / CGFloat(itemCount)
        let actualInterval = (contentWidth - CGFloat(itemCount) * itemWidth) / (CGFloat(itemCount) - 1)
        itemWidth += actualInterval - interval
        
        let itemSize = CGSize(width: itemWidth, height: itemWidth)
        self.itemSize = itemSize
    }
    
}
