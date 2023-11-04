//
//  ChatViewController.swift
//  PineApple
//
//  Created by Tao Man Kit on 28/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import NVActivityIndicatorView
import MessageUI
import ViewAnimator

class FollowingViewController: BaseViewController, ViewModelBased {

    // MARK: - Properties
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchFieldBaseView: UIView!
    @IBOutlet weak var clearButton: UIButton!
    var viewModel: FollowingViewModel!
    let config = ChatUIConfiguration()
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        config.configureUI()
        footerView.setup(self, disposeBag: disposeBag, showRelatedTag: false)
        configureTableView()
        
        if viewModel == nil {
            viewModel = FollowingViewModel(model: Globals.currentUser)
        }
        bindViewModel(viewModel)
        configureNavigationBar()
        configureSearchField()
        bindAction()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.paging.start = 0
        loadData()
    }
              
}

// MARK: - RX
extension FollowingViewController {
    
    func bindViewModel(_ viewModel: FollowingViewModel) {
        setupLoadMore(paging: viewModel.paging)
        
        
        viewModel.followingUsers
        .bind(to: tableView.rx.items(cellIdentifier: "UserTableViewCell", cellType: UserTableViewCell.self)) {[weak self] row, model, cell in
            guard let strongSelf = self else { return }
            cell.isShareMode = strongSelf.viewModel.mode
            cell.bindViewModel(model)
            cell.shareDidClickBlock = { [weak self] user in
                guard let strongSelf = self else { return }
                strongSelf.messageButtonDidClicked(user, title: strongSelf.viewModel.shareTitle, link: strongSelf.viewModel.shareLink?.absoluteString, type: strongSelf.viewModel.shareType)
            }
            
        }.disposed(by: disposeBag)
                
        viewModel.followingUsers
                    .asObservable()
                    .bind {[weak self] (rows) in
                        guard let strongSelf = self else { return }
                        strongSelf.tableView.reloadData()
                        
                        if rows.count > 0 && viewModel.isAnimated {
                            strongSelf.tableView.isHidden = true
                            DispatchQueue.main.asyncAfter(deadline: .now()+0.1, execute: {
                                strongSelf.tableView.isHidden = false
                                let animations = [AnimationType.from(direction: .bottom, offset: 300.0)]
                                let cells = strongSelf.tableView.visibleCells
                                UIView.animate(views: cells, animations: animations, completion: { [weak self] in
                                    self?.footerView.isHidden = false
                                })
                                
                                strongSelf.viewModel.isAnimated = false
                            })
                        }
                }
                .disposed(by: disposeBag)
        
        _ = searchTextField.rx.text
            .orEmpty
            .throttle(0.6, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .bind(to: viewModel.searchText)
            .disposed(by: disposeBag)
        
        viewModel.searchText.asObservable()
            .bind {[weak self] text in
                guard let strongSelf = self else { return }
                strongSelf.footerView.isHidden = !text.isEmpty
                strongSelf.viewModel.filterUser(keyword: text)
            }
            .disposed(by: disposeBag)
        
    }
    
    func bindAction() {
        clearButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.searchTextField.text = ""
                strongSelf.viewModel.filterUser(keyword: "")
        }.disposed(by: disposeBag)
        
        tableView.rx.itemSelected
            .bind {[weak self] indexPath in
                guard let strongSelf = self else { return }
                strongSelf.tableView.deselectRow(at: indexPath, animated: true)
                if strongSelf.viewModel.mode != .share {
                    let user = strongSelf.viewModel.followingUsers.value[indexPath.row].user
                    let vm = ProfileDetailViewModel(user: user)
                    strongSelf.showUserProfilePage(vm)
                }
        }.disposed(by: disposeBag)
        
        footerView.loadMoreButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.startAnimatingLoadMore()
                strongSelf.viewModel.getFollowingUser { [weak self] (result, error) in
                    self?.stopAnimatingLoadMore()
                    if let error = error {
                        self?.showAlert(title: "Error", message: error.localizedDescription)
                    }
                }
                
        }.disposed(by: disposeBag)
    }
}

// MARK: - Private
extension FollowingViewController {
    
    private func configureTableView() {
        tableView.register(nibWithCellClass: UserTableViewCell.self)
        tableView.contentInset = UIEdgeInsets(top: 24, left: 0, bottom: 78, right: 0)
        tableView.tableFooterView = footerView
    }
    
    private func loadData() {
        if Globals.currentUser != nil && viewModel.paging.start == 0 {
            showLoading()
        }
        viewModel.getFollowingUser {[weak self] (isSuccess, error) in
            guard let strongSelf = self else { return }
            strongSelf.stopLoading()
            if let error = error {
                strongSelf.showAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }
    
    private func configureSearchField() {
        searchFieldBaseView.layer.masksToBounds = false
        searchTextField.clearButtonMode = .never
        searchTextField.addInputAccessoryView(with: self, doneAction: #selector(self.dismissKeyboard))
        searchTextField.placeholder = viewModel.mode.placeholder
    }
    
    private func configureNavigationBar() {
        title = viewModel.mode.title
        if viewModel.mode != .message {
            addBackButton()
        }
    }
    
}

// MARK: - UISearchBarDelegate
extension FollowingViewController: UISearchBarDelegate {
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }
}

// MARK: - UITextFieldDelegate
extension FollowingViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchTextField.resignFirstResponder()
        return true
    }
}
