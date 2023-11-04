//
//  MapActivityCollectionViewCell.swift
//  PineApple
//
//  Created by Tao Man Kit on 21/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class MapActivityCollectionViewCell: UICollectionViewCell, ViewModelBased {
    
    // MARK: - Properties
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var attachmentCollectionView: UICollectionView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var addActivityLabel: UILabel!
    
    var viewModel: ActivityViewModel!
    private var disposeBag = DisposeBag()
    
    // MARK: - View Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    
    override func prepareForReuse() {
        disposeBag = DisposeBag()
    }
}

// MARK: - RX
extension MapActivityCollectionViewCell {
    
    func bindViewModel(_ viewModel: ActivityViewModel) {
        self.viewModel = viewModel
        let isDummy = viewModel.model.isDummy
        backgroundImageView.isHidden = !isDummy
        addActivityLabel.isHidden = !isDummy
        addActivityLabel.font = Styles.customFont(17)
        durationLabel.isHidden = isDummy
        
        viewModel.attachments
            .bind(to: attachmentCollectionView.rx.items(cellIdentifier: "AttachmentCollectionViewCell", cellType: AttachmentCollectionViewCell.self)) { (row, element, cell) in
                cell.bindViewModel(element)
                cell.attachmentImageView.hero.id = ""
                cell.attachmentImageView.alpha = element.attachment.path.isEmpty ? 0 : 1
            }.disposed(by: disposeBag)
        
        viewModel.subLocalityString
            .asDriver()
            .drive(addressLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.timeSpend
            .asDriver().map {TimeInterval(exactly: $0)?.toShortString.uppercased() ?? ""}
            .drive(durationLabel.rx.text)
            .disposed(by: disposeBag)
    }
    
}

// MARK: - Private
extension MapActivityCollectionViewCell {
    @objc func showMapActionSheet() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        
        
        let googleAction = UIAlertAction(title: "Google Maps",
                                         style: .default) {[weak self] (action) in
                                            guard let strongSelf = self else { return }
                                            if let latitude = strongSelf.viewModel.location?.latitude, let longitude = strongSelf.viewModel.location?.longitude {
                                                let url = URL(string:"comgooglemapsurl://maps.google.com/?q=\(latitude),\(longitude)")!
                                                if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)) {
                                                    UIApplication.shared.open(url, completionHandler: { (success) in
                                                        print("Opened: \(success)") // Prints true
                                                    })
                                                }
                                                
                                            }}
        
        let mapAction = UIAlertAction(title: "Maps",
                                      style: .default) {[weak self] (action) in
                                        guard let strongSelf = self else { return }
                                        if let latitude = strongSelf.viewModel.location?.latitude, let longitude = strongSelf.viewModel.location?.longitude {
                                            let url = URL(string:"http://maps.apple.com/?q=\(latitude),\(longitude)")!
                                            if UIApplication.shared.canOpenURL(url) {
                                                UIApplication.shared.open(url, completionHandler: { (success) in
                                                    print("Opened: \(success)") // Prints true
                                                })
                                            }
                                        }
        }

        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel) { (action) in }
        alertController.addAction(googleAction)
        alertController.addAction(mapAction)
        alertController.addAction(cancelAction)
        Globals.topViewController.present(alertController, animated: true, completion: nil)
    }
}
