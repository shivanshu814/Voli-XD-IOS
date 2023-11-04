//
//  BaseViewController.swift
//  PineApple
//
//  Created by Tao Man Kit on 19/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class BaseViewController: UIViewController, UIGestureRecognizerDelegate {
    
    // MARK: - Properties
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
            #selector(self.handleRefresh(_:)),
                                 for: UIControl.Event.valueChanged)
        return refreshControl
    }()
    
    let footerView = TableFooterView.instance
    var disposeBag = DisposeBag()

}

// MARK: - View Life Cycle
extension BaseViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureSwipeToBack()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        configureSwipeToBack()
        cleanDisposeBagIfNeeded()
    }
    
}

// MARK: - Private
extension BaseViewController {
    
    private func cleanDisposeBagIfNeeded() {
        if navigationController == nil {
            disposeBag = DisposeBag()
        }
    }
    
    private func configureSwipeToBack() {
        guard self.navigationController != nil else { return }
        
        if let vcs = self.navigationController?.viewControllers, (vcs.count == 1 ||
                (vcs.count >= 2 && (vcs[vcs.count-2] is SignInViewController ||
                vcs[vcs.count-2] is WelcomeViewController  ||
                vcs[vcs.count-2] is CreateProfileViewController))) {
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        } else {
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }
    }
}

// MARK: - PullDownToRefresh
extension BaseViewController {
    func pullDownToRefresh(_ scrollView: UIScrollView) {
        refreshControl.beginRefreshing()
        UIView.animate(withDuration: 0.3) {
            scrollView.contentOffset = CGPoint(x: 0, y: -50)
        }
    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        print("please implement!!!")
    }
}

// MARK: - LoadMore
extension BaseViewController {
    
    func setupLoadMore(paging: Paging) {
        paging.isMore
            .asObservable()
            .bind {[weak self] (isMore) in
                self?.setIsMore(isMore)
        }.disposed(by: disposeBag)
    }

    func setIsMore(_ isMore: Bool) {
        footerView.loadMoreButton.isHidden = !isMore
        footerView.noMoreResultLabel.isHidden = isMore
    }
    
    func startAnimatingLoadMore() {
        footerView.loadMoreButton.isHidden = true
        footerView.activityIndicatorView.startAnimating()
    }
    
    func stopAnimatingLoadMore() {
        footerView.activityIndicatorView.stopAnimating()
    }
    
    func showFooterView() {
        footerView.isHidden = false
    }
}

