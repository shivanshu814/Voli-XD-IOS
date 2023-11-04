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

let uiConfig = ATCChatUIConfiguration(primaryColor: Styles.pCFC2FF,
                                      secondaryColor: UIColor(hex: 0xF5F5F5),
                                      inputTextViewBgColor: .white,
                                      inputTextViewTextColor: .black,
                                      inputPlaceholderTextColor: UIColor(hex: 0x979797))

class ChatViewController: BaseViewController, ViewModelBased {

    // MARK: - Properties
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchFieldBaseView: UIView!
    @IBOutlet weak var clearButton: UIButton!
    var viewModel: ChatViewModel!
    private let config = ChatUIConfiguration()
    private var isFirst = true
              
}

// MARK: - View Life Cycle
extension ChatViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        config.configureUI()
        footerView.setup(self, disposeBag: disposeBag, showRelatedTag: false)
        configureTableView()
        
        if viewModel == nil {
            viewModel = ChatViewModel(model: Globals.currentUser)
        }
        bindViewModel(viewModel)
        configureNavigationBar()
        configureSearchField()
        bindAction()
        
        NotificationCenter.default.addObserver(forName: .messageDidReceived, object: nil, queue: .main) {[weak self] notification in
            if let id = notification.userInfo?["channel"] as? String {
                self?.navigationController?.popToRootViewController(animated: false)
                self?.viewModel.getChannelById(id, completionHandler: {[weak self] (channel, error) in
                    if let error = error {
                        self?.showAlert(title: "Error", message: error.localizedDescription)
                    } else {
                        self?.showChatRoom(channel!)
                    }
                })
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.paging.start = 0
        loadData()
    }
}

// MARK: - RX
extension ChatViewController {
    
    func bindViewModel(_ viewModel: ChatViewModel) {
        
        setupLoadMore(paging: viewModel.paging)
                
        viewModel.channels
        .bind(to: tableView.rx.items(cellIdentifier: "ChannelTableViewCell", cellType: ChannelTableViewCell.self)) { (row, model, cell) in
            cell.bindViewModel(model)
        }.disposed(by: disposeBag)
        
        _ = searchTextField.rx.text
            .orEmpty
            .throttle(0.6, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .bind(to: viewModel.searchText)
            .disposed(by: disposeBag)
        
        viewModel.searchText.asObservable()
            .bind {[weak self] text in
                guard let strongSelf = self else { return }
                strongSelf.viewModel.userIndex = 1
                strongSelf.viewModel.searchChannel(text, completionHandler: {[weak self] (result, error) in
                    if let error = error {
                        self?.showAlert(title: "Error", message: error.localizedDescription)
                    }
                })
        }.disposed(by: disposeBag)
        
    }
    
    func bindAction() {
        clearButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.searchTextField.text = ""
                strongSelf.viewModel.searchText.accept("")
        }.disposed(by: disposeBag)
        
        tableView.rx.itemSelected
            .bind {[weak self] indexPath in
                guard let strongSelf = self else { return }
                strongSelf.tableView.deselectRow(at: indexPath, animated: true)
                
                strongSelf.showChatRoom(indexPath.row)
            
        }.disposed(by: disposeBag)
        
        footerView.loadMoreButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.startAnimatingLoadMore()
                strongSelf.viewModel.getChannels { [weak self] (result, error) in
                    self?.stopAnimatingLoadMore()
                    if let error = error {
                        self?.showAlert(title: "Error", message: error.localizedDescription)
                    }
                }
        }.disposed(by: disposeBag)
    }
}

// MARK: - Private
extension ChatViewController {
    
    private func showChatRoom(_ index: Int) {
        let vc = ATCChatThreadViewController(user: Globals.currentUser!.atcUser, channel: viewModel.channels.value[index].model, uiConfig: uiConfig)
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func configureTableView() {
        tableView.register(nibWithCellClass: ChannelTableViewCell.self)        
        tableView.contentInset = UIEdgeInsets(top: 24, left: 0, bottom: 78, right: 0)
        tableView.tableFooterView = footerView
    }
    
    private func loadData() {
         if Globals.currentUser != nil && isFirst {
            isFirst = false
            showLoading()
        }
        viewModel.getChannels {[weak self] (isSuccess, error) in
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
        searchTextField.placeholder = "Search Inbox"
    }
    
    private func configureNavigationBar() {
        title = "Message"
    }
    
}

// MARK: - UISearchBarDelegate
extension ChatViewController: UISearchBarDelegate {
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }
}

// MARK: - UITextFieldDelegate
extension ChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchTextField.resignFirstResponder()
        return true
    }
}
