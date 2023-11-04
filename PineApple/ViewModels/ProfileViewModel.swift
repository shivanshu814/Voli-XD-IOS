//
//  ProfileViewModel.swift
//  PineApple
//
//  Created by Tao Man Kit on 12/9/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import GooglePlaces
import GoogleMaps
import FirebaseStorage
import FirebaseAuth
import CryptoKit
import AuthenticationServices

class ProfileViewModel: NSObject, ViewModel {
    
    // MARK: - Properties
    private var _model: User?
    var model: User? { return _model }
    var profileImage = BehaviorRelay<StorageReference?>(value: nil)
    var city = ""
    var state = ""
    var country = ""
    let storage = Storage.storage()
    var profileImageUrl = BehaviorRelay<String?>(value: nil)
    var thumbnail = BehaviorRelay<String?>(value: nil)
    var showPreviewImage = BehaviorRelay<Bool>(value: false)
    var name = RequiredFieldViewModel(title: "NAME", errorMessage: "Name cannot be emply", isSingleLine: true)
    var rows = BehaviorRelay<[TextFieldViewModel]>(value:
        [
            EmailFieldViewModel(title: "EMAIL", errorMessage: "Email is invalid", isSingleLine: true),
            ColumnTextFieldViewModel(viewModel: (PasswordFieldViewModel(title: "PASSWORD", errorMessage: "Password must be at least 8 characters", isSingleLine: true), PasswordFieldViewModel(title: "CONFIRM PASSWORD", errorMessage: "Password does not match", isSingleLine: true))),
         RequiredFieldViewModel(title: "LOCATION", errorMessage: "Location cannot be emply.", isSingleLine: true)])
    
    var createRows = BehaviorRelay<[TextFieldViewModel]>(value:
        [
            RequiredFieldViewModel(title: "NAME", errorMessage: "Name cannot be emply", isSingleLine: true),
            EmailFieldViewModel(title: "EMAIL", errorMessage: "Email is invalid", isSingleLine: true),
            PasswordFieldViewModel(title: "PASSWORD", errorMessage: "Password must be at least 8 characters", isSingleLine: true),
            RequiredFieldViewModel(title: "LOCATION", errorMessage: "Location cannot be emply", isSingleLine: true)])
    
    var loginRows = BehaviorRelay<[TextFieldViewModel]>(value:
        [EmailFieldViewModel(title: "EMAIL", errorMessage: "Email is not valid.", isSingleLine: true),
         PasswordFieldViewModel(title: "PASSWORD", errorMessage: "Password must be at least 8 characters", isSingleLine: true)])
    
    var isPrivate = BehaviorRelay<Bool>(value: false)
    var appleSignStatus = BehaviorRelay<RequestStatus>(value: .none)
    
    var newTags = [String]()
    var deletedtags = [String]()
    var currentNonce: String?
    
    // MARK: - Init
    override init() {
        super.init()
        getCountry()
    }
    
    init(model: User?) {
        super.init()
        self._model = model        
        if model != nil {
            setup(with: model!)
        }
    }
    
    init(id: String) {
        super.init()
        var user = User()
        user.id = id
        self._model = user
    }
}

// MARK: - ViewModel
extension ProfileViewModel {
    
    func setup(with model: User) {
        _model = model
                
        // Rows
        if model.loginType != "email" {
            var newRows = rows.value
            if newRows[1] is ColumnTextFieldViewModel {
                newRows.remove(at: 1)
            }
            rows.accept(newRows)
        } else {
            (rows.value[1] as! ColumnTextFieldViewModel).viewModel?.0.value.accept("********")
            (rows.value[1] as! ColumnTextFieldViewModel).viewModel?.1.value.accept("********")
        }
        name.value.accept(model.displayName)
        (rows.value[0] as! EmailFieldViewModel).value.accept(model.email)
        (rows.value[rows.value.count-1] as! RequiredFieldViewModel).value.accept(model.location)
        profileImageUrl.accept(model.profileImageUrl)
        thumbnail.accept(model.thumbnail)
        city = model.city
        state = model.state
        country = model.country
    }
    
