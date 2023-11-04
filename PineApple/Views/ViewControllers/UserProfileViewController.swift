//
//  UserProfileViewController.swift
//  PineApple
//
//  Created by Tao Man Kit on 12/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import ViewAnimator

class UserProfileViewController: BaseViewController, ViewModelBased, KeyboardOverlayAvoidable {

    // MARK: - Properties
    fileprivate enum SegueIdentifier: String {
        case settingSegue = "SettingSegue"
    }
    @IBOutlet weak var tableView: UITableView!
    var viewModel: ProfileDetailViewModel!    
    var keyboardHeight: CGFloat = 0
    var keyboardDidShowBlock: (() -> Void)?
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        if viewModel == nil {
            viewModel = ProfileDetailViewModel(user: Globals.currentUser!)
        }
        configureNavigationbar()
        footerView.setup(self, disposeBag: disposeBag, showRelatedTag: false)
        configureTableView()
        addKeyboardNotification()
        bindViewModel(viewModel)        
        bindAction()
        
        NotificationCenter.default.addObserver(forName: .didUserDidUpdated, object: nil, queue: .main) {[weak self] notification in
            guard let strongSelf = self else { return }
            let model = strongSelf.viewModel.model
            if let user = notification.userInfo?["user"] as? User, user == model.model {
                model.setup(with: user)
                strongSelf.viewModel.setup(with: model)
            }
        }
        
        NotificationCenter.default.addObserver(forName: .didItineraryDidUpdated, object: nil, queue: .main) {[weak self] notification in
            if let itinerary = notification.userInfo?["itinerary"] as? Itinerary {
                self?.viewModel.refresh(itinerary)
            }
        }
          
        viewModel.fetchMyItineraries {[weak self] (result, error) in
          guard let strongSelf = self else { return }
            if result {
                if strongSelf.viewModel.rows.value.count >= 2 {
                    strongSelf.viewModel.updateRows()
                }
            }
        }
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)        
        loadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - RX
extension UserProfileViewController {
    
    func bindViewModel(_ viewModel: ProfileDetailViewModel) {
        setupLoadMore(paging: viewModel.paging)
                
        viewModel.isOwner
            .asObservable()
            .bind {[weak self] (isOwner) in
                self?.title = isOwner ? "My profile" : "User profile"
            }.disposed(by: disposeBag)
        
        viewModel.rows
            .asObservable()
            .bind {[weak self] (rows) in
                guard let strongSelf = self else { return }
                strongSelf.tableView.reloadData()
                strongSelf.footerView.isHidden = false
                return
        }.disposed(by: disposeBag)
    }

    func bindAction() {
        tableView.rx.itemSelected
            .bind {[weak self] indexPath in
                guard let strongSelf = self else { return }
                
                strongSelf.tableView.deselectRow(at: indexPath, animated: true)
                if let vm = strongSelf.viewModel.rows.value[indexPath.row] as? ItineraryDetailViewModel {                    strongSelf.showItineraryDetailPage(vm)
                }
            }.disposed(by: disposeBag)
        
        footerView.loadMoreButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.startAnimatingLoadMore()
                strongSelf.viewModel.fetchMyItineraries { [weak self] (result, error) in
                    self?.stopAnimatingLoadMore()
                    if let error = error {
                        self?.showAlert(title: "Error", message: error.localizedDescription)
                    } else {
                        self?.viewModel.updateRows()
                    }
                }
        }.disposed(by: disposeBag)
    }
}

// MARK: - Private
extension UserProfileViewController {
    
    private func loadData() {
        showLoading()
        viewModel.fetchUserProfile {[weak self] (result, error) in
            self?.stopLoading()
            if let error = error {
                self?.showAlert(title: "Error", message: error.localizedDescription)
            } else {
                self?.viewModel.updateRows()
            }
        }
    }
    
