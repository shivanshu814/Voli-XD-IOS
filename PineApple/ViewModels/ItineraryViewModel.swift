//
//  ItineraryViewModel.swift
//  PineApple
//
//  Created by Tao Man Kit on 15/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Firebase
import FirebaseAuth
import FirebaseStorage
import CoreLocation

class ItineraryViewModel: ViewModel {

    // MARK: - Properties
    private var _model: Itinerary
    var model: Itinerary { return _model }
    var rows = BehaviorRelay<[ViewModel]>(value:[RequiredFieldViewModel(title: "TITLE*", description: "", errorMessage: "Title cannot be empty", isSingleLine: true),
                                                 RequiredFieldViewModel(title: "DESCRIPTION", description: "", errorMessage: "Please provide a description")])
    var isLike = BehaviorRelay<Bool>(value: false)
    var isSave = BehaviorRelay<Bool>(value: false)
    var isComment = BehaviorRelay<Bool>(value: false)
    var likeCount = BehaviorRelay<Int>(value: 0)
    var commentCount = BehaviorRelay<Int>(value: 0)
    var savedCount = BehaviorRelay<Int>(value: 0)
    var isAllowContact = BehaviorRelay<Bool>(value: false)
    var isPrivate = BehaviorRelay<Bool>(value: false)
    var coverImageError = BehaviorRelay<String?>(value: nil)
    var user = BehaviorRelay<User?>(value: nil)
    var createDate = BehaviorRelay<Date>(value: Date())
    var profileImage = BehaviorRelay<StorageReference?>(value: nil)    
    var isEditing = false
    var isVideo = false
    var heroPrefix: String
    var newTags = [String]()
    var deletedtags = [String]()
    var titleFieldViewModel: RequiredFieldViewModel!
    var descriptionFieldViewModel: RequiredFieldViewModel!
    var heroImage = BehaviorRelay<String?>(value: nil)
    var heroImageThumbnail = BehaviorRelay<String?>(value: nil)
    var attachments = BehaviorRelay<[AttachmentViewModel]>(value: [])
    var isReload = true
    var isPrivateBefore: Bool? = nil
    var firstErrorRow = -1
    private let disposeBag = DisposeBag()
    
    var activityViewModels: [ActivityViewModel] {
        return rows.value.filter{$0 is ActivityViewModel} as! [ActivityViewModel]
    }
    
    var isSaved: Bool {
        return !_model.id.isEmpty
    }
    
    var selectedActivity: ActivityViewModel?
    let storage = Storage.storage()
    
    var title: BehaviorRelay<String> {
        return (rows.value[0] as! RequiredFieldViewModel).value
    }
    let locationViewModel = LocationViewModel(enableCityCenter: true)
    
    // MARK: - Init
    init(itinerary: Itinerary, isEditing: Bool = false, heroPrefix: String = "Detail") {
        self._model = itinerary
        self.heroPrefix = heroPrefix
        self.isEditing = isEditing
        if let currentUser = Globals.currentUser, currentUser.isItineraryPrivate && itinerary.id.isEmpty {
            self._model.isPrivate = true
        }        
        self.setup(with: self._model)
        self.setupLocationViewModel()
    }
    
    // MARK: - Init
    init(id: String, isEditing: Bool = false, heroPrefix: String = "Detail") {
        self._model = Itinerary(id: id)
        self.heroPrefix = heroPrefix
        self.isEditing = isEditing
        self.setupLocationViewModel()
    }
}

// MARK: - ViewModel
extension ItineraryViewModel {
    func setModel(_ model: Itinerary) {
        _model = model
    }
    
