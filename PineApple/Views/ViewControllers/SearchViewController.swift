//
//  SearchViewController.swift
//  PineApple
//
//  Created by Tao Man Kit on 14/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class SearchViewController: BaseViewController, ViewModelBased {
    
    // MARK: - Properties
    fileprivate enum SegueIdentifier: String {
        case pageSegue = "PageSegue"
    }
    var titleView: UIView!
    var searchTextField: UITextField!
    var clearButton: UIButton!
    @IBOutlet var switchButtonCollection: [UIButton]!
    @IBOutlet var selectedViewCollection: [UIView]!
    @IBOutlet weak var scopeBarView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchTableView: UITableView!
    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var scopeBarViewTop: NSLayoutConstraint!
    private var pageViewController: UIPageViewController!
    private var pageViewControllers = [SearchResultViewController]()
    private var currentPage = 0
    private var transitionInProgress = false
    private var transitionAnimated = true
    private var shouldShowSearch = true
    var viewModel: SearchViewModel!
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        if viewModel == nil {
            viewModel = SearchViewModel()
        }
        configurePageViewController()
        configureNavigationBar()
        configureTableView()
        bindViewModel(viewModel)
        bindAction()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showLoading()
        viewModel.searchPopularUsers()
        viewModel.searchPopularItineraries()
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier.flatMap(SegueIdentifier.init) else { return }
        
        switch identifier {
        case .pageSegue:
            pageViewController = segue.destination as? UIPageViewController
            pageViewController.delegate = self
            pageViewController.dataSource = self
        }
    }
}

// MARK: - RX
extension SearchViewController {
    
    func bindViewModel(_ viewModel: SearchViewModel) {
        self.viewModel = viewModel
        
        Observable.combineLatest(viewModel.popularUsers, viewModel.popularItineraries)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] (_) in
                self?.stopLoading()
            }).disposed(by: disposeBag)
        
        
        searchTextField.rx.text
            .orEmpty
            .throttle(0.6, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .bind(to: viewModel.keyword)
            .disposed(by: disposeBag)
        
        viewModel.keyword
            .asObservable()
            .bind {[weak self] (keyword) in
                guard let strongSelf = self else { return }
                if !strongSelf.shouldShowSearch {
                    strongSelf.shouldShowSearch = true
                    return
                    
                }
                if !keyword.isEmpty {
                    strongSelf.enableSearchMode(true)
                    strongSelf.viewModel.fetchKeywords()
                } else {
                    strongSelf.enableSearchMode(false)
                    
                }
                
        }.disposed(by: disposeBag)
        
        viewModel.suggestKeywords
            .bind(to: searchTableView.rx.items(cellIdentifier: "keywordsTableViewCell", cellType: TableViewCell.self)) { (row, element, cell) in
                cell.labels?.first?.text = element
        }.disposed(by: disposeBag)
        
        Observable.combineLatest(viewModel.popularUsers, viewModel.popularItineraries)
            .asObservable()
            .observeOn(MainScheduler.instance)
            .bind {[weak self] (_) in
                self?.tableView.reloadData()
        }.disposed(by: disposeBag)
    }
    
    func bindAction() {
        clearButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.enableResultView(false)
                strongSelf.searchTextField.text = ""
                strongSelf.searchTextField.resignFirstResponder()
            }.disposed(by: disposeBag)
        
        searchTableView.rx.itemSelected
            .bind {[weak self] indexPath in
                guard let strongSelf = self else { return }
                strongSelf.searchTableView.deselectRow(at: indexPath, animated: true)
                let keyword = strongSelf.viewModel.suggestKeywords.value[indexPath.row]
                strongSelf.shouldShowSearch = false
                strongSelf.searchTextField.text = keyword
                strongSelf.viewModel.search(keyword)
                strongSelf.searchTextField.resignFirstResponder()
                strongSelf.enableSearchMode(false)
                strongSelf.enableResultView(true)
                strongSelf.showFirstTab()
            }.disposed(by: disposeBag)
        
        tableView.rx.itemSelected
        .bind {[weak self] indexPath in
            guard let strongSelf = self else { return }
            strongSelf.tableView.deselectRow(at: indexPath, animated: true)
            if indexPath.section == 0 {
                let element = strongSelf.viewModel.popularUsers.value[indexPath.row]
                let vm = ProfileDetailViewModel(user: element.user)
                strongSelf.showUserProfilePage(vm)
            } else {
                let element = strongSelf.viewModel.popularItineraries.value[indexPath.row]
                strongSelf.showItineraryDetailPage(element)
            }
            
        }.disposed(by: disposeBag)
    }
}

