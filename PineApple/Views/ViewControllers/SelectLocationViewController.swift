//
//  SelectLocationViewController.swift
//  PineApple
//
//  Created by Tao Man Kit on 25/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import CoreLocation
import GooglePlaces

class SelectLocationViewController: BaseViewController, ViewModelBased {

    // MARK: - Properties
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
                      @IBOutlet weak var searchTextField: UITextField!
                      @IBOutlet weak var searchFieldBaseView: UIView!
        
    var viewModel: LocationViewModel!
    typealias PlaceSelectionAction = (String) -> Void
    var placeSelectionAction: PlaceSelectionAction?
    
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureSearchField()
        configureSearchBar()
        configureNavigationBar()
        if viewModel == nil {
            viewModel = LocationViewModel()
        }
        bindViewModel(viewModel)
        bindAction()
    }
}

// MARK: - RX
extension SelectLocationViewController {
    
    func bindViewModel(_ viewModel: LocationViewModel) {
        self.viewModel = viewModel
        
        viewModel.predictions
        .bind(to: tableView.rx.items(cellIdentifier: "Cell", cellType: TableViewCell.self)) { row, model, cell in
            cell.labels!.first?.text = model.longName
        }.disposed(by: disposeBag)
        
        
        searchTextField.rx.text
            .orEmpty
            .throttle(1.0, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .bind(to: viewModel.searchText)
            .disposed(by: disposeBag)
        
        viewModel.searchText.asObservable()
            .bind {[weak self] text in
                guard let strongSelf = self else { return }
                strongSelf.viewModel.fetchPlaces(keyword: text)
            }
            .disposed(by: disposeBag)
        
    }
    
    func bindAction() {
        tableView.rx.itemSelected
            .bind {[weak self] indexPath in
                guard let strongSelf = self else { return }
                strongSelf.tableView.deselectRow(at: indexPath, animated: true)
                strongSelf.placeSelectionAction?(strongSelf.viewModel.predictions.value[indexPath.row].longName)
                strongSelf.navigationController?.popViewController()
        }.disposed(by: disposeBag)
        
    }
}

// MARK: - Private
extension SelectLocationViewController {
    
    private func configureSearchField() {
        searchFieldBaseView.layer.masksToBounds = false
        searchTextField.clearButtonMode = .never
        searchTextField.addInputAccessoryView(with: self, doneAction: #selector(self.dismissKeyboard))
    }
    
    private func configureNavigationBar() {
        title = "Select location"
        addBackButton()
    }
    
    private func configureSearchBar() {
        if let textField = searchBar.textField {
            textField.addInputAccessoryView(with: self, doneAction: #selector(self.dismissKeyboard))
        } else {
            searchBar.searchTextField.addInputAccessoryView(with: self, doneAction: #selector(self.dismissKeyboard))
        }
        
    }
    
}

// MARK: - UISearchBarDelegate
extension SelectLocationViewController: UISearchBarDelegate {
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }
}

// MARK: - UITextFieldDelegate
extension SelectLocationViewController: UITextFieldDelegate {
    @IBAction func textFieldValueDidChanged(_ sender: Any) {
//        if let text = searchTextField.text {
//            viewModel.fetchPlaces(keyword: text)
//        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchTextField.resignFirstResponder()
        return true
    }
}