    func setup(with model: Itinerary) {
        _model = model
        
        // Rows
        if titleFieldViewModel == nil {
            titleFieldViewModel = (rows.value[0] as! RequiredFieldViewModel)
            descriptionFieldViewModel = (rows.value[1] as! RequiredFieldViewModel)

            descriptionFieldViewModel.isRequired = false
            descriptionFieldViewModel.max = 410
        }
        titleFieldViewModel.value.accept(model.title)
        descriptionFieldViewModel.value.accept(model.description)
        
        var newRows: [ViewModel] = [titleFieldViewModel]
        for (index, activity) in model.activities.enumerated() {
            let model = ActivityViewModel(activity: activity, index: index, isEditing: isEditing, heroPrefix: heroPrefix)
            model.isFirst = index == 0
            newRows.append(model)
        }

        rows.accept(newRows)
        isComment.accept(model.isCommented)
        isLike.accept(model.isLike)
        isSave.accept(model.isSave)
        likeCount.accept(model.likeCount)
        commentCount.accept(model.commentCount)
        savedCount.accept(model.savedCount)
        isPrivate.accept(model.isPrivate)
        if isPrivateBefore == nil {
            isPrivateBefore = model.isPrivate
        }
        isAllowContact.accept(model.isAllowContact)
        user.accept(model.user)
        createDate.accept(model.createDate)
        let storageRef = Storage.storage().reference()
        profileImage.accept(storageRef.child(model.user.thumbnail))
        isVideo = !model.coverVideo.isEmpty
        heroImageThumbnail.accept(model.heroImageThumbnail)
        heroImage.accept(isVideo ? model.coverVideo : model.heroImage)
        
        
    }
    
    func updateModel() {
        if !model.id.isEmpty {
            newTags = []
            deletedtags = []
            let tags = model.tags
            var currentTags = [String]()
            activityViewModels.forEach {
                currentTags.append(contentsOf: $0.tags.value.map{$0.tag.name})
            }
            // new
            currentTags.forEach {
                if !tags.contains($0) && !newTags.contains($0)  {
                    newTags.append($0)
                }
            }
            // delete
            tags.forEach {
                if !currentTags.contains($0) {
                    deletedtags.append($0)
                }
            }
        }
        
        _model.title = titleFieldViewModel.value.value
        _model.description = descriptionFieldViewModel.value.value
        
        activityViewModels.forEach{
            var newModel = $0.attachments.value
            if newModel.last?.attachment.path.isEmpty ?? false {
                newModel.removeLast()
            }
            $0.attachments.accept(newModel)
            
            $0.updateModel()
        }
        
        _model.activities = activityViewModels.map{$0.model}
        _model.isLike = isLike.value
        _model.isSave = isSave.value
        _model.isCommented = isComment.value
        _model.likeCount = likeCount.value
        _model.commentCount = commentCount.value
        _model.savedCount = savedCount.value
        _model.isPrivate = isPrivate.value
        _model.isAllowContact = isAllowContact.value
        let firstAttachment = _model.activities.first?.attachments.first
        if isVideo {
            _model.coverVideo = heroImage.value ?? ""
            _model.heroImageThumbnail = heroImageThumbnail.value ?? ""
            _model.heroImage = ""
        } else  {
            _model.coverVideo = ""
            _model.heroImage = heroImage.value ?? firstAttachment?.path ?? ""
            _model.heroImageThumbnail = heroImageThumbnail.value ?? firstAttachment?.thumbnail ?? ""
        }
        
        if let location = activityViewModels.first?.location, locationViewModel.cityCenter.value != nil {
            _model.distance = locationViewModel.calculateDistance(CLLocation(latitude: location.latitude, longitude: location.longitude))
        } 
        
    }
}

// MARK: - Private
extension ItineraryViewModel {
    private func setupLocationViewModel() {
        locationViewModel.cityCenter
            .asObservable()
            .bind { (center) in
            
        }.disposed(by: disposeBag)
    }
}

// MARK: - Public
extension ItineraryViewModel {
    
    func reset() {
        titleFieldViewModel.value.accept("")
        titleFieldViewModel.errorValue.accept(nil)
        descriptionFieldViewModel.value.accept("")
        descriptionFieldViewModel.errorValue.accept(nil)
        isVideo = false
        heroImage.accept(nil)
        heroImageThumbnail.accept(nil)
        firstErrorRow = -1
        coverImageError.accept(nil)
        let activityViewModel = ActivityViewModel(activity: Activity(), index: 0, isEditing: isEditing, heroPrefix: heroPrefix)
        rows.accept([titleFieldViewModel, activityViewModel])
        isPrivate.accept(Globals.currentUser?.isItineraryPrivate ?? false)
        _model.id = ""        
    }
    
    func sortActivitiesIfNeeded() -> (Int, Int) {
        var newActivities: [ActivityViewModel]
        let beforeIndex = activityViewModels.firstIndex(of: selectedActivity!)!
        newActivities = activityViewModels.sorted(by: { $0.date.value < $1.date.value })
        let afterIndex = newActivities.firstIndex(of: selectedActivity!)!
        print(String(beforeIndex) + " " + String(afterIndex))
        return (beforeIndex, afterIndex)
    }
    
