//
//  ChatViewModel.swift
//  PineApple
//
//  Created by Tao Man Kit on 27/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

let searchItemPerPage = 10

class ChatViewModel: ViewModel {
    private var _model: User?
    var model: User? { return _model }
    var allChannels = [ATCChatChannel]()
    var channels = BehaviorRelay<[ChannelCellViewModel]>(value: [])
    var searchText = BehaviorRelay<String>(value: "")
    var paging = Paging()
    var userIndex = 1
    var isAnimated = true
    let remoteData = ATCRemoteData()
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    init(model: User?) {
        setup(with: model)
    }
}

// MARK: - ViewModel
extension ChatViewModel {
    func setup(with model: User?) {
        _model = model
    }
}

// MARK: - Public
extension ChatViewModel {
    
    func getChannelById(_ id: String, completionHandler: @escaping (ATCChatChannel?, Error?) -> Void) {
        remoteData.getChannelById(id, completionHandler: completionHandler)
    }
    
    func searchChannel(_ keyword: String, completionHandler: RequestDidCompleteBlock? = nil) {
        if Globals.currentUser != nil {
            if keyword.isEmpty {
                channels.accept(allChannels.map{ChannelCellViewModel(model: $0)})
            } else {
                remoteData.searchChannels(keyword.lowercased(), userIndex: userIndex) {[weak self] (channels, error) in
                    guard let strongSelf = self, keyword == self?.searchText.value else { return }
                    
                    if let error = error {
                        completionHandler?(false, error)
                    } else {
                        var filteredChannels: [ATCChatChannel]
                        if strongSelf.userIndex == 1 {
                            filteredChannels = channels.filter{$0.user1Name.starts(with: keyword.lowercased())}
                        } else {
                            filteredChannels = channels.filter{$0.user2Name.starts(with: keyword.lowercased())}
                        }
                        
                        let channelCellViewModels = filteredChannels.map{ChannelCellViewModel(model: $0)}
                        if strongSelf.userIndex == 1 {
                            strongSelf.channels.accept(channelCellViewModels)
                        } else {
                            var newChannels = strongSelf.channels.value
                            newChannels.append(contentsOf: channelCellViewModels)
                            strongSelf.channels.accept(newChannels)
                        }
                        if strongSelf.channels.value.count < searchItemPerPage && strongSelf.userIndex == 1 {
                            strongSelf.userIndex = 2
                            strongSelf.searchChannel(keyword, completionHandler: completionHandler)
                        } else {
                            strongSelf.userIndex = 1
                            completionHandler?(true, nil)
                        }
                        
                    }
                }
            }
            
        }
    }
    
    func getChannels(_ completionHandler: @escaping RequestDidCompleteBlock) {
        if Globals.currentUser != nil {
            remoteData.getMyChannels(paging) {[weak self] (channels, error) in
                guard let strongSelf = self else { return }
                if let error = error {
                    completionHandler(false, error)
                } else {
                    let channelCellViewModel = channels.map{ChannelCellViewModel(model: $0)}
                    strongSelf.handlePagingData(channelCellViewModel, br: strongSelf.channels, paging: strongSelf.paging)
                    
                    strongSelf.allChannels = strongSelf.channels.value.map{$0.model}
                    
                    completionHandler(true, nil)
                }
            }
        }
    }
       
    
}