    private func updateModel() {
        let isCreate = _model == nil
        if _model == nil {
            _model = User()
        }
        
        if !isCreate {
            if _model!.displayName != name.value.value ||
                _model!.location != (rows.value[rows.value.count-1] as! RequiredFieldViewModel).value.value ||
                _model!.thumbnail != thumbnail.value ?? "" {
                _model?.isDirty = true
            } else {
                _model?.isDirty = false
            }
            _model?.displayName = name.value.value
            _model?.email = (rows.value[0] as! EmailFieldViewModel).value.value
            _model?.location = (rows.value[rows.value.count-1] as! RequiredFieldViewModel).value.value
        } else {
            _model?.displayName = (createRows.value[0] as! RequiredFieldViewModel).value.value
            _model?.email = (createRows.value[1] as! EmailFieldViewModel).value.value
            _model?.location = (createRows.value[createRows.value.count-1] as! RequiredFieldViewModel).value.value
            
            var newSetting = _model!.setting
            let s1 = Setting(title: "Itinerary visibility", isEnabled: !isPrivate.value)
            let s2 = Setting(title: "Private messaging", isEnabled: !isPrivate.value)
            var index = newSetting.firstIndex(of: s1)!
            newSetting[index] = s1
            index = newSetting.firstIndex(of: s2)!
            newSetting[index] = s2
            _model?.setting = newSetting
        }
                            
        _model?.profileImageUrl = profileImageUrl.value ?? ""
        _model?.thumbnail = thumbnail.value ?? ""
        _model?.city = city
        _model?.state = state
        _model?.country = country
    }
}


// MARK: - Public
extension ProfileViewModel {
    
