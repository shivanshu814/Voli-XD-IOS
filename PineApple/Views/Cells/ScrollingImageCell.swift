//
//  ScrollingImageCell.swift
//  PineApple
//
//  Created by Tao Man Kit on 30/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import FirebaseUI
import FirebaseStorage

class ScrollingImageCell: UICollectionViewCell {
    var imageView: UIImageView!
    var scrollView: UIScrollView!
    var dTapGR: UITapGestureRecognizer!
    var path: String! {
        didSet {
            loadImage(path: path)
        }
    }
    let storage = Storage.storage()
    var image: UIImage? {
        get { return imageView.image }
        set {
            imageView.image = newValue
            setNeedsLayout()
        }
    }
    var topInset: CGFloat = 0 {
        didSet {
            centerIfNeeded()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        scrollView = UIScrollView(frame: bounds)
        imageView = UIImageView(frame: bounds)
        imageView.contentMode = .scaleAspectFill
        scrollView.addSubview(imageView)
        scrollView.maximumZoomScale = 3
        scrollView.delegate = self
        scrollView.contentMode = .center
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        #if os(tvOS)
        scrollView.panGestureRecognizer.allowedTouchTypes = [
            NSNumber(value: UITouch.TouchType.indirect.rawValue)
        ]
        #endif
        addSubview(scrollView)
        
        dTapGR = UITapGestureRecognizer(target: self, action: #selector(doubleTap(gr:)))
        dTapGR.numberOfTapsRequired = 2
        addGestureRecognizer(dTapGR)
    }
    
    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = imageView.frame.size.height / scale
        zoomRect.size.width  = imageView.frame.size.width  / scale
        let newCenter = imageView.convert(center, from: scrollView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
    
    @objc func doubleTap(gr: UITapGestureRecognizer) {
        if scrollView.zoomScale == 1 {
            scrollView.zoom(to: zoomRectForScale(scale: scrollView.maximumZoomScale, center: gr.location(in: gr.view)), animated: true)
        } else {
            scrollView.setZoomScale(1, animated: true)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = bounds
        let size: CGSize
        if let image = imageView.image {
            let containerSize = CGSize(width: bounds.width, height: bounds.height - topInset)
            if containerSize.width / containerSize.height < image.size.width / image.size.height {
                size = CGSize(width: containerSize.width, height: containerSize.width * image.size.height / image.size.width )
            } else {
                size = CGSize(width: containerSize.height * image.size.width / image.size.height, height: containerSize.height )
            }
        } else {
            size = CGSize(width: bounds.width, height: bounds.width)
        }
        imageView.frame = CGRect(origin: .zero, size: size)
        scrollView.contentSize = size
        centerIfNeeded()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        scrollView.setZoomScale(1, animated: false)
    }
    
    func centerIfNeeded() {
        var inset = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
        if scrollView.contentSize.height < scrollView.bounds.height - topInset {
            let insetV = (scrollView.bounds.height - topInset - scrollView.contentSize.height)/2
            inset.top += insetV
            inset.bottom = insetV
        }
        if scrollView.contentSize.width < scrollView.bounds.width {
            let insetV = (scrollView.bounds.width - scrollView.contentSize.width)/2
            inset.left = insetV
            inset.right = insetV
        }
        scrollView.contentInset = inset
    }
}

// MARKS: - UIScrollViewDelegate
extension ScrollingImageCell: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerIfNeeded()
    }
}

// MARKS: - Private
extension ScrollingImageCell {
    private func loadImage(path: String) {
        
        if path.isEmpty {
            imageView.image = nil
        } else if path.starts(with: "/") {
            if let image = UIImage(contentsOfFile: path) {
                imageView.image = image
            }
        } else {
            let storageRef = storage.reference()
            let reference = storageRef.child(path)
            imageView.sd_setImage(with: reference, placeholderImage: imageView.image, completion: {[weak self] (image, error, cacheType, reference) in
                guard let strongSelf = self, path == self?.path else { return }
                
                if image != nil {
                    strongSelf.imageView?.image = image
                } else {
                    print(error?.localizedDescription ?? "")
                }
            })
            
        }
    }
}