    func updateSortedActivities() {
        var newActivities: [ActivityViewModel]
        newActivities = activityViewModels.sorted(by: { $0.date.value < $1.date.value })
        for (index, item) in newActivities.enumerated() {
            item.index = index
        }
        var newRows = [self.rows.value[0]]
        newRows.append(contentsOf: newActivities)
        self.rows.accept(newRows)
    }
    
    func loadAllAttachments() {
        var allAttachments = [AttachmentViewModel]()
        activityViewModels.forEach {
            for attachment in $0.attachments.value {
                if !attachment.attachment.path.isEmpty {
                    allAttachments.append(attachment)
                }
            }
        }
        attachments.accept(allAttachments)
    }
    
    func addActivity() {
        var newActivity = Activity()
        newActivity.startTime = activityViewModels.last!.date.value
        let activityViewModel = ActivityViewModel(activity: newActivity, index: rows.value.count - 1, isEditing: true)
        selectedActivity = activityViewModel
        var newRows = rows.value
        newRows.append(activityViewModel)
        isReload = false
        rows.accept(newRows)
    }
    
    func fetch(_ completionHandler: @escaping RequestDidCompleteBlock) {
        Itinerary.findById(model.id) {[weak self] (itinerary, error) in
            guard let strongSelf = self else { return }
            if var itinerary = itinerary {
                itinerary.updateLikeCommentSave()
                strongSelf.setup(with: itinerary)
                completionHandler(true, nil)
            } else {
                completionHandler(false, error ?? "Server error")
            }
        }
    }
    
    func delete(_ completionHandler: @escaping RequestDidCompleteBlock) {
        Itinerary.delete(model) {[weak self] (result, error) in
            if result {
                self?.reset()
            }
            completionHandler(result, error)
        }
    }
    