// MARK: - Private
extension SearchViewController {
    
    func enableResultView(_ isEnable: Bool) {
        scopeBarViewTop.constant = isEnable ? 8 : -52
        containerView.isHidden = !isEnable
    }
    
    func enableSearchMode(_ isEnable: Bool) {
        if !isEnable {
            searchTableView.isHidden = true
        } else {
            searchTableView.isHidden = false
        }
    }
    
    func configurePageViewController() {
        let storyboard = UIStoryboard(name: "Search", bundle: nil)
        
        let allSearchResultViewController = storyboard.instantiateViewController(withIdentifier: "SearchResultViewController") as! SearchResultViewController
        allSearchResultViewController.viewModel = SearchResultViewModel(model: viewModel, type: .all)
        pageViewControllers.append(allSearchResultViewController)
        
        let userSearchResultViewController = storyboard.instantiateViewController(withIdentifier: "SearchResultViewController") as! SearchResultViewController
        userSearchResultViewController.viewModel = SearchResultViewModel(model: viewModel, type: .user)
        pageViewControllers.append(userSearchResultViewController)
        
        let itinerarySearchResultViewController = storyboard.instantiateViewController(withIdentifier: "SearchResultViewController") as! SearchResultViewController
        itinerarySearchResultViewController.viewModel = SearchResultViewModel(model: viewModel, type: .itinerary)
        pageViewControllers.append(itinerarySearchResultViewController)
        
        let tagSearchResultViewController = storyboard.instantiateViewController(withIdentifier: "SearchResultViewController") as! SearchResultViewController
        tagSearchResultViewController.viewModel = SearchResultViewModel(model: viewModel, type: .tag)
        pageViewControllers.append(tagSearchResultViewController)
        
        pageViewController.setViewControllers([allSearchResultViewController], direction: .forward, animated: false, completion: nil)
    }
    
    func updateSwitchButtons(with selectedIndex: Int) {
        
        func update(_ index: Int, isSelected: Bool) {
            selectedViewCollection[index].alpha = isSelected ? 1 : 0
            switchButtonCollection[index].isSelected = isSelected
        }
        
        func setSelectedIndex(_ index: Int) {
            update(0, isSelected: index == 0)
            update(1, isSelected: index == 1)
            update(2, isSelected: index == 2)
            update(3, isSelected: index == 3)
        }
        
        setSelectedIndex(selectedIndex)
        searchTextField.resignFirstResponder()
    }
    
