//
//  ItineraryDetailTableViewCell.swift
//  PineApple
//
//  Created by Tao Man Kit on 28/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import Firebase
import FirebaseUI
import SDWebImage
import ModernAVPlayer
import AVKit

class ItineraryDetailTableViewCell: UITableViewCell, ViewModelBased {

    // MARK: - Properties    
    @IBOutlet weak var aboutTitleLabelTop: NSLayoutConstraint!
    @IBOutlet weak var aboutTitleLabel: UILabel!
    @IBOutlet weak var contactButton: UIButton!
    @IBOutlet weak var topShadpwImageView: UIImageView!
    @IBOutlet weak var bottomShadpwImageView: UIImageView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var topTitleLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLocationLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var heroImageCollectionView: UICollectionView!
    @IBOutlet weak var tagCollectionView: UICollectionView!
    @IBOutlet weak var heroImageView: UIImageView!
    @IBOutlet weak var profileButton: UIButton!
    @IBOutlet weak var profileOverlayButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var itineraryCountLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var privateLabel: UILabel!
    @IBOutlet weak var editViewTop: NSLayoutConstraint!
    @IBOutlet weak var heroImageCollectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var tagCollectionViewHeight: NSLayoutConstraint!
    typealias EditButtonDidClickBlock = () -> Void
    var editButtonDidClickBlock: EditButtonDidClickBlock?
    typealias ContentSizeDidChangeBlock = () -> Void
    var contentSizeDidChangeBlock: ContentSizeDidChangeBlock?
    typealias TagDidClickBlock = (String) -> Void
    var tagDidClickBlock: TagDidClickBlock?
    typealias AttachmentDidClickBlock = ([AttachmentViewModel], UIImage?, AVPlayer?, IndexPath) -> Void
    var attachmentDidClickBlock: AttachmentDidClickBlock?
    typealias ProfileDidClickBlock = (User) -> Void
    var profileDidClickBlock: ProfileDidClickBlock?
    typealias SaveDidClickBlock = (ItineraryDetailViewModel) -> Void
    var saveDidClickBlock: SaveDidClickBlock?
    typealias BackButtonDidClickBlock = () -> Void
    var backButtonDidClickBlock: BackButtonDidClickBlock?
    typealias ContactButtonDidClickBlock = (User) -> Void
    var contactButtonDidClickBlock: ContactButtonDidClickBlock?
    var sizingCell: TagCollectionViewCell!
    var player: ModernAVPlayer?
    var playerLayer: AVPlayerLayer?
        
    var viewModel: ItineraryDetailViewModel!
    private var disposeBag = DisposeBag()
    
    // MARK: - View Life Cycle
    override func awakeFromNib() {
        super.awakeFromNib()
        configureTagCollectionView()
        configureHeroCollectionView()
        configureShadowView()
        configurePageControl()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override func prepareForReuse() {
        disposeBag = DisposeBag()
    }
        
}

// MARK: - RX
extension ItineraryDetailTableViewCell {
    
