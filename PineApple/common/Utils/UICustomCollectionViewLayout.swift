//
//  UICustomHeightCollectionViewLayout.swift.swift
//  PineApple
//
//  Created by Tao Man Kit on 6/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import UIKit

public protocol CustomLayoutDelegate {
    
    func collectionView(_ collectionView: UICollectionView, heightForItemAt indexPath: IndexPath, with width: CGFloat) -> CGFloat
}

public class UICustomCollectionViewLayout: UICollectionViewLayout {
    
    public var delegate: CustomLayoutDelegate!
    private var showHeader = true
    private var showFooter = true
    public var headerHeight: CGFloat = 90.0
    public var footerHeight: CGFloat = 221.0 {
        didSet {
            if let last = cache.last {
                var rect = last.frame
                rect.size.height = footerHeight
                last.frame = rect
            }
            
        }
    }
    
    public var numberOfColumns = 2
    public var cellPadding: CGFloat = 8
    
    public var cache = [UICollectionViewLayoutAttributes]()
    
    private var contentHeight: CGFloat = 0.0
    private var contentWidth: CGFloat {
        let insets = collectionView!.contentInset
        return collectionView!.bounds.width - 16
        // return collectionView!.bounds.width - (insets.left + insets.right)
    }
    
    override public var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }
    
    override public func prepare() {
        if cache.isEmpty {
//            collectionView?.contentInset = UIEdgeInsets(top: 0, left: cellPadding, bottom: cellPadding, right: cellPadding)
            collectionView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: cellPadding, right: 0)
            let columnWidth = contentWidth / CGFloat(numberOfColumns)
            var xOffset = [CGFloat]()
            for column in 0 ..< numberOfColumns {
                xOffset.append(CGFloat(column) * columnWidth + 8 )
            }
            
            if self.showHeader {
                let a = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, with: IndexPath(item: 1, section: 0))
                a.frame = CGRect(x: 0, y: 0, width: collectionView!.bounds.width, height: headerHeight)
                contentHeight = max(contentHeight, a.frame.maxY + cellPadding)
                cache.append(a)
            } else {
                headerHeight = 0
            }
            
            var yOffset = [CGFloat](repeating: headerHeight, count: numberOfColumns)
            var col = 0
            for item in 0 ..< collectionView!.numberOfItems(inSection: 0) {
                let indexPath = IndexPath(item: item, section: 0)
                
                let width = columnWidth - cellPadding
                
                let cardHeight = delegate.collectionView(collectionView!, heightForItemAt: indexPath, with: width)
                let height = cellPadding +  cardHeight + cellPadding
                let frame = CGRect(x: xOffset[col], y: yOffset[col], width: width, height: height)
//                var insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)
                var insetFrame = frame
//                insetFrame.size.width -= cellPadding
                insetFrame.size.height -= cellPadding * 2
                if col == 1 {
                    insetFrame.origin.x += cellPadding
                } else {
                    insetFrame.origin.x = 8
                }
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = insetFrame
                cache.append(attributes)
                
                contentHeight = max(contentHeight, frame.maxY)
                yOffset[col] = yOffset[col] + height
                
                col = col >= (numberOfColumns - 1) ? 0 : col+1
            }
            
            if (showFooter) {
                let a = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, with: IndexPath(item: 1, section: 0))
                a.frame = CGRect(x: 0, y: contentHeight + cellPadding, width: collectionView!.bounds.width, height: footerHeight + cellPadding * 3)
                contentHeight = max(contentHeight, a.frame.maxY + cellPadding)
                cache.append(a)
                
            }
        }
    }
    
    override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var layoutAttributes = [UICollectionViewLayoutAttributes]()
        for attributes in cache {
            if attributes.frame.intersects(rect) {
                layoutAttributes.append(attributes)
            }
        }
        return layoutAttributes
    }
}