    private func configureTableView() {
        tableView.register(nibWithCellClass: ItineraryTableViewCell.self)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 78, right: 0)
        tableView.tableFooterView = footerView
        tableView.dataSource = self
    }
    
    func configureNavigationbar() {
        if let vcs = navigationController?.viewControllers {
            if vcs.count == 1 || (vcs.count >= 2 && (vcs[vcs.count-2] is SignInViewController || vcs[vcs.count-2] is WelcomeViewController  || vcs[vcs.count-2] is CreateProfileViewController))  {                
                addCloseButton()
            } else {
                addBackButton()
            }
        }
        
        addMoreButton()
    }
    
    override func showActionSheet() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let shareProfileAction = UIAlertAction(title: viewModel.user?.id == Globals.currentUser?.id ? "Share my profile link" : "Share profile link",
                                          style: .default) {[weak self] (action) in
                                            guard let strongSelf = self else { return }
                                                                                        
                                            if let id = strongSelf.viewModel.user?.id, let displayName = strongSelf.viewModel.user?.displayName {
                                                Globals.generateDynamicLink(type: .profile, id: id) {[weak self] (url) in
                                                    if let url = url {
                                                        self?.showShareActionSheet(url: url, title: displayName, type: "profile")
                                                    }
                                                }
                                            }
        }
        
        let inviteAction = UIAlertAction(title: "Invite friends to Voli",
                                                   style: .default) {[weak self] (action) in
                                                    guard let strongSelf = self else { return }
                                                    let items = [URL(string: "https://itunes.apple.com/us/app/apple-store/id1480514902?mt=8")!]
                                                    let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
                                                    strongSelf.present(ac, animated: true)
        }
                
        let reportAbuseAction = UIAlertAction(title: "Report abuse",
                                                   style: .default) {[weak self] (action) in
                                                    guard let strongSelf = self else { return }
                                                    strongSelf.viewModel.reportAbuse {[weak self] (result, error) in
                                                        if let error = error {
                                                            self?.showAlert(title: "Error", message: error.localizedDescription)
                                                        } else {
                                                            self?.showSnackbar("Report successfully")
                                                        }
                                                    }
                                                    
        }
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel) { (action) in }
        
        if viewModel!.isOwner.value {
            //            alertController.addAction(logoutAction)
        } else {
            alertController.addAction(reportAbuseAction)
        }
        alertController.addAction(shareProfileAction)
        alertController.addAction(inviteAction)
        
        
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource
extension UserProfileViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rows.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = indexPath.row
        let element = viewModel.rows.value[index]
        if (element as? Int) == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileHeaderTableViewCell", for: IndexPath(row: index, section: 0)) as! ProfileHeaderTableViewCell
            cell.bindViewModel(viewModel)
            cell.tagDoneDidClickBlock = {[weak self] in
                self?.dismissKeyboard()
            }
            cell.aboutTextView.addInputAccessoryView(with: self, doneAction: #selector(self.dismissKeyboard))
            cell.contentSizeDidChangeBlock = {[weak self] in
                UIView.setAnimationsEnabled(false)
                self?.tableView.beginUpdates()
                self?.tableView.endUpdates()
                UIView.setAnimationsEnabled(true)
            }
            
            cell.editProfileDidClickBlock = { [weak self] in
                guard let strongSelf = self else { return }
                if !strongSelf.showNoPermissionViewIfNeeded() {
                    strongSelf.showUpdateProfilePage(with: strongSelf.viewModel.model)
                    
                }
            }
            
            cell.settingDidClickBlock = { [weak self] in
                guard let strongSelf = self else { return }
                self?.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
                strongSelf.performSegue(withIdentifier: SegueIdentifier.settingSegue.rawValue, sender: nil)
            }
            cell.messageDidClickBlock = { [weak self] user in
                guard let strongSelf = self else { return }
                strongSelf.messageButtonDidClicked(user)
            }
            return cell
        } else if (element as? Int) == 2 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "FollowedUserTableViewCell", for: IndexPath(row: index, section: 0)) as! FollowedUserTableViewCell
            cell.bindViewModel(viewModel)
            
            cell.seeAllDidClickBlock = { [weak self] in
                guard let strongSelf = self else { return }
                if let user = strongSelf.viewModel!.model.model {
                    self?.showFollowingUserPage(user)                    
                }
            }
            cell.itemDidClickBlock = { [weak self] vm in
                self?.showUserProfilePage(vm)
            }
            return cell
        } else if (element as? Int) == 3 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MyItinerariesHeaderView", for: IndexPath(row: index, section: 0)) as! TableViewCell
            cell.labels?.first?.text = viewModel.isOwner.value ? "My itineraries" : "Itineraries by " + viewModel.name.value
            cell.labels?.last?.isHidden = !viewModel.itineraries.value.isEmpty
            cell.labels?.last?.text = viewModel.isOwner.value ? "Your first itinerary is going to be amazing. All itineraries you create will appear here." : "\(viewModel.model.model?.displayName ?? "") hasn’t published any public itineraries yet."
            footerView.isHidden = viewModel.itineraries.value.isEmpty
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
    }
    
}

