//
//  ImagesSelectionViewController.swift
//  PineApple
//
//  Created by Tao Man Kit on 5/11/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class ImagesSelectionViewController: BaseViewController, ViewModelBased {

    // MARK: - Properties
    @IBOutlet weak var collectionView: UICollectionView!
    var viewModel: ItineraryViewModel!    
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureAttachmentCollectionView()
        bindViewModel(viewModel)
        bindAction()
    }

}

// MARK: - RX
extension ImagesSelectionViewController {
    
    func bindViewModel(_ viewModel: ItineraryViewModel) {
        viewModel.loadAllAttachments()
        
        viewModel.attachments
            .bind(to: collectionView.rx.items(cellIdentifier: "AttachmentCollectionViewCell", cellType: AttachmentCollectionViewCell.self)) { (row, element, cell) in
                cell.bindViewModel(element)
        }.disposed(by: disposeBag)
                
    }
    
    func bindAction() {
        collectionView.rx.itemSelected
            .bind {[weak self] indexPath in
                guard let strongSelf = self else { return }
                strongSelf.viewModel.isVideo = false
                strongSelf.viewModel.heroImage.accept(strongSelf.viewModel.attachments.value[indexPath.row].attachment.path)
                strongSelf.viewModel.heroImageThumbnail.accept(strongSelf.viewModel.attachments.value[indexPath.row].attachment.thumbnail)
                
                strongSelf.navigationController?.popViewController(animated: true)
                
        }.disposed(by: disposeBag)
    }
    
}

// MARK: - Private
extension ImagesSelectionViewController {
    
    private func configureNavigationBar() {
        title = "Select cover image"
        addBackButton()
    }
    
    private func configureAttachmentCollectionView() {
        collectionView.register(nibWithCellClass: AttachmentCollectionViewCell.self)
        collectionView.delegate = self
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 30, right: 16)
        (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumLineSpacing = 12
        (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumInteritemSpacing = 12
    }
    
}

// MARK: - UICollectionViewDelegate, UICollectionViewDelegateFlowLayout
extension ImagesSelectionViewController : UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let wh = (view.frame.width-56)/3
        return CGSize(width: wh, height: wh)
    }
    
}
