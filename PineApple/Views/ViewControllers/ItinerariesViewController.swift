//
//  HomeViewController.swift
//  PineApple
//
//  Created by Tao Man Kit on 14/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import ViewAnimator
import FirebaseAuth
import DKImagePickerController

class ItinerariesViewController: BaseViewController, ViewModelBased {
    
    // MARK: - Properties
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var sortPopupView: SortPopupView!
    @IBOutlet weak var locationPopupView: LocationPopupView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var seeAllButton: UIButton!
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!    
    var viewModel: ItinerariesViewModel!    
    
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {        
        super.viewDidLoad()
        
        showSplashScreen()
        configureTableView()
        viewModel = ItinerariesViewModel()
        footerView.setup(self, disposeBag: disposeBag)
        bindViewModel(viewModel)
        bindAction()
        viewModel.filterViewModel.getSuggestTags()
        pullDownToRefresh(self.tableView)
        
        NotificationCenter.default.addObserver(forName: .didLogin, object: nil, queue: .main) {[weak self] _ in
            self?.dismissSplashScreen()
            Globals.isLogined = true
            self?.fetchItineraries()
            self?.viewModel.getRelatedTags()
            Globals.handleShareCollection()
            PushNotificationManager.shared.updateFirestorePushTokenIfNeeded()
        }
        
        NotificationCenter.default.addObserver(forName: .didItineraryDidUpdated, object: nil, queue: .main) {[weak self] notification in
            if let itinerary = notification.userInfo?["itinerary"] as? Itinerary {
                self?.viewModel.refresh(itinerary)
            }
        }
        
        NotificationCenter.default.addObserver(forName: .locationUpdated, object: nil, queue: .main) { _ in
            Globals.isLocationUpdated = true
//            let location = strongSelf.viewModel.getSelectedLocation(IndexPath(row: 0, section: 0))
//            strongSelf.viewModel.itinerariesFilterViewModel.location.accept(location)
//            strongSelf.fetchItineraries()
        }

        ProfileDetailViewModel.anonymousLoginIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        configureNavigationBarWhenDisappear()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}

// MARK: - RX
extension ItinerariesViewController {
    
    func bindViewModel(_ viewModel: ItinerariesViewModel) {
        
        viewModel.isMore
            .asObservable()
            .bind {[weak self] (isMore) in
                self?.setIsMore(isMore)
        }.disposed(by: disposeBag)
        
        viewModel.rows
            .bind(to: tableView.rx.items) { tableView, index, element in
                if index == 0 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "ItineraryHeaderTableViewCell", for: IndexPath(row: index, section: 0)) as! ItineraryHeaderTableViewCell
                    cell.bindViewModel(element as! ItinerariesFilterViewModel)
                    
                    cell.locationDidClickBlock = { [weak self] in
                        guard let strongSelf = self else { return }
                        self?.showLocationPopup(strongSelf.viewModel, completionBlock: { [weak self] in
                            self?.fetchItineraries()
                        })
                    }
                    
                    cell.sortDidClickBlock = { [weak self] in
                        guard let strongSelf = self else { return }
                        self?.showSortPopup(strongSelf.viewModel, completionBlock: { [weak self] in
                            self?.fetchItineraries()
                        })
                    }
                    cell.itemDidClickBlock = { [weak self] in
                        self?.viewModel.paging.start = 0
                        self?.fetchItineraries()
                    }
                    
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "ItineraryTableViewCell", for: IndexPath(row: index, section: 0)) as! ItineraryTableViewCell
                    cell.bindViewModel(element as! ItineraryDetailViewModel)
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
                            vm.unsave { (result, error) in
                                if let error = error {
                                    strongSelf.showAlert(title: "Error", message: error.localizedDescription)
                                }
                            }
                        }
                    }
                    return cell
                }
            }.disposed(by: disposeBag)
        
        viewModel.rows
            .asObservable()
            .bind { [weak self] (rows) in
                guard let strongSelf = self else { return }
                if viewModel.paging.start == 0 && rows.count > 1 && viewModel.isAnimated {
                    strongSelf.tableView.isHidden = true
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.1, execute: {
                        strongSelf.tableView.isHidden = false
                        let animations = [AnimationType.from(direction: .bottom, offset: 300.0)]
                        var cells = strongSelf.tableView.visibleCells
                        cells.remove(at: 0)
                        UIView.animate(views: cells, animations: animations, completion: { [weak self] in
                            self?.footerView.isHidden = false
                        })
                        strongSelf.viewModel.isAnimated = false
                    })
                }
        }.disposed(by: disposeBag)
        
        footerView.bindTags(viewModel.relatedTags)        
    }
    
    func bindAction() {
   
        tableView.rx.itemSelected
            .bind {[weak self] indexPath in
                guard let strongSelf = self else { return }
                
                if indexPath.row > 0 {
                    strongSelf.showItineraryDetailPage(strongSelf.viewModel.detailViewModels[indexPath.row - 1])
                }
        }.disposed(by: disposeBag)
        
        footerView.loadMoreButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.fetchItineraries(false)
        }.disposed(by: disposeBag)
    }
    
}

// MARK - Private
extension ItinerariesViewController {
    
    @objc override func handleRefresh(_ refreshControl: UIRefreshControl) {
        refreshControl.beginRefreshing()
        fetchItineraries()
    }
    
    private func fetchItineraries(_ fromStart: Bool = true) {
        synced(self) {
            if Globals.isLogined {
//            if Globals.isLocationUpdated && Globals.isLogined {
                if fromStart {
                    viewModel.paging.start = 0
                    viewModel.pagings.values.forEach { $0.start = 0 }
                } else {
                    startAnimatingLoadMore()
                }
                viewModel.getItineraries {[weak self] (_, error) in
                    self?.stopAnimatingLoadMore()
                    self?.refreshControl.endRefreshing()
                    if let error = error {
                        self?.showAlert(title: "Error", message: error.localizedDescription)
                    }
                }
            }
        }
        
    }
    
    private func configureTableView() {
        tableView.addSubview(refreshControl)
        tableView.register(nibWithCellClass: ItineraryTableViewCell.self)
        tableView.estimatedRowHeight = 350
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 48, right: 0)
        tableView.tableFooterView = footerView
    }

    private func configureNavigationBar() {
        addTitleView()
        addProfileButton()
    }
    
    private func configureNavigationBarWhenDisappear() {
        addProfileButton()
        navigationController?.navigationBar.titleTextAttributes = Styles.navigationBarTitleAttributes
        
    }
    
}
