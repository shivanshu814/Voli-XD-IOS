//
//  SettingViewController.swift
//  PineApple
//
//  Created by Tao Man Kit on 16/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class SettingViewController: BaseViewController, ViewModelBased {

    // MARK: - Properties
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    var viewModel: SettingViewModel!    
    let footerHeight: CGFloat = 190
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        if viewModel == nil {
            viewModel = SettingViewModel(model: Globals.currentUser!)
        }
        configureTableView()
        configureNavigationBar()
        bindViewModel(viewModel)
        bindAction()
    }
   
}

// MARK: - RX
extension SettingViewController {
    
    func bindViewModel(_ viewModel: SettingViewModel) {
        
        viewModel.notificationSetting
            .asObservable()
            .bind {[weak self] _ in
                self?.tableView.reloadData()
                DispatchQueue.main.asyncAfter(deadline: .now()+0.1, execute: {
                    self?.updateFooterHeightIfNeeded()
                })
            }.disposed(by: disposeBag)
        
        cancelButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.navigationController?.popViewController(animated: true)
        }.disposed(by: disposeBag)
        
        saveButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.showLoading()
                strongSelf.viewModel.save {[weak self] (result, error) in
                    strongSelf.stopLoading()
                    if let error = error {
                        self?.showAlert(title: "Error", message: error.localizedDescription)
                    }
                }
        }.disposed(by: disposeBag)
    }
    
    func bindAction() {
        logoutButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                
                let defaultAction = UIAlertAction(title: "Sure",
                                                  style: .default) {[weak self] (action) in
                                                    guard let strongSelf = self else { return }
                                                    PushNotificationManager.shared.removeFirestorePushToken()
                                                    ProfileDetailViewModel.logout()
                                                    
                                                    if Globals.rootViewController.presentedViewController != nil {
                                                        strongSelf.dismiss(animated: true, completion: nil)
                                                    } else {
                                                        strongSelf.navigationController?.popToRootViewController(animated:  true)
                                                    }
                                                    
                                                    
                }
                let cancelAction = UIAlertAction(title: "Cancel",
                                                 style: .cancel) { (action) in }
                
                let alert = UIAlertController(title: "",
                                              message: "Are you sure to logout?",
                                              preferredStyle: .alert)
                alert.addAction(defaultAction)
                alert.addAction(cancelAction)
                strongSelf.present(alert, animated: true) {}               
            }.disposed(by: disposeBag)
    }
}

// MARK: - Private
extension SettingViewController {
    private func configureNavigationBar() {
        addBackButton()
        title = "Settings"
    }
    
    private func configureTableView() {
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 78, right: 0)
    }
    
    private func updateFooterHeightIfNeeded() {
        let offsetY = view.frame.height - (tableView.frame.origin.y + (tableView.contentSize.height - tableView.tableFooterView!.frame.height + footerHeight))
        var rect = tableView.tableFooterView!.frame
        if offsetY > 0 {
            rect.size.height = footerHeight + offsetY
        } else {
            rect.size.height = footerHeight
        }
        tableView.tableFooterView!.frame = rect
    }
}

// MARK: - UITableViewDataSource
extension SettingViewController : UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? viewModel.privacySetting.value.count : viewModel.notificationSetting.value.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingTableViewCell", for: indexPath) as! SettingTableViewCell
        if indexPath.section == 0 {
            cell.bindViewModel(viewModel.privacySetting.value[indexPath.row])
        } else {
            cell.bindViewModel(viewModel.notificationSetting.value[indexPath.row])
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let nib = UINib.init(nibName: "SettingHeaderView", bundle: nil)
        let headerView = nib.instantiate(withOwner: nil, options: nil).first as? SettingHeaderView
        headerView?.titleLabel.text = section == 0 ? "Privacy" : "Notifications"
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 19 + 32
    }
    
}

