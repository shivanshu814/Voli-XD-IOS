//
//  ActivityViewModel.swift
//  PineApple
//
//  Created by Tao Man Kit on 16/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import GooglePlaces
import GoogleMaps

class ActivityViewModel: ViewModel {
    // MARK: - Properties    
    private var _model: Activity
    var model: Activity { return _model }
    var index = -1
    var isFirst = false
    var heroPrefix: String
    var shouldGetLocation = true
    var attachments = BehaviorRelay<[AttachmentViewModel]>(value: [])
    var tags = BehaviorRelay<[TagCellViewModel]>(value: [])
    var date = BehaviorRelay<Date>(value: Date())
    var locationToString = false
    var isAttachmentsUpdated = BehaviorRelay<Bool>(value: false)
    var isLocationValid = BehaviorRelay<Bool>(value: true)
    var isAttachmentValid = BehaviorRelay<Bool>(value: true)
    var isTimeSpendValid = BehaviorRelay<Bool>(value: true)
    var location: CLLocationCoordinate2D? {
        didSet {
            guard shouldGetLocation else { return }
            if let newLocation = location {
                guard locationToString else { return }
                
                let _location = CLLocation(latitude: newLocation.latitude, longitude: newLocation.longitude)
                CLGeocoder().reverseGeocodeLocation(_location, preferredLocale: NSLocale(localeIdentifier: "en_US") as Locale) {[weak self] placemarks, error in
                    
                    if let error = error {
                        print(error.localizedDescription)
                    } else {
                        guard let placeMark = placemarks?[0] else { return }
                        
                        let location = placeMark.getCityStateCountryName()
                        self?.city.accept(location.city)
                        self?.state.accept(location.state)
                        self?.country.accept(location.country)
                        
                        let name = placeMark.name ?? ""
                        var thoroughfare = placeMark.thoroughfare ?? ""
                        var subThoroughfare = placeMark.subThoroughfare ?? ""
                        thoroughfare = name.contains(thoroughfare) ? "" : thoroughfare
                        subThoroughfare = name.contains(subThoroughfare) ? "" : subThoroughfare
                        
                        self?.locationString.accept(placeMark.name ?? "")
                        self?.subLocalityString.accept("\(name.isEmpty ? "" : "\(name)")\(thoroughfare.isEmpty ? "": ", \(thoroughfare)")\(subThoroughfare.isEmpty ? "" : ", \(subThoroughfare)")")
                        
                    }
                }
            } else {
                self.locationString.accept("Please set your location.")
                self.subLocalityString.accept("")
            }
        }
    }
    var locationString = BehaviorRelay<String>(value: "")
    var subLocalityString = BehaviorRelay<String>(value: "")
    var city = BehaviorRelay<String>(value: "")
    var state = BehaviorRelay<String>(value: "")
    var country = BehaviorRelay<String>(value: "")
    var description = BehaviorRelay<String>(value: "")
    var timeSpend = BehaviorRelay<TimeInterval>(value: 0)
    var isEditing = false
    private let disposeBag = DisposeBag()
    
    // MARK: - Init
    init(activity: Activity, index: Int = -1, isEditing: Bool = false, heroPrefix: String = "Detail") {
        self.index = index
        self.isFirst = index == 0
        self.isEditing = isEditing
        self.heroPrefix = heroPrefix
        self._model = activity
        self.setup(with: activity)
        attachments
            .asObservable()
            .bind {[weak self] (attachments) in
                self?.getInfoFromFirstImage()
            }.disposed(by: disposeBag)
    }
    
}

// MARK: - ViewModel
extension ActivityViewModel {
    func setup(with model: Activity) {
        _model = model
        var loop = 0
        var newAttachments = model.attachments.map { (attachment) -> AttachmentViewModel in
            let vm = AttachmentViewModel(attachment: attachment, indexPath: index < 0 ? nil : IndexPath(row: loop, section: index), heroPrefix: heroPrefix)
            loop += 1
            return vm
        }
        
        if isEditing {
            // dummy attachment for Adding
            newAttachments.append(AttachmentViewModel(attachment: Attachment()))
        }
        attachments.accept(newAttachments)
        locationString.accept(model.location)
        subLocalityString.accept(model.subLocality)
        city.accept(model.city)
        state.accept(model.state)
        country.accept(model.country)
        timeSpend.accept(model.timeSpend)
        let dateStr = Styles.dateFormatter_HHmma.string(from: model.startTime)
        date.accept(Styles.dateFormatter_HHmma.date(from: dateStr)!)        
        tags.accept(model.tag.map{TagCellViewModel(tag: $0)})
        description.accept(model.description)
        shouldGetLocation = false
        location = CLLocationCoordinate2D(latitude: model.latitude, longitude: model.longitude)
        shouldGetLocation = true
    }
    
    func updateModel() {
        _model.attachments = attachments.value.map{$0.attachment}
        _model.tag = tags.value.map{$0.tag.name}
        _model.description = description.value
        _model.timeSpend = timeSpend.value
        _model.startTime = date.value
        _model.location = locationString.value
        _model.subLocality = subLocalityString.value
        _model.city = city.value
        _model.state = state.value
        _model.country = country.value
        if let _location = location {
            _model.latitude = _location.latitude
            _model.longitude = _location.longitude
        }
    }
}


// MARK: - Public
extension ActivityViewModel {
    
    func updateAttachmentPath(_ paths: [String: String]) {
        for attachment in attachments.value {
            if !attachment.attachment.path.isEmpty && paths[attachment.attachment.path] != nil{
                attachment.attachment.path = paths[attachment.attachment.path] ?? ""
                attachment.attachment.thumbnail = paths[attachment.attachment.thumbnail] ?? ""
            }
        }
    }
    
    func validate() -> Bool {        
        let v1 = location != nil && !(location!.latitude == 0 && location!.longitude == 0)
        let v2 = timeSpend.value > 0
        let v3 = attachments.value.count > 1 && attachments.value.count < 11
        isLocationValid.accept(v1)
        isAttachmentValid.accept(v3)
        isTimeSpendValid.accept(v2)
        return v1 && v2 && v3
    }
    
    func deleteTag(_ tag: TagCellViewModel) {
        var newTags = tags.value
        newTags.removeObject(tag)
        tags.accept(newTags)
    }
    
    func deleteAttachment(_ attachment: AttachmentViewModel) {
        var newAttachments = attachments.value
        newAttachments.removeObject(attachment)
        attachments.accept(newAttachments)
    }
}

// MARK: - Private
extension ActivityViewModel {
    private func getInfoFromFirstImage() {
        if let _location = location.value, _location.longitude == 0, _location.latitude == 0 {
            if let location = attachments.value.first?.attachment.location {
                self.locationToString = true
                self.location = location
            }
            
            if let date = attachments.value.first?.attachment.date {
                self.date.accept(date)
            }
        }
    }
}

// MARK: - Equatable
extension ActivityViewModel: Equatable {
    static func == (lhs: ActivityViewModel, rhs: ActivityViewModel) -> Bool {
        return lhs._model == rhs._model
    }
}