    @available(iOS 13, *)
    @objc func startSignInWithAppleFlow() -> ASAuthorizationController{
        let nonce = Globals.randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        return ASAuthorizationController(authorizationRequests: [request])        
    }

    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
          let inputData = Data(input.utf8)
          let hashedData = SHA256.hash(data: inputData)
          let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
          }.joined()

          return hashString
    }
    
    func updatePrivateStatus() {
        isPrivate.accept(!isPrivate.value)
    }
    
    func updateAbout(_ about: String) {
        _model?.about = about
    }
    
    func updateTags(_ tags: [String]) {
        newTags = []
        deletedtags = []
        // new
        tags.forEach {
            if !_model!.tags.contains($0) {
                newTags.append($0)
            }
        }
        // delete
        _model!.tags.forEach {
            if !tags.contains($0) {
                deletedtags.append($0)
            }
        }
        
        _model?.tags = tags
    }
    
    static func configureProfileDirectory() {
        let path = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask,true).first!)/Profile"
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: path) {
            do {
                try fileManager.createDirectory(atPath: path,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
            } catch {
                print(error.localizedDescription)
            }
        }
        
    }
    
    func updateLocation(_ location: String) {
        if model == nil {
            (createRows.value[createRows.value.count-1] as! RequiredFieldViewModel).value.accept(location)
        } else {
            (rows.value[rows.value.count-1] as! RequiredFieldViewModel).value.accept(location)
        }        
    }
    
    func getCountry() {        
        LocationController.shared.getCityCountry {[weak self] (location) in
            guard let strongSelf = self else { return }
            if strongSelf.model == nil {
                (strongSelf.createRows.value[strongSelf.createRows.value.count-1] as! RequiredFieldViewModel).value.accept(location.fullName)
            } else {
                (strongSelf.rows.value[strongSelf.rows.value.count-1] as! RequiredFieldViewModel).value.accept(location.fullName)
            }
            
            strongSelf.city = location.city
            strongSelf.state = location.state
            strongSelf.country = location.country
        }        
    }
    
    static func upload(path: String, thumbnail: String, completionHandler: @escaping (Bool, (path: String, thumbnail: String)?) -> Void) {
        ProfileViewModel.upload(path: path, completionHandler: { (success, url) in
            if !success {
                completionHandler(false, nil)
                return
            }
            let largeUrl = url
            ProfileViewModel.upload(path: thumbnail, completionHandler: { (success, url) in
                if !success {
                    completionHandler(false, nil)
                } else {
                    if let path = largeUrl, let thumbnail = url {
                        completionHandler(true, (path, thumbnail))
                    } else {
                        completionHandler(false, nil)
                    }
                }
            })
        })
    }
    
    static func upload(path: String, suffix: String = "", completionHandler: @escaping (Bool, String?) -> Void) {
        let name = "\(Styles.dateFormatter_ddMMyyyyHHmmsssss.string(from: Date()))\(suffix).jpg"
        let localFile = URL(fileURLWithPath: path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        let user = Auth.auth().currentUser
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let ref = storageRef.child("\(user!.uid)/\(name)")
        let uploadTask = ref.putFile(from: localFile, metadata: metadata)
        
        uploadTask.observe(.resume) { snapshot in
            // Upload resumed, also fires when the upload starts
        }
        
        uploadTask.observe(.pause) { snapshot in
            // Upload paused
        }
        
        uploadTask.observe(.progress) { snapshot in
            // Upload reported progress
//            let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
//                / Double(snapshot.progress!.totalUnitCount)
        }
        
        uploadTask.observe(.success) { snapshot in
            let url = "\(user!.uid)/\(name)"
            print(url)
            completionHandler(true, url)
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
            completionHandler(false, nil)
        }
    }
    
    func loginValidate() -> Bool {
        let v1 = (loginRows.value[0] as! EmailFieldViewModel).validate()
        let v2 = (loginRows.value[1] as! PasswordFieldViewModel).validate()
        return v1 && v2
    }
    
    func validate() -> Bool {
        if _model == nil {
            let v0 = (createRows.value[0] as! RequiredFieldViewModel).validate()
            let v1 = (createRows.value[1] as! EmailFieldViewModel).validate()
            let v2 = (createRows.value[2] as! PasswordFieldViewModel).validate()
            let v3 = (createRows.value[createRows.value.count-1] as! RequiredFieldViewModel).validate()
            return v0 && v1 && v2 && v3
        } else {
            let v0 = name.validate()
            let v1 = (rows.value[0] as! EmailFieldViewModel).validate()
            let v3 = (rows.value[rows.value.count-1] as! RequiredFieldViewModel).validate()
            if _model?.loginType == "email" {
                let password = (rows.value[1] as! ColumnTextFieldViewModel).viewModel?.0.validate() ?? true
                let v2 = (rows.value[1] as! ColumnTextFieldViewModel).viewModel?.0.value.value == (rows.value[1] as! ColumnTextFieldViewModel).viewModel?.1.value.value
                (rows.value[1] as! ColumnTextFieldViewModel).viewModel?.1.errorValue.accept(v2 ? nil : "Password does not match")
                return v0 && v1 && v2 && v3 && password
            }
            return v0 && v1 && v3
        }
        
    }
    
    // create user by email/password or google
    static func createUser(with email: String, loginType: String, user: User? = nil, completionHandler: @escaping RequestDidCompleteBlock) {
        
        // called by email/password
        func create(with user: User, completionHandler: @escaping RequestDidCompleteBlock) {
            if let firUser = Auth.auth().currentUser {
                var _user = user
                _user.id = firUser.uid
                _user.loginType = loginType
                
                User.create(_user, completionHandler: {(result, error) in
                    if let error = error {
                        completionHandler(false, error)
                    } else {
                        Globals.currentUser = _user
                        completionHandler(true, nil)
                    }
                })
            }
        }
        
        // called by google
        func create(with email: String, imageUrl: String = "", thumbnail: String = "", cityCountry: String, city: String, state: String, country: String, completionHandler: @escaping RequestDidCompleteBlock) {
            if let firUser = Auth.auth().currentUser {
                let _user = User(
                        id: firUser.uid,
                        displayName: firUser.displayName ?? "",
                        firstName: "",
                        lastName: "",
                        profileImageUrl: imageUrl,
                        thumbnail: thumbnail,
                        location: cityCountry,
                        city: city,
                        state: state,
                        country: country,
                        email: email,
                        phone: firUser.phoneNumber ?? "",
                        fbId: loginType == "facebook" ? firUser.providerData.first?.uid ?? "" : "",
                        loginType: loginType)
                
                User.create(_user, completionHandler: {(result, error) in
                    if let error = error {
                        completionHandler(false, error)
                    } else {
                        Globals.currentUser = _user
                        completionHandler(true, nil)
                    }
                })
            }
        }
        
        if user != nil {
            create(with: user!, completionHandler: completionHandler)
        } else {
            LocationController.shared.getCityCountry({ (cc) in
                if let firUser = Auth.auth().currentUser {
                    // Photo from FB
                    if loginType == "facebook", let id = firUser.providerData.first?.uid, let url = URL(string: "https://graph.facebook.com/\(id)/picture?type=large"), let data = try? Data(contentsOf: url), let image = UIImage(data: data), let paths = saveImageForUpload(image) {
                        
                        ProfileViewModel.upload(path: paths.path, completionHandler: { (success, url) in
                            let largeUrl = url
                            ProfileViewModel.upload(path: paths.thumbnail, suffix: "_small", completionHandler: { (success, url) in
                                create(with: email, imageUrl: largeUrl ?? "", thumbnail: url ?? "", cityCountry: cc.fullName, city: cc.city, state: cc.state, country: cc.country, completionHandler: completionHandler)
                            })
                        })
                    } else {
                        create(with: email, cityCountry: cc.fullName, city: cc.city, state: cc.state, country: cc.country, completionHandler: completionHandler)
                    }
                }
            })
        }
        
        
    }
    
    // create by email/password
    func create(_ completionHandler: @escaping RequestDidCompleteBlock) {
        if validate() {
            let email = (createRows.value[1] as! EmailFieldViewModel).value.value
            let password = (createRows.value[2] as! PasswordFieldViewModel).value.value
            Auth.auth().createUser(withEmail: email, password: password) {  [weak self] authResult, error in
                
                if error != nil {
                    completionHandler(false, error)
                    return
                }
                self?.updateModel()
                ProfileViewModel.createUser(with: email, loginType: "email", user: self?._model, completionHandler: { (result, error) in
                    if error != nil {
                        completionHandler(false, error)
                    } else {
                        completionHandler(true, nil)
                    }
                })
            }
            return
        }
        completionHandler(false, nil)
    }
    
    func updatePasswordIfNeeded(_ completionHandler: @escaping RequestDidCompleteBlock) {
        if model?.loginType == "email" {
            if let password = (rows.value[1] as? ColumnTextFieldViewModel)?.viewModel?.0.value.value, password != "********" {
                Auth.auth().currentUser?.updatePassword(to: password) { (error) in
                    completionHandler(error==nil, error)
                }
            } else {
                completionHandler(true, nil)
            }
        } else {
            completionHandler(true, nil)
        }
    }
    
    func removeImage() {
           profileImageUrl.accept("")
           thumbnail.accept("")
    }
    
    // update profile
    func saveProfileImage(_ completionHandler: @escaping RequestDidCompleteBlock) {
        updateModel()
        if let user = model {
            User.updateProfileImage(user, completionHandler: completionHandler)
        }
    }
    
    // update profile
    func save(_ completionHandler: @escaping RequestDidCompleteBlock) {
        if validate() {
            updateModel()
            if let user = model {
                
                User.update(user) {[weak self] (result, error) in
                    guard let strongSelf = self else { return }
                    if error == nil {
                        strongSelf.updatePasswordIfNeeded(completionHandler)
                    } else {
                        completionHandler(false, error)
                    }
                }
            }
        } else {
            completionHandler(false, nil)
        }
    }
    
    func saveAbout(_ completionHandler: @escaping RequestDidCompleteBlock) {
        updateModel()
        if let user = model {
            User.updateAbout(user, completionHandler: completionHandler)
            
        }
    }
    
    
    func saveTags(_ completionHandler: @escaping RequestDidCompleteBlock) {
        updateModel()
        if let user = model {
            User.updateTags(newTags.map{Tag(name: $0)}, deletedTags: deletedtags.map{Tag(name: $0)}, user: user, completionHandler: completionHandler)
        }
    }
    
    // signIn
    func signIn(_ completionHandler: @escaping RequestDidCompleteBlock) {
        if loginValidate() {
            let email = (loginRows.value[0] as! EmailFieldViewModel).value.value
            let password = (loginRows.value[1] as! PasswordFieldViewModel).value.value
            Auth.auth().signIn(withEmail: email, password: password) { user, error in
                if error != nil {
                    completionHandler(false, error)
                    return
                }
                User.currentUser({ (result, error) in
                    if error != nil {
                        completionHandler(false, error)
                    } else {
                        PushNotificationManager.shared.registerForPushNotifications()
                        completionHandler(true, nil)
                    }
                })
            }
            return
        }
        completionHandler(false, nil)
    }
    
    // forgot password
    func forgotPassword(_ completionHandler: @escaping RequestDidCompleteBlock) {
        let fieldViewModel = (loginRows.value[0] as! EmailFieldViewModel)        
        if fieldViewModel.validate() {
            Auth.auth().sendPasswordReset(withEmail: fieldViewModel.value.value) { error in
                if error == nil {
                    completionHandler(true, nil)
                } else {
                    completionHandler(false, error!)
                }
            }
        }
    }
    
    static func isEmailAlreadyRegisted(_ email: String, completionHandler: @escaping (Bool) -> Void) {
        Auth.auth().fetchSignInMethods(forEmail: email, completion: {
            (providers, error) in
            
            if error != nil {
                completionHandler(false)
            } else if let providers = providers {
                completionHandler(!providers.isEmpty)
            }
        })
    }
}