    func bindViewModel(_ viewModel: ItineraryDetailViewModel) {
        self.viewModel = viewModel
        
        configureEditView()
        
        viewModel.showContact.asDriver()
            .map{!$0}
            .drive(contactButton.rx.isHidden)
            .disposed(by: disposeBag)
        
        pageControl.numberOfPages = viewModel.attachments.value.count
        
        viewModel.numberOfItinerary
            .asDriver()
            .drive(itineraryCountLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.attachments
            .bind(to: heroImageCollectionView.rx.items(cellIdentifier: "HeroImageCell", cellType: CollectionViewCell.self)) {[weak self] (row, element, cell) in
                guard let strongSelf = self else { return }
                if element.attachment.identifier == coverVideo {
                    cell.views?[0].isHidden = false
                    if strongSelf.player == nil {
                        let player = ModernAVPlayer()
                                                
                        let starsRef = strongSelf.viewModel.storage.reference().child(element.attachment.path)
                        
                        starsRef.downloadURL { url, error in
                          if let error = error {
                            print(error.localizedDescription)
                          } else {
                            let media = ModernAVPlayerMedia(url: url!, type: .stream(isLive: false))
                            player.load(media: media, autostart: true)
                            player.loopMode = true
                            player.player.isMuted = true
                            let playerLayer = AVPlayerLayer(player: player.player)
                            playerLayer.frame = cell.bounds
                            playerLayer.videoGravity = .resizeAspectFill
                            strongSelf.player = player
                            strongSelf.playerLayer = playerLayer
                            cell.views?[0].layer.addSublayer(playerLayer)
                          }
                        }
                        cell.imagesViews?[0].loadImage(element.attachment.thumbnail)
                    }
                } else {
                    cell.views?[0].isHidden = true
                    cell.imagesViews?[0].loadImage(element.attachment.path)
                }
        }.disposed(by: disposeBag)
        
        viewModel.model.isPrivate
            .asDriver()
            .map { "Your itinerary is now \( $0 ? "private" : "public")" }
            .drive(privateLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.model.user
            .asObservable()
            .filterNil()
            .bind {[weak self] (user) in
                guard let strongSelf = self else { return }
                strongSelf.nameLabel.text = user.displayName
                strongSelf.addressLabel.text = user.location
            }
            .disposed(by: disposeBag)
        
        viewModel.model.profileImage
            .asObservable()
            .filterNil()
            .bind {[weak self] (reference) in
                guard let strongSelf = self else { return }
               
                strongSelf.profileButton.imageView?.contentMode = .scaleAspectFill
                strongSelf.profileButton.imageView?.sd_setImage(with: reference, placeholderImage: nil, completion: { (image, error, cacheType, reference) in
                    if image != nil {
                        strongSelf.profileButton.setImage(image, for: .normal)                        
                    }
                })
            }
            .disposed(by: disposeBag)
        
        (viewModel.model.rows.value[0] as! RequiredFieldViewModel).value
            .asDriver()
            .drive(titleLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.model.createDate
            .asDriver()
            .map { $0.toDateString}
            .drive(dateLabel.rx.text)
            .disposed(by: disposeBag)
        
        Observable.combineLatest(viewModel.timeSpend, viewModel.model.activityViewModels.first!.locationString) { (x, y) -> String in
                return x + " • " + y
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] (timeLocation) in
                guard let strongSelf = self else { return }
                strongSelf.timeLocationLabel.text = timeLocation
            })
            .disposed(by: disposeBag)
        
        viewModel.heroImage
            .asObservable()
            .filterNil()
            .subscribe(onNext: {[weak self] (reference) in
                guard let strongSelf = self else { return }
                
                if let attachment = viewModel.attachments.value.first?.attachment {
                    
                    if attachment.path.isEmpty {
                        strongSelf.heroImageView?.layer.masksToBounds = true
                        strongSelf.heroImageView?.backgroundColor = UIColor.white
                        strongSelf.heroImageView?.image = #imageLiteral(resourceName: "AddImage")
                    } else if attachment.path.starts(with: "/") {
                        if let image = UIImage(contentsOfFile: attachment.path) {
                            strongSelf.heroImageView?.image = image
                        }
                    } else {
                        strongSelf.heroImageView?.sd_setImage(with: reference, placeholderImage: nil, completion: { (image, error, cacheType, reference) in
                            if image != nil {
                                strongSelf.heroImageView?.image = image
                            }
                        })
                        
                    }
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.tags
            .bind(to: tagCollectionView.rx.items(cellIdentifier: "TagCollectionViewCell", cellType: TagCollectionViewCell.self)) { (row, element, cell) in
                cell.bindViewModel(element)
                element.removePrefix()
                cell.backgroundColor = Styles.p8437FF
                cell.tagLabel.textColor = UIColor.white
            }.disposed(by: disposeBag)
        
        viewModel.model.descriptionFieldViewModel.value
            .asObservable()
            .bind {[weak self] (description) in
                guard let strongSelf = self else { return }
                self?.descriptionLabel.attributedText = NSAttributedString(string: description, attributes: strongSelf.descriptionLabel.attributedText?.attributes)
//                self?.descriptionLabel.text = description
                if description.isEmpty {
                    self?.aboutTitleLabelTop.constant = -27
                    self?.aboutTitleLabel.isHidden = true
                } else {
                    self?.aboutTitleLabelTop.constant = 24
                    self?.aboutTitleLabel.isHidden = false
                }
        }
        .disposed(by: disposeBag)
        
                
        layoutIfNeeded()
        tagCollectionViewHeight.constant = viewModel.tags.value.isEmpty ? 0 : tagCollectionView.contentSize.height
        
        bindAction()
    }
    
    func bindAction() {
        
        contactButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.contactButtonDidClickBlock?(strongSelf.viewModel.itinerary.user)
        }.disposed(by: disposeBag)
        
        backButton.rx.tap
            .bind{ [weak self] in
                self?.backButtonDidClickBlock?()
        }.disposed(by: disposeBag)
        
        profileOverlayButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                if let user = strongSelf.viewModel.model.user.value {
                    strongSelf.profileDidClickBlock?(user)
                }
        }.disposed(by: disposeBag)
        
        tagCollectionView.rx.itemSelected
            .bind {[weak self] indexPath in
                guard let strongSelf = self else { return }
                strongSelf.tagDidClickBlock?(strongSelf.viewModel.tags.value[indexPath.row].tag.name)
        }.disposed(by: disposeBag)
        
        heroImageCollectionView.rx.itemSelected
            .bind {[weak self] indexPath in
                guard let strongSelf = self else { return }
                let image = (strongSelf.heroImageCollectionView.cellForItem(at: indexPath) as! CollectionViewCell).imagesViews!.first!.image
                let attachment = strongSelf.viewModel.attachments.value[indexPath.row]
                if attachment.attachment.identifier == coverVideo {
                    strongSelf.attachmentDidClickBlock?(strongSelf.viewModel.attachments.value, image, self?.player?.player, indexPath)
                } else {
                    strongSelf.attachmentDidClickBlock?(strongSelf.viewModel.attachments.value, image, nil, indexPath)                    
                }
        }.disposed(by: disposeBag)
                
    }
    
}

// MARK: - Private
extension ItineraryDetailTableViewCell {
    
    private func configureShadowView() {
        topShadpwImageView.addGradient(UIColor(hex: 0x000000, transparency: 0.63)!, endColor: UIColor(hex: 0xDFDFDF, transparency: 0)!, size: CGSize(width: UIScreen.main.bounds.width, height: topShadpwImageView.frame.height))

        bottomShadpwImageView.addGradient(UIColor.clear, endColor: UIColor.black, size: CGSize(width: UIScreen.main.bounds.width, height: bottomShadpwImageView.frame.height))
    }
    
    private func configureTagCollectionView() {
        tagCollectionView.register(nibWithCellClass: TagCollectionViewCell.self)
        tagCollectionView.delegate = self
        let nib = UINib.init(nibName: "TagCollectionViewCell", bundle: nil)
        sizingCell = nib.instantiate(withOwner: nil, options: nil).first as? TagCollectionViewCell
        (tagCollectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumLineSpacing = 8
        (tagCollectionView.collectionViewLayout as! UICollectionViewFlowLayout).minimumInteritemSpacing = 8
    }
    
    private func configureHeroCollectionView() {
        heroImageCollectionView.delegate = self
        heroImageCollectionViewHeight.constant = UIScreen.main.bounds.height * 0.71
    }
    
    private func configureEditView() {
        editViewTop.constant = -56
    }
    
    private func configurePageControl() {
        pageControl.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
    }
        
}

// MARK: - Public
extension ItineraryDetailTableViewCell {
    func showCloseButton() {
        backButton.setImage(#imageLiteral(resourceName: "closeButton"), for: .normal)
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate
extension ItineraryDetailTableViewCell : UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == heroImageCollectionView {
            return CGSize(width: UIScreen.main.bounds.width, height: (UIScreen.main.bounds.height * 0.71))
        } else {
            let cellViewModel = viewModel.tags.value[indexPath.row]
            sizingCell.bindViewModel(cellViewModel)
            cellViewModel.removePrefix()
            let size = sizingCell.cellSize
            return CGSize(width: size.width, height: 32)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let visibleRect = CGRect(origin: heroImageCollectionView.contentOffset, size: heroImageCollectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        if let visibleIndexPath = heroImageCollectionView.indexPathForItem(at: visiblePoint) {
            pageControl.currentPage = visibleIndexPath.row
        }
    }
    
    
}
