//
//  SearchItineraryTableViewCell.swift
//  PineApple
//
//  Created by Tao Man Kit on 20/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class SearchItineraryTableViewCell: UITableViewCell, ViewModelBased {
    
    // MARK: - Properties
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var byLabel: UILabel!
    @IBOutlet weak var cityDurationLabel: UILabel!
    var viewModel: ItineraryDetailViewModel!
    private var disposeBag = DisposeBag()
    
    // MARK: - View Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
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
extension SearchItineraryTableViewCell {
    
    func bindViewModel(_ viewModel: ItineraryDetailViewModel) {
        self.viewModel = viewModel
        
        viewModel.heroImage
            .asObservable()
            .filterNil()
            .subscribe(onNext: {[weak self] (reference) in
                guard let strongSelf = self else { return }
                strongSelf.photoImageView.sd_setImage(with: reference, placeholderImage: nil, completion: { (image, error, cacheType, reference) in
                    if image != nil {
                        strongSelf.photoImageView.image = image
                    }
                })
            })
            .disposed(by: disposeBag)
        
        viewModel.model.title.asDriver()
            .drive(titleLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.city.asDriver()
            .drive(byLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.timeSpend.asDriver()
            .drive(cityDurationLabel.rx.text)
            .disposed(by: disposeBag)
    }
    
}
