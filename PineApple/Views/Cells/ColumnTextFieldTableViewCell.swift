//
//  ColumnTextFieldTableViewCell.swift
//  PineApple
//
//  Created by Tao Man Kit on 23/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ColumnTextFieldTableViewCell: UITableViewCell, ViewModelBased {
    
    // MARK: - Properties
    @IBOutlet weak var leftBorderView: UIView!
    @IBOutlet weak var rightBorderView: UIView!
    @IBOutlet weak var leftHeaderLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var rightHeaderLabel: UILabel!
    @IBOutlet weak var rightTextField: UITextField!
    @IBOutlet weak var rightErrorLabel: UILabel!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var viewHeight: NSLayoutConstraint!
    
    var viewModel: ColumnTextFieldViewModel!
    private var disposeBag = DisposeBag()
    
    // MARK: - View Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        configureTextStyles()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        textField.isSecureTextEntry = false
        textField.isUserInteractionEnabled = true
        textField.keyboardType = .default
        rightTextField.isSecureTextEntry = false
        rightTextField.isUserInteractionEnabled = true
        rightTextField.keyboardType = .default
        disposeBag = DisposeBag()
    }
    
}

// MARK: - RX
extension ColumnTextFieldTableViewCell {
    
    func bindViewModel(_ viewModel: ColumnTextFieldViewModel) {
        self.viewModel = viewModel
        
        leftHeaderLabel.text = viewModel.viewModel?.0.title
        rightHeaderLabel.text = viewModel.viewModel?.1.title
        textField.placeholder = viewModel.viewModel?.0.description
        rightTextField.placeholder = viewModel.viewModel?.1.description
        
        
        viewModel.viewModel?.0.value.asDriver()
            .drive(textField.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.viewModel?.1.value.asDriver()
            .drive(rightTextField.rx.text)
            .disposed(by: disposeBag)
        
        
        viewModel.viewModel?.0.errorValue
            .asObservable()
            .bind {[weak self] (error) in
                self?.errorLabel.text = error?.uppercased()
                self?.errorLabel.isHidden = error == nil
        }
        .disposed(by: disposeBag)
        
        viewModel.viewModel?.1.errorValue
            .asObservable()
            .bind {[weak self] (error) in
                self?.rightErrorLabel.text = error?.uppercased()
                self?.rightErrorLabel.isHidden = error == nil
        }
        .disposed(by: disposeBag)
        
        
    }
    
    func bindAction() {
        
    }
}

// MARK: - Private
extension ColumnTextFieldTableViewCell {
    private func configureTextStyles() {
        textField.borderStyle = .none
        textField.font = Styles.customFontLight(15)
        textField.setPlaceHolderTextColor(Styles.g797979)
        textField.delegate = self
        textField.clearButtonMode = .whileEditing
    }
}

//// MARK: - KVO
//extension ColumnTextFieldTableViewCell {
//    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//        let newValue = 55 + (change![NSKeyValueChangeKey.newKey] as? CGSize)!.height - 15
//
//        if newValue != textFieldHeight.constant {
//            textFieldHeight.constant = newValue
//            contentSizeDidChangeBlock?()
//        }
//    }
//}

// MARK - UITextFieldDelegate
extension ColumnTextFieldTableViewCell: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        leftBorderView.layer.borderColor = Styles.g797979.cgColor
    }
        
    func textFieldDidEndEditing(_ textField: UITextField) {
        leftBorderView.layer.borderColor = Styles.gD8D8D8.cgColor
        if self.textField == textField {
            viewModel.viewModel?.0.value.accept(textField.text ?? "")
        } else {
            viewModel.viewModel?.1.value.accept(textField.text ?? "")
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if self.textField == textField {
            viewModel.viewModel?.0.value.accept("")
        } else {
            viewModel.viewModel?.1.value.accept("")
        }
        return true
    }
    
}
