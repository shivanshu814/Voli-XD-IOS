//
//  ItineraryDetailActivityTableViewCell.swift
//  PineApple
//
//  Created by Tao Man Kit on 29/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class ItineraryDetailActivityTableViewCell: UITableViewCell, ViewModelBased {

    // MARK: - Properties
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var locationOverlayButton: UIButton!
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var tagLabelTop: NSLayoutConstraint!
    
    var viewModel: ActivityViewModel!
    private var disposeBag = DisposeBag()
    typealias AttachmentDidClickBlock = (ActivityViewModel, UIImage?, IndexPath) -> Void
    var attachmentDidClickBlock: AttachmentDidClickBlock?
    
    typealias LocationDidClickBlock = (ActivityViewModel) -> Void
    var locationDidClickBlock: LocationDidClickBlock?
    
    // MARK: - View Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        configureTagCollectionView()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        disposeBag = DisposeBag()
    }

}

// MARK: - RX
extension ItineraryDetailActivityTableViewCell {
    
    func bindViewModel(_ viewModel: ActivityViewModel) {
        self.viewModel = viewModel
        
        viewModel.date
            .asDriver()
            .map{ "\(Styles.dateFormatter_HHmma.string(from: $0).lowercased())" }
            .drive(timeLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.timeSpend
            .asDriver()
            .map{$0.toShortString}
            .drive(durationLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.tags
            .asDriver()
            .map{($0.map{"#"+$0.name.value}).joined(separator: "  ")}
            .drive(tagLabel.rx.text)
            .disposed(by: disposeBag)
                
        viewModel.subLocalityString
            .asDriver()
            .drive(locationLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.attachments
            .bind(to: collectionView.rx.items(cellIdentifier: "AttachmentCollectionViewCell", cellType: AttachmentCollectionViewCell.self)) { (row, element, cell) in
                cell.bindViewModel(element)
            }.disposed(by: disposeBag)
        
        tagLabelTop.constant = viewModel.tags.value.isEmpty ? 0 : 16
        
        bindAction()
    }
    
    func bindAction() {
        
        locationOverlayButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.locationButton.sendActions(for: .touchUpInside)
        }.disposed(by: disposeBag)
        
        locationButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.locationDidClickBlock?(strongSelf.viewModel)
            }.disposed(by: disposeBag)
        
        collectionView.rx.itemSelected
            .bind {[weak self] indexPath in
                guard let strongSelf = self else { return }
                let image = (strongSelf.collectionView.cellForItem(at: indexPath) as! AttachmentCollectionViewCell).attachmentImageView.image
                strongSelf.attachmentDidClickBlock?(strongSelf.viewModel, image, indexPath)
            }.disposed(by: disposeBag)
    }
    
}


// MARK: - Private
extension ItineraryDetailActivityTableViewCell {
    
    private func configureTagCollectionView() {
        collectionView.register(nibWithCellClass: AttachmentCollectionViewCell.self)

    }
}