    private func configureNavigationBar() {
        titleView = UIView(frame: CGRect(x: 16, y: 0, width: view.bounds.width-32, height: 36))
        
        searchTextField = UITextField(frame: CGRect(x: 0, y: 0, width: titleView.bounds.width-50, height: 36))
        searchTextField.placeholder = "Search for people, itineraries and tags"
        searchTextField.font = Styles.customFontLight(15)
        searchTextField.textColor = Styles.g504F4F
        searchTextField.setPlaceHolderTextColor(Styles.g888888)
        searchTextField.delegate = self
        searchTextField.returnKeyType = .search
        searchTextField.autocorrectionType = .no
        searchTextField.addInputAccessoryView(with: self, doneAction: #selector(self.dismissKeyboard))
        
        clearButton = UIButton(frame: CGRect(x: titleView.bounds.width - 40, y: 0, width: 40, height: 36))
        clearButton.setImage(#imageLiteral(resourceName: "Cancel_gray"), for: .normal)
        clearButton.tintColor = UIColor(hex: 0x9B9B9B)
        titleView.addSubview(searchTextField)
        titleView.addSubview(clearButton)
        self.navigationItem.titleView = titleView
        
        let gradientLayer:CAGradientLayer = CAGradientLayer()
        gradientLayer.frame.size = shadowView.frame.size
        gradientLayer.frame.size.width = UIScreen.main.bounds.width
        gradientLayer.colors =
            [UIColor(hex: 0xf0f0f0)!.cgColor, UIColor(hex: 0xffffff)!.cgColor]
        shadowView.layer.addSublayer(gradientLayer)
        shadowView.alpha = 0.7
    }
    
    private func configureTableView() {
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)
        tableView.register(nibWithCellClass: SearchUserTableViewCell.self)
        tableView.register(nibWithCellClass: SearchItineraryTableViewCell.self)        
    }
    
    private func showFirstTab() {
        transitionAnimated = false
        switchButtonTapped(switchButtonCollection.first!)
    }
    
    override func dismissKeyboard() {
        searchTextField.resignFirstResponder()
    }
}

// MARK: - IBAction
extension SearchViewController {
    @IBAction func switchButtonTapped(_ sender: UIButton) {
        guard !sender.isSelected else { return }
        
        sender.isSelected = true
        var direction = UIPageViewController.NavigationDirection.forward
        
        let index = sender.tag
        let selectVC = pageViewControllers[index]
        updateSwitchButtons(with: index)
        if index < currentPage {
            direction = UIPageViewController.NavigationDirection.reverse
        }
        currentPage = index
        if (!transitionInProgress) {
            transitionInProgress = true
            let animated = transitionAnimated
            transitionAnimated = true
            pageViewController.setViewControllers([selectVC], direction: direction, animated: animated) { [weak self]_ in
                guard let strongSelf = self else { return }
                if let pvcs = strongSelf.pageViewController {
                    DispatchQueue.main.async(execute: {
                        pvcs.setViewControllers([selectVC], direction: direction, animated: false, completion: { (finished) in
                            strongSelf.transitionInProgress = !finished
                        })
                    })
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension SearchViewController : UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? viewModel.popularUsers.value.count : viewModel.popularItineraries.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SearchUserTableViewCell", for: indexPath) as! SearchUserTableViewCell
            cell.bindViewModel(viewModel.popularUsers.value[indexPath.row])
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SearchItineraryTableViewCell", for: indexPath) as! SearchItineraryTableViewCell
            cell.bindViewModel(viewModel.popularItineraries.value[indexPath.row])
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let nib = UINib.init(nibName: "SettingHeaderView", bundle: nil)
        let headerView = nib.instantiate(withOwner: nil, options: nil).first as? SettingHeaderView
        headerView?.titleLabel.text = section == 0 ? "Popular users" : "Popular itineraries"
        headerView?.separateView.isHidden = section == 0
        headerView?.titleLabelBottom.constant = 24
        headerView?.titleLabelTop.constant = (section == 0 ? 40 : 32)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 54 + 24 + (section == 0 ? 5 : 0)
    }
    
}

// MARK: - UIPageViewControllerDelegate
extension SearchViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
//        currentPage = pageViewControllers.index(of: pageViewController.viewControllers![0] as! SearchResultViewController)!
//        updateSwitchButtons(with: currentPage)
        
//        currentPage = pageViewControllers.index(of: pendingViewControllers[0] as! SearchResultViewController)!
//        updateSwitchButtons(with: currentPage)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if !completed { return }
        currentPage = pageViewControllers.index(of: pageViewController.viewControllers![0] as! SearchResultViewController)!
        updateSwitchButtons(with: currentPage)
    }
}

// MARK: - UIPageViewControllerDataSource
extension SearchViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if pageViewControllers.first == viewController {
            return nil
        } else {
            let index = pageViewControllers.index(of: viewController as! SearchResultViewController)! - 1
            return pageViewControllers[index]
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if pageViewControllers[3] == viewController {
            return nil
        } else {
            let index = pageViewControllers.index(of: viewController as! SearchResultViewController)! + 1
            return pageViewControllers[index]
            
        }
    }
    
}

// MARK: - UITextFieldDelegate
extension SearchViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if !(textField.text ?? "").isEmpty {
            enableSearchMode(true)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if !(textField.text ?? "").isEmpty {
            if viewModel.fetchingKeywords {
                return false
            }
            viewModel.search(textField.text!)
            enableSearchMode(false)
            enableResultView(true)
            showFirstTab()
        } else {
            enableResultView(false)
        }
        return true
    }
}
