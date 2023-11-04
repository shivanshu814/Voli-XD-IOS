//
//  NoPermissionView.swift
//  PineApple
//
//  Created by Tao Man Kit on 9/10/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import UIKit
import RxCocoa
import RxSwift

// MARK: - Properties
class NoPermissionView: UIView {

    // MARK: - Properties
    @IBOutlet weak var blurView: UIView!
    @IBOutlet weak var createProfileButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var browseButton: UIButton!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var yesButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    weak var superViewController: UIViewController!
    private let disposeBag = DisposeBag()
    
    // MARK: - View Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        bindAction()
    }

}

// MARK: - RX
extension NoPermissionView {
    
    func bindAction() {
        
        titleLabel.text = UserDefaults.standard.value(forKey: "isLogined") == nil ? "You need to create a profile first" : "You need to be signed in first"
        
        yesButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }                
                strongSelf.superViewController.showUserProfileLandingPage()
                Globals.rootViewController.fadeOutPopup()
        }.disposed(by: disposeBag)
        
        cancelButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.dismissButton.sendActions(for: .touchUpInside)
        }.disposed(by: disposeBag)
        
    }
    
}
