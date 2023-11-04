//
//  SeeAllViewController.swift
//  PineApple
//
//  Created by Tao Man Kit on 5/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import FirebaseStorage
import FirebaseUI
import SDWebImage
import ViewAnimator

class SeeAllViewController: BaseViewController, ViewModelBased {

    // MARK: - Properties
    @IBOutlet weak var sortPopupBaseView: UIView!
    @IBOutlet weak var sortPopupView: UIView!
    @IBOutlet weak var sortPopupDismissButton: UIButton!
    @IBOutlet weak var sortTableView: UITableView!
    @IBOutlet weak var sortConfirmButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tagCollectionView: UICollectionView!
    
    private var sizingFooterView: TagFooterCollectionReusableView!
    private var sizingCell: TagCollectionViewCell!
    var viewModel: SuggestionsViewModel!
    private var isFirst = true
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationbar()
        if viewModel.type == .image || viewModel.type == .tag {
            configureTagCollectionView()
        } else {
            configureTableView()
            footerView.setup(self, disposeBag: disposeBag, showRelatedTag: false)
        }
        bindViewModel(viewModel)
        bindAction()
        loadData()
    }

}

// MARK: - Private
extension SeeAllViewController {
    
    @IBAction func dismissSortByPopup() {
        sortPopupBaseView.fadeOut(duration: 0.2, completion: nil)
        sortPopupView.playBounceAnimation([1, 0.8, 1.1, 0.6], duration: 0.5)
    }
    
    @objc override func handleRefresh(_ refreshControl: UIRefreshControl) {
        refreshControl.beginRefreshing()
        viewModel.paging.start = 0
        loadData()
    }
    