    func clearLocalCache() {
        let path = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask,true).first!)/Attachments"
        try? FileManager.default.removeItem(atPath: path)
        attachmentIndex = 0
    }
    
    func updateUser() {
        if let user = Globals.currentUser {
            _model.user = user
        }
    }
    
    func validate() -> Bool {
        firstErrorRow = -1
        let v1 = titleFieldViewModel.validate()
        if !v1 { firstErrorRow = 1 }
        let v2 = descriptionFieldViewModel.validate()
        if firstErrorRow < 0 && !v2 { firstErrorRow = 0 }
        var v3 = !(heroImageThumbnail.value?.isEmpty ?? true)
        coverImageError.accept(v3 ? "" : "Please select a cover image/video")
        if isVideo && v3 && heroImage.value!.starts(with: "/") {
            let fileAttributes = try! FileManager.default.attributesOfItem(atPath: heroImage.value!)
            let fileSizeNumber = fileAttributes[FileAttributeKey.size] as! NSNumber
            let fileSize = fileSizeNumber.int64Value
            var sizeMB = Double(fileSize / 1024)
            sizeMB = Double(sizeMB / 1024)
            print(String(format: "%.2f", sizeMB) + " MB")
            v3 = sizeMB <= 20
            coverImageError.accept(v3 ? "" : "Size cannot be larger than 20MB")
        }
        
        
        if firstErrorRow < 0 && !v3 { firstErrorRow = 0 }
        
        var isAllValid = true
        for (index, vm) in activityViewModels.enumerated() {
            if !vm.validate() {
                if firstErrorRow < 1 { firstErrorRow = index + 2 }
                isAllValid = false
            }
        }
        let isValid = v1 && v2 && v3 && isAllValid
        if isValid {
            firstErrorRow = -1
        }
        return isValid
    }
    
    func loadItinerary() {
        self.setup(with: _model)
    }
    
    func getCityCenter() {
        updateModel()
        let fullName = model.country == "hong kong" ? model.country : "\(model.city.isEmpty ? "" : "\(model.city), ")\(model.state.isEmpty ? "": "\(model.state), ")\(model.country)"
        if let location = Globals.cityCenter[fullName] {
            locationViewModel.cityCenter.accept(location)
        } else {
            locationViewModel.fetchPlaces(keyword: fullName)
        }
        
    }
    
    func save(_ completionHandler: @escaping RequestDidCompleteBlock) {
        let _newTags = newTags
        let _deletedtags = deletedtags
        updateModel()
        if model.id.isEmpty {
            Itinerary.create(model) {[weak self] (id, error) in
                if let error = error {
                    completionHandler(false, error)
                } else {
                    self?._model.id = id
                    completionHandler(true, nil)
                }
            }
        } else {
            Itinerary.update(model, privateChanged: isPrivateBefore != model.isPrivate, tags: _newTags.map{Tag(name: $0)}, deletedTags: _deletedtags.map{Tag(name: $0)},  completionHandler: completionHandler)
        }
    }
    
    func removeActivity(_ index: Int) {
        var newActivities = activityViewModels
        
        if newActivities.count == 1 {
            newActivities.first?.setup(with: Activity())
            newActivities.first?.index = 0
        } else {
            newActivities.remove(at: index)
            
            if index == 0 {
                newActivities.first?.isFirst = true
            }
            
            for (index, activity) in newActivities.enumerated() {
                activity.index = index
            }
        }
        
        var newRows: [ViewModel] = [titleFieldViewModel]
        newRows.append(contentsOf: newActivities)
        rows.accept(newRows)
    }
    
    func uploadPhotos(_ completionHandler: @escaping RequestDidCompleteBlock) {
        var paths = [String: String]()
        
        func uploadFinished() {
            for activity in activityViewModels {
                activity.updateAttachmentPath(paths)
            }
            if heroImageThumbnail.value != nil && paths[heroImageThumbnail.value!] != nil {
                heroImage.accept(paths[heroImage.value!])
                heroImageThumbnail.accept(paths[heroImageThumbnail.value!])
            }            
            
            save(completionHandler)
        }
        
        func upload(path: String, index: Int, isVideo: Bool = false) {
            let name = "\(Styles.dateFormatter_ddMMyyyyHHmmsssss.string(from: Date()))\(index).\(isVideo ? "mp4" : "jpg")"
            print(Date())
            let localFile = URL(fileURLWithPath: path)
            let metadata = StorageMetadata()
            metadata.contentType = isVideo ? "video/mpeg4" : "image/jpeg"
            let user = Auth.auth().currentUser
            let storageRef = storage.reference()
            let ref = storageRef.child("\(user!.uid)/\(name)")
            print("\(user!.uid)/\(name)")
            let uploadTask = ref.putFile(from: localFile, metadata: metadata)
            
            uploadTask.observe(.resume) { snapshot in
                // Upload resumed, also fires when the upload starts
            }
            
            uploadTask.observe(.pause) { snapshot in
                // Upload paused
            }
            
            uploadTask.observe(.progress) { snapshot in
                // Upload reported progress
                let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
                    / Double(snapshot.progress!.totalUnitCount)
                print(percentComplete)
            }
            
            uploadTask.observe(.success) { snapshot in
                paths[path] = snapshot.reference.fullPath
                if (paths.values.filter { $0.isEmpty }).isEmpty {
                    uploadFinished()
                }
            }
            
            uploadTask.observe(.failure) { snapshot in
                if let error = snapshot.error as NSError? {
                    switch (StorageErrorCode(rawValue: error.code)!) {
                    case .objectNotFound:
                        print("File doesn't exist")
                        break
                    case .unauthorized:
                        print("User doesn't have permission to access file")
                        break
                    case .cancelled:
                        print("User canceled the upload")
                        break
                    case .unknown:
                        print("Unknown error occurred, inspect the server response")
                        break
                    default:
                        print("A separate error occurred. This is a good place to retry the upload.")
                        break
                    }
                }
            }
        }
        
        // Upload photo
        var index = 0
        for activity in activityViewModels {
            activity.attachments.value.forEach {
                if !$0.attachment.path.isEmpty && $0.attachment.path.starts(with: "/") {
                    paths[$0.attachment.path] = ""
                    paths[$0.attachment.thumbnail] = ""
                    upload(path: $0.attachment.path, index: index)
                    index += 1
                    upload(path: $0.attachment.thumbnail, index: index)
                    index += 1
                }
            }
        }
        if isVideo {
            if let path = heroImage.value, path.starts(with: "/") {
                paths[path] = ""
                upload(path: path, index: index, isVideo: true)
                index += 1
            }
            if let path = heroImageThumbnail.value, path.starts(with: "/") {
                paths[path] = ""
                upload(path: path, index: index)
                index += 1
            }
        }
        
        if paths.keys.isEmpty {
            uploadFinished()
        }
        
    }
    
    func updatePrivateStatus() {
        isPrivate.accept(!isPrivate.value)
    }
    
    func updateContactStatus() {
        isAllowContact.accept(!isAllowContact.value)
    }
}
