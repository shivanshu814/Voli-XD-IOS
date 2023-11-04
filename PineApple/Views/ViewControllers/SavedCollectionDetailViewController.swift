//
//  SavedCollectionDetailViewController.swift
//  PineApple
//
//  Created by Tao Man Kit on 4/10/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import ViewAnimator

class SavedCollectionDetailViewController: BaseViewController, ViewModelBased {

    // MARK: - Properties
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nameLabel: UILabel!
    var viewModel: SavedCollectionDetailViewModel!
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureTableView()
        footerView.setup(self, disposeBag: disposeBag, showRelatedTag: false)
        bindViewModel(viewModel)
        bindAction()
        loadData()
        
        NotificationCenter.default.addObserver(forName: .didItineraryDidUpdated, object: nil, queue: .main) {[weak self] notification in
            if let itinerary = notification.userInfo?["itinerary"] as? Itinerary {
                self?.viewModel.refresh(itinerary)
            }
        }
        
        NotificationCenter.default.addObserver(forName: .didCollectionDidUpdated, object: nil, queue: .main) {[weak self] notification in
            if let action = notification.userInfo?["action"] as? String, action == "rename" { return }
            if let collection = notification.userInfo?["collection"] as? SavedCollection {
                let unsavedItinerary = notification.userInfo?["unsavedItinerary"] as? Itinerary
                self?.viewModel.refresh(collection, unsavedItinerary: unsavedItinerary)
            } else {
                self?.loadData()
            }
        }
    }

}

// MARK: - RX
extension SavedCollectionDetailViewController {
    
    func bindViewModel(_ viewModel: SavedCollectionDetailViewModel) {
            
        setupLoadMore(paging: viewModel.paging)
        
        viewModel.name
            .asDriver()
            .drive(nameLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.itineraries
            .bind(to: tableView.rx.items(cellIdentifier: "ItineraryTableViewCell", cellType: ItineraryTableViewCell.self)) { (row, element, cell) in
            cell.bindViewModel(element)
            cell.itemDidClickBlock = { [weak self] vm in
                guard let strongSelf = self else { return }
                strongSelf.showItineraryDetailPage(vm)
            }
            cell.commentDidClickBlock = { [weak self] vm in
                guard let strongSelf = self else { return }
                strongSelf.showCommentPage(CommentViewModel(model: vm))
            }
            cell.saveDidClickBlock = { [weak self] vm in
                guard let strongSelf = self else { return }
                if !vm.model.isSave.value {
                    strongSelf.showSavedCollectionPopup(vm)
                } else {
                    vm.unsave {[weak self] (result, error) in
                        guard let strongSelf = self else { return }
                        if let error = error {
                            Globals.topViewController.showAlert(title: "Error", message: error.localizedDescription)
                        } else {
                            strongSelf.viewModel.remove(itinerary: vm)                            
                        }
                    }
                }
                
            }
        }.disposed(by: disposeBag)
        
        viewModel.itineraries
            .asObservable()
            .bind { [weak self] (rows) in
                guard let strongSelf = self else { return }
                if viewModel.paging.start == 0 && rows.count > 1 && viewModel.isAnimated {
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
        }.disposed(by: disposeBag)
    }
    
    func bindAction() {
        
        footerView.loadMoreButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.loadData()
        }.disposed(by: disposeBag)
        
        tableView.rx.itemSelected
            .bind {[weak self] indexPath in
                guard let strongSelf = self else { return }
                strongSelf.showItineraryDetailPage(strongSelf.viewModel.itineraries.value[indexPath.row])
        }.disposed(by: disposeBag)
                
    }
    
}

// MARK - Private
extension SavedCollectionDetailViewController {
    
    @objc override func handleRefresh(_ refreshControl: UIRefreshControl) {
        refreshControl.beginRefreshing()
        viewModel.paging.start = 0
        loadData()
    }
    
    private func loadData() {
        if viewModel.itineraries.value.isEmpty {
            showLoading()
        }
        startAnimatingLoadMore()
        viewModel.getItineraries {[weak self] (result, error) in
            guard let strongSelf = self else { return }
            strongSelf.refreshControl.endRefreshing()
            strongSelf.stopAnimatingLoadMore()
            strongSelf.stopLoading()
            if let error = error {
                strongSelf.showAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }
    
    private func configureNavigationBar() {
        title = "Collection"
        addBackButton()
        addMoreButton()
    }
    
    private func configureTableView() {
        tableView.addSubview(refreshControl)
        tableView.register(nibWithCellClass: ItineraryTableViewCell.self)
        tableView.estimatedRowHeight = 358
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 78, right: 0)
        tableView.tableFooterView = footerView
    }

    override func showActionSheet() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let shareAction = UIAlertAction(title: "Share this collection",
                                              style: .default) {[weak self] (action) in
                                                guard let strongSelf = self else { return }
                                                let id = strongSelf.viewModel.model.id
                                                let name = strongSelf.viewModel.model.name
                                                Globals.generateDynamicLink(type: .collection, id: id, name: name) {[weak self] (url) in
                                                    if let url = url {
                                                        self?.showShareActionSheet(url: url, title: name, type: "collection")
                                                    }
                                                }
        }
        
        let deleteAction = UIAlertAction(title: "Delete",
                                              style: .default) {[weak self] (action) in
                                                guard let strongSelf = self else { return }
                                                strongSelf.showDeletedCollectionPopup(strongSelf.viewModel, collectionDidDeleteBlock: { [weak self] in
                                                    self?.navigationController?.popViewController()
                                                })
        }
        
        let renameAction = UIAlertAction(title: "Rename collection",
                                              style: .default) {[weak self] (action) in
                                                guard let strongSelf = self else { return }
                                                strongSelf.showRenameCollectionPopup(strongSelf.viewModel)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel) { (action) in }
        
        alertController.addAction(deleteAction)
        alertController.addAction(shareAction)        
        alertController.addAction(renameAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
}