    private func loadData(fromStart: Bool = true) {
            
        if viewModel.type == .image {
            viewModel.tagViewModel.relatedTagViewModel.getRelatedTags()
            if fromStart {
                viewModel.tagViewModel.paging.start = 0
            }
        } else if viewModel.type != .tag {
            if fromStart {
                viewModel.paging.start = 0
            } else {
                startAnimatingLoadMore()
            }
        }
        
        viewModel.getSuggestion {[weak self] (result, error) in
            self?.stopAnimatingLoadMore()
            self?.refreshControl.endRefreshing()
            if let error = error {
                self?.showAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }
    
    private func configureTableView() {
        tableView.contentInset = UIEdgeInsets(top: 24, left: 0, bottom: 30, right: 0)
        tableView.register(nibWithCellClass: UserTableViewCell.self)
        tableView.register(nibWithCellClass: ItineraryTableViewCell.self)
        tableView.tableFooterView = footerView
        
    }
    
    private func configureTagCollectionView() {
        tagCollectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)
        tagCollectionView.alwaysBounceVertical = true
        tagCollectionView.register(nibWithCellClass: TagCollectionViewCell.self)
        
        var nib = UINib.init(nibName: "TagHeaderCollectionReusableView", bundle: nil)
        tagCollectionView.register(nib: nib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withClass: TagHeaderCollectionReusableView.self)
        
        nib = UINib.init(nibName: "TagFooterCollectionReusableView", bundle: nil)
        sizingFooterView = nib.instantiate(withOwner: nil, options: nil).first as? TagFooterCollectionReusableView
        tagCollectionView.register(nib: nib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withClass: TagFooterCollectionReusableView.self)

        tagCollectionView.delegate = self
        nib = UINib.init(nibName: "TagCollectionViewCell", bundle: nil)
        sizingCell = nib.instantiate(withOwner: nil, options: nil).first as? TagCollectionViewCell
        (tagCollectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumLineSpacing = 11
        (tagCollectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumInteritemSpacing = 7
        (tagCollectionView.collectionViewLayout as! UICollectionViewFlowLayout).sectionInset = UIEdgeInsets(top: 20, left: 15, bottom: 20, right: 15)
        
    }
    
    private func configureNavigationbar() {
        title = viewModel.title
        addBackButton()
    }
    
    private func playFirstLoadAnimation(rows: [Any], fromFirstRow: Bool = false) {
        if rows.count > 1 && viewModel.isAnimated {
            tableView.isHidden = true
            
            DispatchQueue.main.asyncAfter(deadline: .now()+0.1, execute: { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.tableView.isHidden = false
                let animations = [AnimationType.from(direction: .bottom, offset: 300.0)]
                var cells = strongSelf.tableView.visibleCells
                if !fromFirstRow {
                    cells.remove(at: 0)
                }
                UIView.animate(views: cells, animations: animations, completion: { [weak self] in
                    self?.footerView.isHidden = false
                })
                                        
                strongSelf.viewModel.isAnimated = false
            })
        }
    }
}

// MARK: - RX
extension SeeAllViewController {
    
    func bindViewModel(_ viewModel: SuggestionsViewModel) {
        
        setupLoadMore(paging: viewModel.paging)
                
        switch viewModel.type {
        case .sameUser, .similar:
            
            if viewModel.type == .similar {
                viewModel.similarSubType
                    .asObservable()
                    .bind {[weak self] (type) in
                        if type != nil {
                            self?.title = type!.title
                        }
                }
                .disposed(by: disposeBag)                
            }
            
            tagCollectionView.isHidden = true
            viewModel.suggestions
                .bind(to: tableView.rx.items) { tableView, index, element in
                    let cell = tableView.dequeueReusableCell(withIdentifier: "ItineraryTableViewCell", for: IndexPath(row: index, section: 0)) as! ItineraryTableViewCell
                    cell.bindViewModel(element)
                    cell.itemDidClickBlock = { [weak self] vm in
                        guard let strongSelf = self else { return }
                        strongSelf.showItineraryDetailPage(vm)
                    }
                    cell.commentDidClickBlock = { [weak self] vm in
                        guard let strongSelf = self else { return }
                        strongSelf.showCommentPage(CommentViewModel(model: vm))
                    }
                    return cell
                    
                }.disposed(by: disposeBag)
        case .user:
            tagCollectionView.isHidden = true
            viewModel.userSuggestions
                .bind(to: tableView.rx.items(cellIdentifier: "UserTableViewCell", cellType: UserTableViewCell.self)) { (row, element, cell) in
                    cell.bindViewModel(element)
                }.disposed(by: disposeBag)
        case .followingUser:
            tagCollectionView.isHidden = true
            viewModel.userSuggestions
                .bind(to: tableView.rx.items(cellIdentifier: "UserTableViewCell", cellType: UserTableViewCell.self)) { (row, element, cell) in
                    cell.bindViewModel(element)
                }.disposed(by: disposeBag)
        case .tag: 
            tableView.isHidden = true
            (tagCollectionView.collectionViewLayout as! UICollectionViewFlowLayout).headerReferenceSize = CGSize(width: 0, height: 0)
            
            (tagCollectionView.collectionViewLayout as! UICollectionViewFlowLayout).footerReferenceSize = CGSize(width: 0, height: 0)
            
            viewModel.tagSuggestions
                .bind(to: tagCollectionView.rx.items(cellIdentifier: "TagCollectionViewCell", cellType: TagCollectionViewCell.self)) { (row, element, cell) in
                    cell.bindViewModel(element)
                }.disposed(by: disposeBag)
        case .image:
                        
            title = "tag: \(viewModel.tagViewModel.model!)"
            tableView.isHidden = true
            
            let customCollectionViewLayout = UICustomCollectionViewLayout()
            customCollectionViewLayout.delegate = self
            customCollectionViewLayout.numberOfColumns = 2
            tagCollectionView.collectionViewLayout = customCollectionViewLayout
            
            tagCollectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            tagCollectionView.dataSource = self
            
            sizingFooterView.bindViewModel(viewModel.tagViewModel)
            sizingFooterView.contentSizeDidChangeBlock = { [weak self] height in
                guard let strongSelf = self else { return }
                let customCollectionViewLayout = UICustomCollectionViewLayout()
                customCollectionViewLayout.delegate = self
                customCollectionViewLayout.numberOfColumns = 2
                customCollectionViewLayout.footerHeight = height
                strongSelf.tagCollectionView.collectionViewLayout = customCollectionViewLayout
        
            }
            
            viewModel.tagViewModel.sortOptions
                .bind(to: sortTableView.rx.items(cellIdentifier: "SortTableViewCell", cellType: TableViewCell.self)) {[weak self] (row, element, cell) in
                    guard let strongSelf = self else { return }
                    cell.labels?[0].text = element.displayName
                    let isSelected = strongSelf.viewModel.tagViewModel.sortBy.value.displayName == element.displayName
                    cell.backgroundColor = isSelected ? Styles.pCFC2FF : UIColor.white
                    cell.labels?[0].font = isSelected ? UIFont.boldSystemFont(ofSize: 16) : UIFont.systemFont(ofSize: 16, weight: .medium)
                }.disposed(by: disposeBag)
            
                        
            viewModel.tagViewModel.imageSuggestion
                .asObservable()
                .bind {[weak self] (imageSuggestion) in
                    if !imageSuggestion.isEmpty,
                        let collectionViewLayout = self?.tagCollectionView.collectionViewLayout as? UICustomCollectionViewLayout{
                        collectionViewLayout.cache = []
                    }
                    self?.tagCollectionView.reloadData()
                }
                .disposed(by: disposeBag)
            
        default: break
        }
        
        viewModel.suggestions
            .asObservable()
            .bind { [weak self] (rows) in
                guard let strongSelf = self else { return }
                strongSelf.playFirstLoadAnimation(rows: rows, fromFirstRow: strongSelf.viewModel.type != .image)
        }.disposed(by: disposeBag)
        
        viewModel.userSuggestions
            .asObservable()
            .bind { [weak self] (rows) in
                guard let strongSelf = self else { return }
                strongSelf.playFirstLoadAnimation(rows: rows, fromFirstRow: true)
        }
        .disposed(by: disposeBag)
        
    }
    
    func bindAction() {
        
        footerView.loadMoreButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.loadData(fromStart: false)
        }.disposed(by: disposeBag)
        
        sortPopupDismissButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.dismissSortByPopup()
        }.disposed(by: disposeBag)
        
        switch viewModel.type {
        case .sameUser, .similar:
            tableView.rx.itemSelected
                .bind {[weak self] indexPath in
                    guard let strongSelf = self else { return }
                    strongSelf.showItineraryDetailPage(strongSelf.viewModel.suggestions.value[indexPath.row])
                }.disposed(by: disposeBag)
        case .user, .followingUser:
            tableView.rx.itemSelected
                .bind {[weak self] indexPath in
                    guard let strongSelf = self else { return }
                    strongSelf.tableView.deselectRow(at: indexPath, animated: true)
                    
                    let user = strongSelf.viewModel.userSuggestions.value[indexPath.row].user
                    let vm = ProfileDetailViewModel(user: user)
                    strongSelf.showUserProfilePage(vm)
                    
                }.disposed(by: disposeBag)        
        case .tag:
            tagCollectionView.rx.itemSelected
                .bind {[weak self] indexPath in
                    guard let strongSelf = self else { return }
                    // TODO
                    strongSelf.showSeeAllPage(SuggestionsViewModel(tagViewModel: TagViewModel(tag: (strongSelf.viewModel.tagSuggestions.value[indexPath.row]).tag.name)))
                    
                }.disposed(by: disposeBag)
            
        case .image:
            sortConfirmButton.rx.tap
                .bind{ [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.dismissSortByPopup()
                }.disposed(by: disposeBag)
            
            sortTableView.rx.itemSelected
                .bind {[weak self] indexPath in
                    guard let strongSelf = self else { return }
                    strongSelf.viewModel.tagViewModel.sortBy.accept(sortByOption[indexPath.row])
                    strongSelf.sortTableView.reloadData()
                    strongSelf.loadData(fromStart: true)
                }.disposed(by: disposeBag)
            
            tagCollectionView.rx.itemSelected
                .bind {[weak self] indexPath in
                    guard let strongSelf = self else { return }
                    let imageSuggestion = strongSelf.viewModel.tagViewModel.imageSuggestion.value[indexPath.row]
                    strongSelf.showItineraryDetailPage(ItineraryDetailViewModel(itinerary: imageSuggestion.itinerary))
                }.disposed(by: disposeBag)
            
        default: break
        }
    }
    
}

// MARK: - UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource
extension SeeAllViewController : UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.tagViewModel.imageSuggestion.value.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = (collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectionViewCell", for: indexPath) as? CollectionViewCell)!
        let storageRef = viewModel.storage.reference()
        let model = viewModel.tagViewModel.imageSuggestion.value[indexPath.row]
        cell.imagesViews?.first?.sd_setImage(with: storageRef.child(model.attachment.thumbnail), placeholderImage: nil, completion: { (image, error, cacheType, reference) in
            if image != nil {
                cell.imagesViews?.first?.image = image
            }
        })
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if viewModel.type == .image { return CGSize() }
        sizingCell.bindViewModel(viewModel.tagSuggestions.value[indexPath.row])
        let size = sizingCell.cellSize
        return CGSize(width: min(collectionView.width, size.width) , height: 30)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionView.elementKindSectionFooter {
            let sectionView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "TagFooterCollectionReusableView", for: indexPath) as! TagFooterCollectionReusableView
            sectionView.bindViewModel(viewModel.tagViewModel)
            sectionView.contentSizeDidChangeBlock = { [weak self] height in
                guard let strongSelf = self else { return }
                (strongSelf.tagCollectionView.collectionViewLayout as! UICustomCollectionViewLayout).footerHeight = height
                strongSelf.tagCollectionView.collectionViewLayout.invalidateLayout()
                
            }
            sectionView.seeAllDidChangeBlock = { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.showSeeAllPage(SuggestionsViewModel(itineraryViewModel: nil, type: .tag, isAll: true))
            }
            sectionView.relatedTagDidChangeBlock = { [weak self] vm in
                guard let strongSelf = self else { return }
                strongSelf.showSeeAllPage(SuggestionsViewModel(tagViewModel: TagViewModel(tag: vm.tag.name)))
            }
            sectionView.isHidden = isFirst
            isFirst = false
            return sectionView
        } else {
            let sectionView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "TagHeaderCollectionReusableView", for: indexPath) as! TagHeaderCollectionReusableView
            sectionView.bindViewModel(viewModel.tagViewModel.model)
            
            sectionView.sortButtonDidClickBlock = { [weak self] in
                guard let strongSelf = self else { return }
                self?.showSortPopup(strongSelf.viewModel, completionBlock: { [weak self] in
                    self?.loadData()
                })
            }            
            return sectionView
        }
        
    }
}

// MARK: - CustomLayoutDelegate
extension SeeAllViewController: CustomLayoutDelegate{
    func collectionView(_ collectionView: UICollectionView, heightForItemAt indexPath: IndexPath, with width: CGFloat) -> CGFloat {
        return CGFloat((viewModel.tagViewModel.imageSuggestion.value[indexPath.row]).imageHeight.height)
    }
}
