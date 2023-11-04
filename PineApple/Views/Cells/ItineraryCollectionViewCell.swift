//
//  ItineraryCollectionViewCell.swift
//  PineApple
//
//  Created by Tao Man Kit on 30/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import Firebase
import FirebaseUI
import SDWebImage

class ItineraryCollectionViewCell: UICollectionViewCell, ViewModelBased {
    
    // MARK: - Properties
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLocationLabel: UILabel!
    @IBOutlet weak var attachmentCollectionView: UICollectionView!
    typealias ItemDidClickBlock = (ItineraryDetailViewModel) -> Void
    var itemDidClickBlock: ItemDidClickBlock?    
    var viewModel: ItineraryDetailViewModel!
    private var disposeBag = DisposeBag()
    
    
    // MARK: - View Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        configureTagCollectionView()
        shadowColor = UIColor.red //Styles.g504F4F.cgColor
    }
    
    override func prepareForReuse() {
        disposeBag = DisposeBag()
    }
}

// MARK: - RX
extension ItineraryCollectionViewCell {
    
    func bindViewModel(_ viewModel: ItineraryDetailViewModel) {
        self.viewModel = viewModel
        
        (viewModel.model.rows.value[0] as! RequiredFieldViewModel).value
            .asDriver()
            .drive(titleLabel.rx.text)
            .disposed(by: disposeBag)
        
        Observable.combineLatest(viewModel.timeSpend, viewModel.model.activityViewModels.first!.subLocalityString) { (x, y) -> String in
            return x + " • " + y
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] (timeLocation) in
                guard let strongSelf = self else { return }
                strongSelf.dateLocationLabel.text = timeLocation
            })
            .disposed(by: disposeBag)
        
        viewModel.attachments
            .bind(to: attachmentCollectionView.rx.items(cellIdentifier: "AttachmentCollectionViewCell", cellType: AttachmentCollectionViewCell.self)) { (row, element, cell) in
                cell.bindViewModel(element)
                cell.hero.isEnabled = false
            }.disposed(by: disposeBag)
                
    }
    
    func bindAction() {
        
        attachmentCollectionView.rx.itemSelected
            .bind {[weak self] indexPath in
                guard let strongSelf = self else { return }
                strongSelf.itemDidClickBlock?(strongSelf.viewModel)
            }.disposed(by: disposeBag)
        
    }
    
}

// MARK: - Private
extension ItineraryCollectionViewCell {
    
    private func configureTagCollectionView() {
        attachmentCollectionView.register(nibWithCellClass: AttachmentCollectionViewCell.self)

    }
}

