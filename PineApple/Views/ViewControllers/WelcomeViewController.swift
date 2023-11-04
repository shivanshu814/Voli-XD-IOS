//
//  WelcomeViewController.swift
//  PineApple
//
//  Created by Tao Man Kit on 12/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class WelcomeViewController: UIViewController {

    // MARK: - Properties
    @IBOutlet weak var exploreButton: UIButton!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var profileButton: UIButton!
    private let disposeBag = DisposeBag()
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationbar()        
        bindAction()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now()+2) { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isHidden = false
    }

}

// MARK: - Private
extension WelcomeViewController {
    
    private func configureNavigationbar() {
        title = "Create profile"
        navigationController?.navigationBar.isHidden = true
        navigationItem.leftBarButtonItem = nil
        navigationItem.hidesBackButton = true
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
}


// MARK: - RX
extension WelcomeViewController {
    
    func bindAction() {
        exploreButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.dismiss(animated: true, completion: nil)
            }.disposed(by: disposeBag)
        
        createButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                Globals.rootViewController.setSelectIndex(from: Globals.rootViewController.selectedIndex, to: 2)
                strongSelf.dismiss(animated: true, completion: nil)
            }.disposed(by: disposeBag)
        
        profileButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                
                strongSelf.showUserProfilePage(ProfileDetailViewModel(user: Globals.currentUser!))
                
            }.disposed(by: disposeBag)
    }
    
}
