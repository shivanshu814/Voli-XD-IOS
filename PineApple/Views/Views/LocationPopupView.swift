//
//  LocationPopupView.swift
//  PineApple
//
//  Created by Tao Man Kit on 1/11/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class LocationPopupView: UIView, ViewModelBased {

    // MARK: - Properties
    @IBOutlet weak var tableView: UITableView!    
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var locationTableView: UITableView!
    @IBOutlet weak var locationPopupDismissButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var popupViewHeight: NSLayoutConstraint!
    var keyboardHeight: CGFloat = 0
    
    var superViewController: UIViewController?
    var viewModel: ItinerariesViewModel! {
        didSet {
            bindViewModel(viewModel)
            bindAction()
        }
    }
    var isSearching: Bool {
        return !viewModel.locationViewModel.searchText.value.isEmpty
    }
    
    private let disposeBag = DisposeBag()
    typealias CompletionBlock = () -> Void
    var completionBlock: CompletionBlock?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureTableView()
        configureTextField()
        addKeyboardNotification()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - RX
extension LocationPopupView {
    
    func bindViewModel(_ viewModel: ItinerariesViewModel) {
        locationTextField.rx.text
            .orEmpty
            .throttle(1.0, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .bind(to: viewModel.locationViewModel.searchText)
            .disposed(by: disposeBag)
        
        viewModel.locationViewModel.searchText.asObservable()
            .bind {[weak self] text in
                guard let strongSelf = self else { return }
                if text.isEmpty {
                    strongSelf.viewModel.showPopularCities()
                } else {
                    strongSelf.viewModel.locationViewModel.fetchPlaces(keyword: text)
                }
        }
        .disposed(by: disposeBag)
        
        viewModel.locationOptions
            .asObservable()
            .bind {[weak self] (_) in
                self?.tableView.reloadData()
        }.disposed(by: disposeBag)

        
    }
    
    func bindAction() {
        clearButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.locationTextField.text = ""
        }.disposed(by: disposeBag)
        
        locationTableView.rx.itemSelected
            .bind {[weak self] indexPath in
                guard let strongSelf = self, let viewModel = strongSelf.viewModel else { return }
                let index = indexPath.section == 0 ? indexPath.row : indexPath.row + 2
                
                viewModel.getSelectedLocation(index) { (location) in
                   
                    strongSelf.viewModel.isCurrentLocation = (indexPath.section == 0 && indexPath.row == 1 && location.longName != WORLDWIDE)
                    viewModel.filterViewModel.location.accept(location)
                    strongSelf.viewModel.itineraries = []
                    strongSelf.completionBlock?()
                    strongSelf.locationPopupDismissButton.sendActions(for: .touchUpInside)
                }
        }.disposed(by: disposeBag)
    }
    
}

// MARK: - Private
extension LocationPopupView {
    private func configureTextField() {
        locationTextField.delegate = self
        locationTextField.clearButtonMode = .never
        locationTextField.addInputAccessoryView(with: self, doneAction: #selector(self.dismissKeyboard))
    }
    
    private func configureTableView() {
        tableView.register(UINib(nibName: "OptionTableViewCell", bundle: nil), forCellReuseIdentifier: "OptionTableViewCell")
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    @objc private func dismissKeyboard() {
        locationTextField.resignFirstResponder()
    }
}

// MARK: - UITextFieldDelegate
extension LocationPopupView: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        locationTextField.resignFirstResponder()
        return true
    }
}

// MARK: - Keyboard
extension LocationPopupView {
    private func addKeyboardNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
                
    }
    
    @objc private func keyboardWillShow(_ notification: Notification ) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            keyboardHeight = keyboardRectangle.height
            popupViewHeight.constant = height - popupView.frame.minY - keyboardHeight + 10
        }
    }
    
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension LocationPopupView : UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return isSearching ? 1 : 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = viewModel.locationOptions.value.count
        return isSearching ? count : section == 0 ? 2 : count - 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "OptionTableViewCell", for: indexPath) as! OptionTableViewCell
        let element = viewModel.locationOptions.value[indexPath.section == 0 ? indexPath.row : indexPath.row + 2]
        cell.titleLabel.text = element.longName
        if !isSearching {
            if element.longName == CURRENT_LOCATION {
                cell.showIcon(#imageLiteral(resourceName: "navigation"))
            } else if element.longName == WORLDWIDE {
                cell.showIcon(#imageLiteral(resourceName: "globe"))
            }
            
            let isSelected = viewModel.isCurrentLocation ? element.longName == CURRENT_LOCATION : viewModel.filterViewModel.location.value.longName == element.longName
            cell.backgroundColor = isSelected ? Styles.pCFC2FF : UIColor.white
        }
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section != 0 else { return nil }
        
        let nib = UINib(nibName: "OptionHeaderView", bundle: nil)
        let view = nib.instantiate(withOwner: nil, options: nil).first as? OptionHeaderView
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 0 : 40
    }
    
}

