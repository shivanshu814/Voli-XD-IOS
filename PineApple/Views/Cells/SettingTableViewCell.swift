//
//  SettingTableViewCell.swift
//  PineApple
//
//  Created by Tao Man Kit on 17/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class SettingTableViewCell: UITableViewCell, ViewModelBased {

    // MARK: - Properties
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var switchControl: UISwitch!
    var viewModel: SettingCellViewModel!
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
extension SettingTableViewCell {
    
    func bindViewModel(_ viewModel: SettingCellViewModel) {
        self.viewModel = viewModel
        
        viewModel.title.asDriver()
            .drive(titleLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.isEnabled.asDriver()
            .drive(switchControl.rx.isOn)
            .disposed(by: disposeBag)
        
        bindAction()
    }
    
    func bindAction() {
        
        switchControl.rx.isOn.subscribe {[weak self] isOn in
            guard let strongSelf = self else { return }
            strongSelf.viewModel.save(isOn: isOn.element!)
                
            }.disposed(by: self.disposeBag)
    }
    
}
