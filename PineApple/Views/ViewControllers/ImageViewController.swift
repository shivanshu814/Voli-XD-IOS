//
//  ItineraryDetailViewController.swift
//  PineApple
//
//  Created by Tao Man Kit on 28/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import Hero
import RxCocoa
import RxSwift
import FirebaseUI

class ImageViewController: UIViewController {
    
    // MARK: - Properties
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var backButton: UIButton!
    
    var viewModel: ActivityViewModel!
    var image: UIImage!
    var imageURLString = ""
    var selectedIndex: IndexPath!
    var panGR = UIPanGestureRecognizer()
    
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = true
        self.collectionView.contentInsetAdjustmentBehavior = .never
        //    automaticallyAdjustsScrollViewInsets = false
        collectionView.isPagingEnabled = true
        preferredContentSize = CGSize(width: view.bounds.width, height: view.bounds.width)
        
        view.layoutIfNeeded()
        collectionView!.reloadData()
        if let selectedIndex = selectedIndex {
            collectionView!.scrollToItem(at: IndexPath(row: selectedIndex.row, section: 0), at: .centeredHorizontally, animated: false)
        }
        
        panGR.addTarget(self, action: #selector(pan))
        panGR.delegate = self
        collectionView?.addGestureRecognizer(panGR)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        for v in (collectionView!.visibleCells as? [ScrollingImageCell])! {
            v.topInset = topLayoutGuide.length
        }
    }
    
    
}

// MARK: - UICollectionViewDataSource
extension ImageViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel == nil ? 1 : viewModel.attachments.value.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let imageCell = (collectionView.dequeueReusableCell(withReuseIdentifier: "item", for: indexPath) as? ScrollingImageCell)!
        if viewModel == nil {
            imageCell.imageView.loadImage(imageURLString)
        } else {
            if indexPath.row == selectedIndex.row {
                imageCell.imageView.image = image
            }
            imageCell.imageView.hero.id = "image_\(selectedIndex.section)_\(indexPath.row)"
            imageCell.imageView.hero.modifiers = [.position(CGPoint(x:view.bounds.width/2, y:view.bounds.height+view.bounds.width/2)), .scale(0.6), .fade]
            imageCell.path = viewModel.attachments.value[indexPath.row].attachment.path
            
        }
        imageCell.topInset = topLayoutGuide.length
        imageCell.imageView.isOpaque = true
        return imageCell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ImageViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return view.bounds.size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

// MARK: - UIGestureRecognizerDelegate
extension ImageViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let cell = collectionView?.visibleCells[0] as? ScrollingImageCell,
            cell.scrollView.zoomScale == 1 {
            let v = panGR.velocity(in: nil)
            return v.y > abs(v.x)
        }
        return false
    }
}

// MARK: - Private
extension ImageViewController {
    
    @objc private func pan() {
        let translation = panGR.translation(in: nil)
        let progress = translation.y / 2 / collectionView!.bounds.height
        switch panGR.state {
        case .began:
            hero.dismissViewController()
        case .changed:
            Hero.shared.update(progress)
            if let cell = collectionView?.visibleCells[0]  as? ScrollingImageCell {
                let currentPos = CGPoint(x: translation.x + view.center.x, y: translation.y + view.center.y)
                Hero.shared.apply(modifiers: [.position(currentPos)], to: cell.imageView)
            }
        default:
            if progress + panGR.velocity(in: nil).y / collectionView!.bounds.height > 0.3 {
                Hero.shared.finish()
            } else {
                Hero.shared.cancel()
            }
        }
    }
}
