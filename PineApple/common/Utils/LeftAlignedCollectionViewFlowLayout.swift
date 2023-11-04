//
//  LeftAlignedCollectionViewFlowLayout.swift
//  NBCU
//
//  Created by Steven Tao on 6/9/2016.
//  Copyright © 2016 ROKO. All rights reserved.
//

import UIKit

class LeftAlignedCollectionViewFlowLayout: UICollectionViewFlowLayout {

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)
        
        var leftMargin = sectionInset.left
        
        attributes?.forEach { layoutAttribute in
            if layoutAttribute.frame.origin.x == sectionInset.left {
                leftMargin = sectionInset.left
            }
            else {
                if rect.size.width < leftMargin + layoutAttribute.frame.width {
                    layoutAttribute.frame.origin.x = sectionInset.left
                } else {
                    layoutAttribute.frame.origin.x = leftMargin
                }
                
            }
            
            leftMargin += layoutAttribute.frame.width + minimumInteritemSpacing
        }
        
        return attributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let layoutAttribute = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes
        
        // First in a row.
        if layoutAttribute?.frame.origin.x == sectionInset.left || (indexPath as NSIndexPath).item == 0 {
            layoutAttribute?.frame.origin.x = 0
            return layoutAttribute
        }
        
        // We need to align it to the previous item.
        let previousIndexPath = IndexPath(item: (indexPath as NSIndexPath).item - 1, section: (indexPath as NSIndexPath).section)
        guard let previousLayoutAttribute = self.layoutAttributesForItem(at: previousIndexPath) else {
            return layoutAttribute
        }
        
        layoutAttribute?.frame.origin.x = previousLayoutAttribute.frame.maxX + 7
        
        return layoutAttribute
    }

}
