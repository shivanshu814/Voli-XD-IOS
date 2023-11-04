//
//  ItineraryDetailViewController.swift
//  PineApple
//
//  Created by Tao Man Kit on 28/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import Hero
import RxCocoa
import RxSwift
import AVKit

class ItineraryDetailViewController: BaseViewController, ViewModelBased {

    // MARK: - Properties    
    fileprivate enum SegueIdentifier: String {
        case mapSegue = "MapSegue"
    }
        
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var editButton: UIButton!

    var viewModel: ItineraryDetailViewModel!
    var isFirst = true    
    var isJustCreated = false
    var avplayer: AVPlayer?
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureAudioSession()
        configureTableView()
        configureNavigationBar()
        configureBottomView()
        bindViewModel(viewModel)
        bindAction()
        
        NotificationCenter.default.addObserver(forName: .didItineraryDidUpdated, object: nil, queue: .main) {[weak self] notification in
            guard let strongSelf = self else { return }
            if let itinerary = notification.userInfo?["itinerary"] as? Itinerary, itinerary == strongSelf.viewModel.model.model {
                if itinerary.isDeleted {
                    strongSelf.showLoading()
                    if let vcs = strongSelf.navigationController?.viewControllers, vcs.count > 1 {
                        if let vc = strongSelf.navigationController?.viewControllers.first as? CreateItineraryViewController {
                            vc.viewModel.reset()
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now()+0.6) {
                            self?.navigationController?.popViewController(animated: true)
                            strongSelf.stopLoading()
                        }
                    } else {
                        self?.dismiss(animated: true, completion: nil)
                    }
                } else {
                    if itinerary.commentCount != strongSelf.viewModel.itinerary.commentCount {
                        strongSelf.viewModel.getFirstComment()
                    }
                    self?.viewModel.model.setup(with: itinerary)
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
                
        disableSwipeToBackIfNeeded()
        if isFirst {
            isFirst = false
            viewModel.loadData {[weak self] (result, error) in
                if let error = error {
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        } else {
            // reload user section
            let userIndexPath = IndexPath(row: viewModel.rows.value.count - 1, section: 0)
            tableView.reloadRows(at: [userIndexPath], with: .none)
        }
        
        if isJustCreated {
            showSnackbar("Your itinerary is now \(viewModel.itinerary.isPrivate ? "private." : "public.")")
            isJustCreated = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isHidden = false
        avplayer?.pause()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier.flatMap(SegueIdentifier.init) else { return }
        
        switch identifier {
        case .mapSegue:
            if let index = sender as? Int {
                let destinationViewController = segue.destination as! UINavigationController
                destinationViewController.hero.isEnabled = true
                destinationViewController.hero.modalAnimationType = .push(direction: .left)
                let mapViewController = destinationViewController.viewControllers.first as! MapViewController
                mapViewController.viewModel = MapViewModel(itineraryViewModel: viewModel.model, selectedActivityIndex: index, isEditing: false)
                destinationViewController.modalPresentationStyle = .fullScreen
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}

// MARK: - RX
extension ItineraryDetailViewController {
    
    func bindViewModel(_ viewModel: ItineraryDetailViewModel) {
        
        viewModel.rows
        .bind(to: tableView.rx.items) { tableView, index, element in
            let indexPath = IndexPath(row: index, section: 0)
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ItineraryDetailTableViewCell", for: indexPath) as! ItineraryDetailTableViewCell
                cell.bindViewModel(viewModel)
                if Globals.currentUser?.followingUserIds.contains(viewModel.itinerary.user.id) ?? false {
                    viewModel.showContact.accept(true)
                }
                if self.navigationItem.hidesBackButton {
                    cell.showCloseButton()
                }
                cell.contactButtonDidClickBlock = { [weak self] user in
                    self?.messageButtonDidClicked(user)                    
                }
                cell.attachmentDidClickBlock = { [weak self] (attachmentViewModels, image, player, indexPath) in
                    guard let strongSelf = self else { return }
                    if player != nil {
                        strongSelf.avplayer = player
                        player!.pause()
                        player!.isMuted = false
                        let controller = AVPlayerViewController()
                        NotificationCenter.default.addObserver(strongSelf, selector: #selector(strongSelf.avPlayerClosed), name: Notification.Name("avPlayerDidDismiss"), object: nil)
                        
                        controller.player = player!
                        strongSelf.present(controller, animated: true) {
                           DispatchQueue.main.async {
                             player?.play()
                           }
                        }
                    } else {
                        let _vc = UIStoryboard(name: "ImageViewer", bundle: nil).instantiateInitialViewController() as! UINavigationController
                        let vc = _vc.viewControllers.first as! ImageViewController
                        vc.image = image
                        var activity = Activity()
                        activity.attachments = attachmentViewModels.map{$0.attachment}
                        vc.viewModel = ActivityViewModel(activity: activity)
                        vc.selectedIndex = IndexPath(row: indexPath.row, section: 0)
                        vc.view.backgroundColor = UIColor.black
                        vc.collectionView!.backgroundColor = UIColor.black
                        _vc.hero.isEnabled = true
                        _vc.modalPresentationStyle = .fullScreen
                        strongSelf.present(_vc, animated: true, completion: nil)
                        
                    }
                }
                cell.backButtonDidClickBlock = { [weak self] in
                    guard let strongSelf = self else { return }
                    if strongSelf.navigationItem.hidesBackButton {
                        if let vc = strongSelf.navigationController?.viewControllers.first as? CreateItineraryViewController {
                            
                            vc.viewModel.reset()
                            strongSelf.navigationController?.popViewController(animated: true)
                        }
                    } else {
                        self?.navigationController?.popViewController(animated: true)
                    }
                }
                cell.tagDidClickBlock = { [weak self] tag in
                    self?.showSeeAllPage(SuggestionsViewModel(tagViewModel: TagViewModel(tag: tag)))
                }
                cell.profileDidClickBlock = {[weak self] user in
                    self?.showUserProfilePage(ProfileDetailViewModel(user: user))
                }
                cell.saveDidClickBlock = {[weak self] vm in
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
            } else if viewModel.rows.value[indexPath.row] is ActivityViewModel {
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "ItineraryDetailActivityTableViewCell", for: indexPath) as! ItineraryDetailActivityTableViewCell
                cell.bindViewModel(viewModel.rows.value[indexPath.row] as! ActivityViewModel)
                cell.numberLabel.text = String(indexPath.row)
                cell.attachmentDidClickBlock = { [weak self] (activityViewModel, image, indexPath) in
                    guard let strongSelf = self else { return }
                    let _vc = UIStoryboard(name: "ImageViewer", bundle: nil).instantiateInitialViewController() as! UINavigationController
                    let vc = _vc.viewControllers.first as! ImageViewController
                    vc.image = image
                    vc.viewModel = activityViewModel
                    vc.selectedIndex = activityViewModel.attachments.value[indexPath.row].indexPath
                    vc.view.backgroundColor = UIColor.black
                    vc.collectionView!.backgroundColor = UIColor.black
                    _vc.hero.isEnabled = true
                    _vc.modalPresentationStyle = .fullScreen
                    strongSelf.present(_vc, animated: true, completion: nil)
                }
                
                cell.locationDidClickBlock = { [weak self] vm in
                    guard let strongSelf = self else { return }
                    let index = strongSelf.viewModel.model.activityViewModels.firstIndex(of: vm)
                    self?.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
                    self?.performSegue(withIdentifier: SegueIdentifier.mapSegue.rawValue, sender: index)
                }
                return cell
            } else if let item = viewModel.rows.value[indexPath.row] as? SuggestionsViewModel {
                switch item.type {
                case .sameUser, .similar:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "SuggestionTableViewCell", for: indexPath) as! SuggestionTableViewCell
                    cell.bindViewModel(item)
                    cell.suggestionDidClickBlock = { [weak self] vm, indexPath in
                        guard let strongSelf = self else { return }
                        strongSelf.showItineraryDetailPage(vm)
                    }
                    cell.seeAllDidClickBlock = { [weak self] vm in
                        guard let strongSelf = self else { return }
                        strongSelf.showSeeAllPage(vm)
                    }
                    return cell
                case .user:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "RecommendedUserTableViewCell", for: indexPath) as! RecommendedUserTableViewCell
                    cell.bindViewModel(item)
                    cell.seeAllDidClickBlock = { [weak self] vm in
                        guard let strongSelf = self else { return }
                        strongSelf.showSeeAllPage(vm)
                    }
                    cell.userDidClickBlock = { [weak self] vm in
                        guard let strongSelf = self else { return }
                        strongSelf.showUserProfilePage(vm)
                    }
                    return cell
                default:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "RecommendedTagTableViewCell", for: indexPath) as! RecommendedTagTableViewCell
                    cell.bindViewModel(item)
                    cell.contentSizeDidChangeBlock = {[weak self] in
                        self?.tableView.update()
                    }
                    cell.seeAllDidClickBlock = { [weak self] vm in
                        guard let strongSelf = self else { return }
                        strongSelf.showSeeAllPage(vm)
                    }
                    cell.tagDidClickBlock = { [weak self] tag in
                        guard let strongSelf = self else { return }
                        strongSelf.showSeeAllPage(SuggestionsViewModel(tagViewModel: TagViewModel(tag: tag)))
                    }
                    return cell
                }
                
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ItineraryDetailActivityFooterTableViewCell", for: indexPath) as! ItineraryDetailActivityFooterTableViewCell
                cell.bindViewModel(viewModel)
                cell.commentDidClickBlock = { [weak self] vm in
                    guard let strongSelf = self else { return }
                    strongSelf.showCommentPage(CommentViewModel(model: vm))
                }
                
                cell.itineraryDidSaveBlock = { [weak self] vm in
                    guard let strongSelf = self else { return }
                    if !vm.model.isSave.value {
                        strongSelf.showSavedCollectionPopup(vm) {
                            strongSelf.showSnackbar("Itinerary is saved.")
                        }
                    } else {
                        vm.unsave { (result, error) in
                            if let error = error {
                                strongSelf.showAlert(title: "Error", message: error.localizedDescription)
                            } else {
                                strongSelf.showSnackbar("Itinerary is unsaved.")
                            }
                        }
                    }
                }
                
                cell.contentSizeDidChangeBlock = {[weak self] in
                    self?.tableView.update()
                }
                cell.viewCommentDidSaveBlock = {[weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.showCommentPage(CommentViewModel(model: strongSelf.viewModel))
                }
                return cell
            }
        }.disposed(by: disposeBag)
        
        footerView.bindTags(viewModel.recommendedTags.tagSuggestions)
    }
    
    func bindAction() {
        
        saveButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                if !strongSelf.showNoPermissionViewIfNeeded() {
                    if let vm = strongSelf.viewModel {
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
                }
        }.disposed(by: disposeBag)
        
        shareButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                let id = strongSelf.viewModel.itinerary.id
                Globals.generateDynamicLink(type: .itinerary, id: id) {[weak self] (url) in
                    if let url = url {
                        self?.showShareActionSheet(url: url, title: strongSelf.viewModel.itinerary.title, type: "itinerary")
                    }
                }
        }.disposed(by: disposeBag)
        
        editButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.isFirst = true
                strongSelf.showEditPage()
        }.disposed(by: disposeBag)
        
    }
    
}

// MARK: - Notification
extension ItineraryDetailViewController {
    @objc func avPlayerClosed(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {[weak self] in
            self?.avplayer?.isMuted = true
            self?.avplayer?.play()
        }
    }
}

// MARK: - Private
extension ItineraryDetailViewController {

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: .default, options: .mixWithOthers) //For playing volume when phone is on silent
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func configureBottomView() {
        if viewModel.isOwner {
            saveButton.isHidden = true
            shareButton.backgroundColor = saveButton.backgroundColor
            shareButton.setImage(#imageLiteral(resourceName: "share-white"), for: .normal)
            shareButton.setTitleColor(UIColor.white, for: .normal)
            editButton.isHidden = false
        } else {
            editButton.isHidden = true
        }
    }
    
    private func configureTableView() {
        tableView.register(nibWithCellClass: SuggestionTableViewCell.self)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.estimatedRowHeight = 310
        tableView.tableFooterView = footerView
        footerView.showLoadMore = false
        footerView.setup(self, disposeBag: disposeBag)
        footerView.isHidden = false
    }
    
    private func showEditPage() {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withClass: CreateItineraryViewController.self) {
            vc.viewModel = ItineraryViewModel(itinerary: viewModel.model.model, isEditing: true)
            vc.editFinishedBlock = { [weak self] itinerary in
                self?.viewModel.setup(with: ItineraryViewModel(itinerary: itinerary))
                self?.showSnackbar("Your changes are saved.")                
            }
            let navCtrl = UINavigationController(rootViewController: vc)
            navCtrl.modalPresentationStyle = .fullScreen
            present(navCtrl, animated: true, completion: nil)
        }
    }
    
    private func configureNavigationBar() {
        title = "Itinerary"
        addProfileButton()

        if let vcs = navigationController?.viewControllers {
            if vcs.count > 1 && !(vcs[vcs.count-2] is CreateItineraryViewController) {
//                addBackButton(true)
            } else if vcs.count == 1 {
//                addCloseButton()
            } else {
                navigationItem.hidesBackButton = true
                navigationController?.interactivePopGestureRecognizer?.isEnabled = false
            }
        }
    }
    
    private func disableSwipeToBackIfNeeded() {
        if navigationItem.hidesBackButton {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        }
    }
    
}
