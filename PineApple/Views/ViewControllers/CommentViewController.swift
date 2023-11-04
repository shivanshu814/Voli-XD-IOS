//
//  CommentViewController.swift
//  PineApple
//
//  Created by Tao Man Kit on 8/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import MessageViewController
import RxCocoa
import RxSwift
import FirebaseStorage
import SDWebImage

class CommentViewController: MessageViewController, ViewModelBased {

    // MARK: - Properties
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    let tableView = UITableView()
    var viewModel: CommentViewModel!
    private let disposeBag = DisposeBag()
    private var postButton: UIButton!
    private var isFirst = true
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - View Life Cycle
extension CommentViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationbar()
        configureMessageBar()
        configureTableView()
        configureAutoCompleteViewController()
        bindViewModel(viewModel)
        bindAction()
        
        NotificationCenter.default.addObserver(forName: .didCommentDidUpdated, object: nil, queue: .main) {[weak self] notification in
                   if let comment = notification.userInfo?["comment"] as? Comment {
                       self?.viewModel.refresh(comment)
                   }
               }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }
    
}

// MARK: - Private
extension CommentViewController {
    
    private func loadData() {
        viewModel.fetchComments {[weak self] (result, error) in
            if let error = error {
                self?.showAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }
    
    private func configureNavigationbar() {
        addCloseButton()
        title = "Comments"
    }
    
    private func configureMessageBar() {
        borderColor = UIColor.clear
        
        let contentView = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 8))
        contentView.backgroundColor = UIColor.clear
        messageView.add(contentView: contentView)
        
        
        messageView.textViewInset = UIEdgeInsets(top: 14, left: 89, bottom: 14, right: 18)
        messageView.font = Styles.customFontLight(15)
        messageView.textView.placeholderText = "Add a comment..."
        messageView.textView.placeholderTextColor = UIColor(hex: 0x959595)
        messageView.textView.isUserInteractionEnabled = true
        messageView.textView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -13)
        messageView.textView.autocorrectionType = .no
        
        // Left Button
        messageView.setButton(icon: nil, for: .normal, position: .left)
        messageView.addButton(target: self, action: #selector(onLeftButton), position: .left)
        messageView.leftButtonTint = .blue
        messageView.showLeftButton = false
        messageView.setButton(inset: 0, position: .left)
        
        let leftButton = UIButton(type: .custom)
        leftButton.cornerRadius = 20
        leftButton.contentMode = .scaleAspectFill
        leftButton.backgroundColor = UIColor.lightGray
        leftButton.addTarget(self, action: #selector(onLeftButton), for: .touchUpInside)
        
        messageView.addSubview(leftButton)
        leftButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leftButton.widthAnchor.constraint(equalToConstant: 40),
            leftButton.heightAnchor.constraint(equalToConstant: 40),
            leftButton.leadingAnchor.constraint(equalTo: messageView.leadingAnchor, constant: 18),
            leftButton.centerYAnchor.constraint(equalTo: self.messageView.textView.centerYAnchor, constant: 0)
            ])
        if let path = Globals.currentUser?.profileImageUrl {
            let storageRef = viewModel.storage.reference()
            let reference = storageRef.child(path)
            leftButton.imageView?.sd_setImage(with: reference, placeholderImage: nil, completion: { (image, error, cacheType, reference) in
                if image != nil {
                    leftButton.setImage(image, for: .normal)
                }
            })
        }
        
        let baseView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 48))
        baseView.borderColor = UIColor.lightGray
        baseView.borderWidth = 1
        baseView.backgroundColor = UIColor.clear
        baseView.isUserInteractionEnabled = false
        baseView.cornerRadius = 22
        messageView.addSubview(baseView)
        baseView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            baseView.leadingAnchor.constraint(equalTo: leftButton.trailingAnchor, constant: 11),
            baseView.trailingAnchor.constraint(equalTo: messageView.trailingAnchor, constant: -15),
            baseView.heightAnchor.constraint(equalTo: messageView.textView.heightAnchor, constant: 0),
            baseView.centerYAnchor.constraint(equalTo: self.messageView.textView.centerYAnchor, constant: 0)
            ])
        
        postButton = UIButton(type: .system)
        postButton.setTitle("Post", for: .normal)
        postButton.setTitleColor(Styles.pCFC2FF, for: .disabled)
        postButton.setTitleColor(Styles.p8437FF, for: .normal)
        postButton.titleLabel?.font = Styles.customFontBold(14)
        postButton.addTarget(self, action: #selector(onRightButton), for: .touchUpInside)
        messageView.addSubview(postButton)
        postButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            postButton.widthAnchor.constraint(equalToConstant: 40),
            postButton.heightAnchor.constraint(equalToConstant: 40),
            postButton.trailingAnchor.constraint(equalTo: messageView.trailingAnchor, constant: -25),
            postButton.centerYAnchor.constraint(equalTo: self.messageView.textView.centerYAnchor, constant: 0)
            ])
        
        
        // Right Button
        messageView.setButton(inset: 15, position: .right)
        messageView.setButton(title: "", for: .normal, position: .right)
        messageView.rightButtonTint = .blue
        
        if Globals.currentUser != nil {
            messageView.textView.becomeFirstResponder()
        } else {
            messageView.isUserInteractionEnabled = Globals.currentUser != nil
        }
        
    }
    
    private func configureTableView() {
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 300
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(nibWithCellClass: CommentTableViewCell.self)
        tableView.delegate = self
        setup(scrollView: tableView)
    }
    
    private func configureAutoCompleteViewController() {
        let nib = UINib(nibName: "AutoCompleteUserCell", bundle: nil)
        messageAutocompleteController.tableView.register(nib, forCellReuseIdentifier: "AutoCompleteUserCell")
        messageAutocompleteController.tableView.estimatedRowHeight = 44
        messageAutocompleteController.tableView.rowHeight = UITableView.automaticDimension
        
        let tintColor = Styles.p8437FF
        messageAutocompleteController.registerAutocomplete(prefix: "@", attributes: [
        .foregroundColor: tintColor,
        .backgroundColor: tintColor.withAlphaComponent(0.1)
        ])
        messageAutocompleteController.delegate = self
    }
    
    @objc func onLeftButton() {
        print("Did press left button")
    }
    
    @objc func onRightButton() {
        if let user = Globals.currentUser {
            let comment = Comment(id: "", user: user, message: messageView.text, likeCount: 0, date: Date(), tags: viewModel.newTags)
            showLoading()
            viewModel.postComment(comment) {[weak self] (result, error) in
                self?.stopLoading()
                if let error = error {
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                } else {
                    self?.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                }
            }
            messageView.textView.resignFirstResponder()
        }
    }
}

