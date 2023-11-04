//
//  AttachmentCollectionViewCell.swift
//  PineApple
//
//  Created by Tao Man Kit on 16/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Firebase
import FirebaseUI
import SDWebImage

class AttachmentCollectionViewCell: UICollectionViewCell, ViewModelBased {
    
    // MARK: - Properties
    @IBOutlet weak var attachmentImageView: UIImageView!
    @IBOutlet weak var attachmentBaseView: UIView!
    var viewModel: AttachmentViewModel!
    private var disposeBag = DisposeBag()
    
    // MARK: - View Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        attachmentBaseView.layer.masksToBounds = false
    }
    
    override func prepareForReuse() {
        disposeBag = DisposeBag()
        attachmentBaseView.layer.masksToBounds = false
        attachmentImageView.image = nil
        hero.isEnabled = true
    }
}

// MARK: - RX
extension AttachmentCollectionViewCell {
    
    func bindViewModel(_ viewModel: AttachmentViewModel) {
        self.viewModel = viewModel
        loadImage()
        if let indexPath = viewModel.indexPath {
            attachmentImageView.hero.id = "image_\(indexPath.section)_\(indexPath.row)"
            attachmentImageView.hero.modifiers = [.fade, .scale(0.8)]
        }
    }
    
}

// MARK: - Private
extension AttachmentCollectionViewCell {
    fileprivate func loadImage() {        
        if viewModel.attachment.thumbnail.isEmpty {
            attachmentBaseView.layer.masksToBounds = true
            attachmentImageView.backgroundColor = UIColor.white
            attachmentImageView.image = #imageLiteral(resourceName: "AddImage")
        } else {
            attachmentImageView.loadImage(viewModel.attachment.thumbnail)
        }

    }
}
