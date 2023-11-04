//
//  SavedViewController.swift
//  PineApple
//
//  Created by Tao Man Kit on 14/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import ViewAnimator

class SavedViewController: BaseViewController, ViewModelBased {

    // MARK: - Properties
    fileprivate enum SegueIdentifier: String {
        case detailSegue = "DetailSegue"
    }
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noItemTitleLabel: UILabel!
    @IBOutlet weak var noItemMessageLabel: UILabel!
    var viewModel: SavedCollectionViewModel! {
        didSet {
            bindViewModel(viewModel)
            bindAction()
        }
    }
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        configureNavigationBar()
        viewModel = SavedCollectionViewModel()
        
        NotificationCenter.default.addObserver(forName: .didItineraryDidUpdated, object: nil, queue: .main) {[weak self] notification in
            if let itinerary = notification.userInfo?["itinerary"] as? Itinerary {
                self?.viewModel.refresh(itinerary)
            }
        }
        
        NotificationCenter.default.addObserver(forName: .didCollectionDidUpdated, object: nil, queue: .main) {[weak self] notification in
            if let collection = notification.userInfo?["collection"] as? SavedCollection {
                self?.viewModel.refresh(collection)
            } else {
                self?.loadData()
            }
        }
        
        NotificationCenter.default.addObserver(forName: .sharedCollectionDidReceived, object: nil, queue: .main) {[weak self] notification in
            self?.navigationController?.popToRootViewController(animated: true)
            
            if let id = notification.userInfo?["id"] as? String, let name = notification.userInfo?["name"] as? String, let uid = notification.userInfo?["uid"] as? String {
                self?.showLoading()
                self?.viewModel.handleSharedCollection(id, name: name, uid: uid, completionHandler: {[weak self] (result, error) in
                    self?.stopLoading()
                    if let error = error {
                        self?.showAlert(title: "Error", message: error.localizedDescription)
                    }
                    
                })
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !showNoPermissionViewIfNeeded() {
            loadData()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier.flatMap(SegueIdentifier.init) else { return }
        
        switch identifier {
        case .detailSegue:
            let destinationViewController = segue.destination as! SavedCollectionDetailViewController
            destinationViewController.viewModel = SavedCollectionDetailViewModel(model: viewModel.collections.value[sender as! Int])
        }
    }

}

// MARK: - RX
extension SavedViewController {
    
    func bindViewModel(_ viewModel: SavedCollectionViewModel) {
        
        viewModel.collections
            .bind(to: tableView.rx.items) { tableView, index, element in
                let indexPath = IndexPath(row: index, section: 0)
                let cell = tableView.dequeueReusableCell(withIdentifier: "SuggestionTableViewCell", for: indexPath) as! SuggestionTableViewCell
                                
                cell.bindViewModel(SuggestionsViewModel(savedCollection: element))
                cell.titleLabelHeight.constant = 24
                cell.suggestionDidClickBlock = { [weak self] vm, indexPath in
                    guard let strongSelf = self else { return }
                    strongSelf.showItineraryDetailPage(vm)
                }
                cell.seeAllDidClickBlock = { [weak self] vm in
                    guard let strongSelf = self else { return }
                    self?.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
                    strongSelf.performSegue(withIdentifier: SegueIdentifier.detailSegue.rawValue, sender: index)
                }
                return cell
                
        }.disposed(by: disposeBag)
        
        viewModel.collections
            .asObservable()
            .bind { [weak self] (rows) in
                guard let strongSelf = self else { return }
                strongSelf.tableView.isScrollEnabled = !rows.isEmpty
                strongSelf.noItemTitleLabel.isHidden = !rows.isEmpty
                strongSelf.noItemMessageLabel.isHidden = !rows.isEmpty
                if viewModel.paging.start == 0 && rows.count > 1 && viewModel.isAnimated {
                    strongSelf.tableView.isHidden = true
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.1, execute: {
                        strongSelf.tableView.isHidden = false
                        let animations = [AnimationType.from(direction: .bottom, offset: 300.0)]
                        let cells = strongSelf.tableView.visibleCells
                        UIView.animate(views: cells, animations: animations, completion: nil)
                        strongSelf.viewModel.isAnimated = false
                    })
                }
        }.disposed(by: disposeBag)
    }
}

// MARK - Private
extension SavedViewController {
    
    @objc override func dismissPopup() {
        super.dismissPopup()
        Globals.rootViewController.selectLastIndex()
    }
    
    private func loadData() {
        if viewModel.collections.value.isEmpty {
            showLoading()
        }
        viewModel.getCollectionList {[weak self] (result, error) in
            self?.stopLoading()
            if let error = error {
                self?.showAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }
    
    private func configureTableView() {
        tableView.register(nibWithCellClass: SuggestionTableViewCell.self)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 78, right: 0)
        tableView.estimatedRowHeight = 297
    }
    
    private func configureNavigationBar() {
        title = "Saved"        
    }

}
