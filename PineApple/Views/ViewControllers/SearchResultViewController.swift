//
//  SearchResultViewController.swift
//  PineApple
//
//  Created by Tao Man Kit on 20/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class SearchResultViewController: BaseViewController, ViewModelBased {

    // MARK: - Properties
    @IBOutlet weak var tableView: UITableView!    
    var viewModel: SearchResultViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()                
        configureTableView()
        footerView.setup(self, disposeBag: disposeBag)
        bindViewModel(viewModel)
        bindAction()
    }

}

// MARK: - RX
extension SearchResultViewController {
    
    func bindViewModel(_ viewModel: SearchResultViewModel) {
        self.viewModel = viewModel
        
        switch viewModel.type {
        case .all:
            viewModel.model.all
                .bind(to: tableView.rx.items) {[weak self] tableView, index, element in
                    self?.showFooterView()
                    if element is ItineraryDetailViewModel {
                        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchItineraryTableViewCell", for: IndexPath(row: index, section: 0)) as! SearchItineraryTableViewCell
                        cell.bindViewModel(element as! ItineraryDetailViewModel)
                        return cell
                    } else if element is UserCellViewModel {
                        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchUserTableViewCell", for: IndexPath(row: index, section: 0)) as! SearchUserTableViewCell
                        cell.bindViewModel(element as! UserCellViewModel)
                        return cell
                    } else {
                        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchTagTableViewCell", for: IndexPath(row: index, section: 0)) as! SearchTagTableViewCell
                        cell.bindViewModel(element as! TagCellViewModel)
                        return cell
                    }
                    
            }.disposed(by: disposeBag)
            
            viewModel.model.all
                .asObservable()
                .bind {[weak self] (_) in
                    self?.showFooterView()
                    self?.stopAnimatingLoadMore()
            }.disposed(by: disposeBag)
            
            Observable.combineLatest(viewModel.model.userPaging.isMore, viewModel.model.itineraryPaging.isMore, viewModel.model.tagPaging.isMore) { (x, y, z) -> Bool in
                return x || y || z
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] (isMore) in
                self?.setIsMore(isMore)
            }).disposed(by: disposeBag)
            
        case .user:
            viewModel.model.users
                .bind(to: tableView.rx.items(cellIdentifier: "SearchUserTableViewCell", cellType: SearchUserTableViewCell.self)) {(row, element, cell) in
                    cell.bindViewModel(element)
                }.disposed(by: disposeBag)
            
            viewModel.model.users
                .asObservable()
                .bind {[weak self] (_) in
                    self?.showFooterView()
                    self?.stopAnimatingLoadMore()
            }.disposed(by: disposeBag)
            
            setupLoadMore(paging: viewModel.model.userPaging)
        case .itinerary:
            viewModel.model.itineraries
                .bind(to: tableView.rx.items(cellIdentifier: "SearchItineraryTableViewCell", cellType: SearchItineraryTableViewCell.self)) { (row, element, cell) in
                    cell.bindViewModel(element)
                }.disposed(by: disposeBag)
            
            viewModel.model.itineraries
                .asObservable()
                .bind {[weak self] (_) in
                    self?.showFooterView()
                    self?.stopAnimatingLoadMore()
            }.disposed(by: disposeBag)
            
            setupLoadMore(paging: viewModel.model.itineraryPaging)
        case .tag:
            viewModel.model.tags
                .bind(to: tableView.rx.items(cellIdentifier: "SearchTagTableViewCell", cellType: SearchTagTableViewCell.self)) {(row, element, cell) in
                    cell.bindViewModel(element)
                }.disposed(by: disposeBag)
            
            viewModel.model.tags
                .asObservable()
                .bind {[weak self] (_) in
                    self?.showFooterView()
                    self?.stopAnimatingLoadMore()
            }.disposed(by: disposeBag)
            
            setupLoadMore(paging: viewModel.model.tagPaging)
        }
        
        footerView.bindTags(viewModel.model.relatedTags)
    }
    
    func bindAction() {
        
        // FooterView
        footerView.loadMoreButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.loadData()
        }.disposed(by: disposeBag)
        
        // TableView
        tableView.rx.itemSelected
            .bind {[weak self] indexPath in
                guard let strongSelf = self else { return }
                strongSelf.tableView.deselectRow(at: indexPath, animated: true)
                switch strongSelf.viewModel.type {
                case .all:
                    let element = strongSelf.viewModel.model.all.value[indexPath.row]
                    if let vm = element as? ItineraryDetailViewModel {
                        strongSelf.showItineraryDetailPage(vm)
                    } else if let vm =  element as? UserCellViewModel {
                        let vm = ProfileDetailViewModel(user: vm.user)
                        strongSelf.showUserProfilePage(vm)
                    } else if let vm = element as? TagCellViewModel {
                        strongSelf.showSeeAllPage(SuggestionsViewModel(tagViewModel: TagViewModel(tag: vm.tag.name)))
                    }
                case .user:
                    let element = strongSelf.viewModel.model.users.value[indexPath.row]
                    let vm = ProfileDetailViewModel(user: element.user)
                    strongSelf.showUserProfilePage(vm)
                case .itinerary:
                    let element = strongSelf.viewModel.model.itineraries.value[indexPath.row]
                    strongSelf.showItineraryDetailPage(element)
                case .tag:
                    let element = strongSelf.viewModel.model.tags.value[indexPath.row]
                    strongSelf.showSeeAllPage(SuggestionsViewModel(tagViewModel: TagViewModel(tag: element.tag.name)))
                }
        }.disposed(by: disposeBag)
    }
    
}

// MARK: - Private
extension SearchResultViewController {
    
    private func loadData() {
        startAnimatingLoadMore()
        switch viewModel.type {
        case .all:
            viewModel.model.searchUsers()
            viewModel.model.searchItineraries()
            viewModel.model.searchTags()
        case .user: viewModel.model.searchUsers()
        case .itinerary: viewModel.model.searchItineraries()
        case .tag: viewModel.model.searchTags()
        }
    }
    
    private func configureTableView() {
        tableView.contentInset = UIEdgeInsets(top: 24, left: 0, bottom: 30, right: 0)
        tableView.register(nibWithCellClass: SearchUserTableViewCell.self)
        tableView.register(nibWithCellClass: SearchItineraryTableViewCell.self)
        tableView.register(nibWithCellClass: SearchTagTableViewCell.self)                
        tableView.tableFooterView = footerView
    }
        
}