// MARK: - RX
extension CommentViewController {
    
    func bindViewModel(_ viewModel: CommentViewModel) {
        self.viewModel = viewModel
        
        (messageView.textView.rx.text.orEmpty <-> viewModel.newComment).disposed(by: disposeBag)
        
        viewModel.newComment
            .asObservable()
            .bind {[weak self] (newComment) in
                self?.postButton.isEnabled = !newComment.isEmpty 
            }
            .disposed(by: disposeBag)
        
        viewModel.comments
            .bind(to: tableView.rx.items(cellIdentifier: "CommentTableViewCell", cellType: CommentTableViewCell.self)) { (row, element, cell) in
                cell.bindViewModel(element)
                cell.commentButtonDidClickBlock = { [weak self] vm in
                    guard let strongSelf = self else { return }

                    let defaultTypingTextAttributes = strongSelf.messageView.textView.typingAttributes
                    let newAttributedText = strongSelf.messageView.textView.attributedText.mutableCopy() as! NSMutableAttributedString
                    newAttributedText.append(NSAttributedString(string: newAttributedText.string.isEmpty ? "@" : " @", attributes: defaultTypingTextAttributes))
                    strongSelf.messageView.textView.attributedText = NSAttributedString()
                    strongSelf.messageView.textView.attributedText = newAttributedText

                    let name = vm.model.user.displayName
                    strongSelf.viewModel.newTags.append(name)

                    strongSelf.viewModel.autocompleteUsers.accept([vm.model.user])
                    strongSelf.messageAutocompleteController.show(true)
                    strongSelf.messageAutocompleteController.tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .none)

                    strongSelf.messageAutocompleteController.accept(autocomplete: name)

                }
                cell.itemDidReportBlock = { [weak self] vm in
                    guard let strongSelf = self else { return }
                    let defaultAction = UIAlertAction(title: "Yes",
                                                      style: .default) {[weak self] (action) in
                                                        guard let strongSelf = self else { return }

                                                        var newValue = strongSelf.viewModel.comments.value
                                                        newValue.removeObject(vm)
                                                        strongSelf.viewModel.comments.accept(newValue)

                    }
                    let cancelAction = UIAlertAction(title: "Cancel",
                                                     style: .cancel) { (action) in }

                    let alert = UIAlertController(title: "",
                                                  message: "Do you want to report this comment?",
                                                  preferredStyle: .alert)
                    alert.addAction(defaultAction)
                    alert.addAction(cancelAction)
                    strongSelf.present(alert, animated: true) {}
                }
            }.disposed(by: disposeBag)
        
        viewModel.autocompleteUsers
            .bind(to: messageAutocompleteController.tableView.rx.items(cellIdentifier: "AutoCompleteUserCell", cellType:
                TableViewCell.self)) {[weak self] (row, element, cell) in
                    guard let strongSelf = self else { return }
                    cell.labels?.first?.text = element.displayName
                    let storageRef = strongSelf.viewModel.storage.reference()
                    let reference = storageRef.child(element.thumbnail)
                    cell.imagesViews?.first?.sd_setImage(with: reference, placeholderImage: nil, completion: { (image, error, cacheType, reference) in
                        if image != nil {
                            cell.imagesViews?.first?.image = image
                        }
                    })
                    cell.selectionStyle = .none
            }.disposed(by: disposeBag)
        
    }
    
    func bindAction() {
        messageAutocompleteController.tableView.rx.itemSelected
            .asObservable()
            .bind {[weak self] (indexPath) in
                guard let strongSelf = self else { return }
                let name = (strongSelf.viewModel.autocompleteUsers.value[indexPath.row]).displayName
                strongSelf.viewModel.newTags.append(name)
                strongSelf.messageAutocompleteController.accept(autocomplete: name)
            }.disposed(by: disposeBag)
    }
    
}

// MARK: - MessageAutocompleteControllerDelegate
extension CommentViewController: MessageAutocompleteControllerDelegate {
    func didFind(controller: MessageAutocompleteController, prefix: String, word: String) {
        let autocompleteUsers = viewModel.users.filter { word.isEmpty || $0.displayName.lowercased().contains(word.lowercased()) }
        viewModel.autocompleteUsers.accept(autocompleteUsers)
        controller.show(true)
    }
        
}

// MARK: - UITableViewDataSource
extension CommentViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if viewModel.paging.isMore.value && indexPath.row == viewModel.comments.value.count - 2 {
            loadData()
        }
    }
}


