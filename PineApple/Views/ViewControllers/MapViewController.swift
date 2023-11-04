//
//  MapViewController.swift
//  PineApple
//
//  Created by Tao Man Kit on 15/8/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import UIKit
import GoogleMaps
import Alamofire
import GoogleMapsDirections
import GooglePlaces
import RxCocoa
import RxSwift
import ViewAnimator
import UPCarouselFlowLayout

class MapViewController: BaseViewController, ViewModelBased {
    
    // MARK: - Properties
    private var mapView: GMSMapView!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var toggleTravelModeButton: UIButton!
    @IBOutlet weak var dropdownView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchFieldBaseView: UIView!
    @IBOutlet weak var dropdownViewHeight: NSLayoutConstraint!
    
    private var zoomLevel: Float = 15.0
    private let defaultLocation = (latitude: -33.915846, longitude: 151.044273)
    var viewModel: MapViewModel!
    private var markers = [GMSMarker]()
    private var polyline: GMSPolyline?
    var keyboardHeight: CGFloat = 0
    private var pageSize: CGSize {
        let layout = self.collectionView.collectionViewLayout as! UPCarouselFlowLayout
        var pageSize = layout.itemSize
        pageSize.width += layout.minimumLineSpacing
        return pageSize
    }
    typealias AddActivityBlock = () -> Void
    var addActivityBlock: AddActivityBlock?
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - View Life Cycle
extension MapViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        LocationController.shared.startUpdatingLocation()
        configureNavigationBar()
        configureSearchField()
        configureCollectionView()
        configureMapView()
        addMarkers()
        drawDirectionPath()
        bindViewModel(viewModel)
        bindAction()
        addKeyboardNotification()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        selectActivity(at: viewModel.selectedActivityIndex)
        
        if viewModel.isEditing {
            showSnackbar("Hold the pin to change location", topMargin: 145)
        } else {
            showSnackbar("Hold the activity card to open in maps app")
        }
    }
    
}

// MARK: - RX
extension MapViewController {
    
    func bindViewModel(_ viewModel: MapViewModel) {
        self.viewModel = viewModel
        
        searchFieldBaseView.isHidden = !viewModel.isEditing
        toggleTravelModeButton.isHidden = viewModel.isEditing
        
        viewModel.predictions
            .bind(to: tableView.rx.items(cellIdentifier: "PredictionCell", cellType: TableViewCell.self)) { row, model, cell in
                cell.labels!.first?.text = model.attributedPrimaryText.string
                cell.labels![1].text = model.attributedSecondaryText?.string ?? ""
                cell.labels!.first?.font = Styles.customFontBold(17)
                cell.labels![1].font = Styles.customFont(14)
                
        }.disposed(by: disposeBag)
        
        viewModel.activityViewModels
            .bind(to: collectionView.rx.items(cellIdentifier: "MapActivityCollectionViewCell", cellType: MapActivityCollectionViewCell.self)) { (row, element, cell) in
                cell.bindViewModel(element)
        }.disposed(by: disposeBag)
        
        viewModel.refreshMarkers
            .filter{$0}
            .asObservable()
            .subscribe(onNext: {[weak self] _ in
                guard let strongSelf = self else { return }
                
                let index = strongSelf.viewModel.selectedActivityIndex
                
                strongSelf.markers.forEach{
                    $0.isDraggable = false
                    $0.icon = #imageLiteral(resourceName: "pinMap")
                }
                
                if index <= strongSelf.markers.count - 1 {
                    let location = viewModel.location(with: index)
                    let position = strongSelf.markers[index].position
                    if location.latitude != position.latitude ||
                        location.longitude != position.longitude {
                        strongSelf.markers[index].position = location
                        // redraw the path if marker position is updated
                        strongSelf.drawDirectionPath()
                    }
                    strongSelf.updateCameraPosition(location: location)
                    
                    let marker = strongSelf.markers[index]
                    if strongSelf.viewModel.isEditing {
                        marker.isDraggable = true
                    }
                    marker.icon = #imageLiteral(resourceName: "pinMap_selected")
                }
            }).disposed(by: disposeBag)
    }
    
    func bindAction() {
        
        toggleTravelModeButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.toggleTravelModeButton.isSelected = !strongSelf.toggleTravelModeButton.isSelected
                strongSelf.viewModel.isWalking = !strongSelf.toggleTravelModeButton.isSelected
                strongSelf.drawDirectionPath()
        }.disposed(by: disposeBag)
        
        clearButton.rx.tap
            .bind{ [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.searchTextField.text = ""
                strongSelf.viewModel.predictions.accept([])
        }.disposed(by: disposeBag)
        
        tableView.rx.itemSelected
            .bind {[weak self] indexPath in
                guard let strongSelf = self else { return }
                let placeID = strongSelf.viewModel.predictions.value[indexPath.row].placeID
                strongSelf.viewModel.fetchLocationByPlaceID(placeID)
                strongSelf.searchTextField.resignFirstResponder()
                strongSelf.searchTextField.text = ""
                strongSelf.tableView.deselectRow(at: indexPath, animated: true)
                
        }.disposed(by: disposeBag)
        
        collectionView.rx.itemSelected
            .bind {[weak self] indexPath in
                guard let strongSelf = self else { return }
                if indexPath.row == strongSelf.viewModel.activityViewModels.value.count-1, strongSelf.viewModel.isEditing {
                    strongSelf.dismiss(animated: false, completion: {
                        strongSelf.addActivityBlock?()
                    })
                } else {
                    strongSelf.selectActivity(at: indexPath.row)
                    if !strongSelf.viewModel.isEditing {
                        strongSelf.showMapActionSheet(strongSelf.viewModel.activityViewModels.value[indexPath.row])
                    }
                }
        }.disposed(by: disposeBag)
    }
}

// MARK: - Private
extension MapViewController {
        
    func showMapActionSheet(_ activityViewModel: ActivityViewModel) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let googleAction = UIAlertAction(title: "Google Maps",
                                         style: .default) { (action) in
                                            if let latitude = activityViewModel.location?.latitude, let longitude = activityViewModel.location?.longitude {
                                                let url = URL(string:"comgooglemapsurl://maps.google.com/?q=\(latitude),\(longitude)")!
                                                if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)) {
                                                    UIApplication.shared.open(url, completionHandler: { (success) in
                                                        print("Opened: \(success)") // Prints true
                                                    })
                                                }
                                                
                                            }}
        
        let mapAction = UIAlertAction(title: "Maps",
                                      style: .default) { (action) in
                                        if let latitude = activityViewModel.location?.latitude, let longitude = activityViewModel.location?.longitude {
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
        present(alertController, animated: true, completion: nil)
    }
    
    override func goBack() {
        viewModel.undoAll()
        super.goBack()
    }
    
    private func selectActivity(at index: Int) {
        collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: true)
        viewModel.selectedActivityIndex = index
        viewModel.refreshMarkers.accept(true)
    }
    
    @objc private func updateLocation() {
        goBackHero()
    }
    
    private func configureNavigationBar() {
        title = viewModel.isEditing ? "Edit location" : "How to get there"
        addHeroBackButton()
        if viewModel.isEditing {
            navigationController?.navigationBar.tintColor = Styles.p8437FF
            let item = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(MapViewController.updateLocation))
            item.setTitleTextAttributes(Styles.navigationBarItemAttributes, for: .normal)
            navigationItem.rightBarButtonItem = item
        }
    }
    
    private func configureSearchField() {
        searchFieldBaseView.layer.masksToBounds = false
        searchTextField.clearButtonMode = .never
//        searchTextField.addInputAccessoryView(with: self, doneAction: #selector(self.dismissKeyboard))
    }
    
    private func configureCollectionView() {
        let layout = UPCarouselFlowLayout()
        layout.itemSize = CGSize(width: view.bounds.width-130, height: 170)
        layout.scrollDirection = .horizontal
        layout.sideItemScale = 1
        layout.sideItemAlpha = 1
        layout.spacingMode = .overlap(visibleOffset: 69)
        collectionView.collectionViewLayout = layout
        collectionView.delegate = self
    }
    
    private func updateCameraPosition(location: CLLocationCoordinate2D) {
        let cameraPosition = GMSCameraPosition.camera(withLatitude: location.latitude,
                                          longitude: location.longitude,
                                          zoom: zoomLevel)
        mapView.animate(to: cameraPosition)
    }
    
    private func configureMapView() {
        var camera: GMSCameraPosition
        let index = viewModel.selectedActivityIndex
        if let location = viewModel.itineraryViewModel.activityViewModels[index].location, location.latitude != 0, location.longitude != 0 {
            camera = GMSCameraPosition.camera(withLatitude: location.latitude,
                                                         longitude: location.longitude,
                                                         zoom: zoomLevel)
        } else {
            camera = GMSCameraPosition.camera(withLatitude: defaultLocation.latitude,
                                              longitude: defaultLocation.longitude,
                                              zoom: zoomLevel)
        }
        
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        mapView.settings.myLocationButton = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.isMyLocationEnabled = true
        mapView.delegate = self
        
        do {
            if let styleURL = Bundle.main.url(forResource: "MapStyle", withExtension: "json") {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } else {
                NSLog("Unable to find style.json")
            }
        } catch {
            NSLog("One or more of the map styles failed to load. \(error)")
        }
        
        view.insertSubview(mapView, belowSubview: collectionView)        
    }
    
    private func drawDirectionPath() {
        viewModel.fetchDirection {[weak self] (route) in
            guard let strongSelf = self else { return }
            let routeOverviewPolyline = route.overviewPolylinePoints
            let path = GMSPath.init(fromEncodedPath: routeOverviewPolyline!)
            if strongSelf.polyline == nil {
                strongSelf.polyline = GMSPolyline.init(path: path)
                strongSelf.polyline?.strokeColor = Styles.p8437FF
                strongSelf.polyline?.strokeWidth = 4
                strongSelf.polyline?.map = strongSelf.mapView
            } else {
                strongSelf.polyline?.path = path
            }            
        }
    }
    
    private func addMarkers() {
        var index = 0
        
        viewModel.itineraryViewModel.activityViewModels.forEach {
            let _location = viewModel.getValidLocation($0.location)
        
            
            let isSelected = index == viewModel.selectedActivityIndex
            let marker = GMSMarker()
            marker.icon = isSelected ? #imageLiteral(resourceName: "pinMap_selected") : #imageLiteral(resourceName: "pinMap")
            marker.isDraggable = viewModel.isEditing ? isSelected : false
            marker.position = CLLocationCoordinate2D(latitude: _location.latitude, longitude: _location.longitude)
            marker.map = mapView
            
            markers.append(marker)
            index += 1
        }
        
    }
    
}

// MARK: - UITextFieldDelegate
extension MapViewController: UITextFieldDelegate {
    @IBAction func textFieldValueDidChanged(_ sender: Any) {
        if let text = searchTextField.text {
            viewModel.fetchPlaces(keyword: text)
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        dropdownView.fadeIn(duration: 0.2, completion: nil)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        dropdownView.fadeOut(duration: 0.2, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchTextField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        dropdownView.fadeOut(duration: 0.2, completion: nil)
        return true
    }
}

// MARK: - GMSMapViewDelegate
extension MapViewController : GMSMapViewDelegate {
    
    func mapView (_ mapView: GMSMapView, didEndDragging didEndDraggingMarker: GMSMarker) {
        let index = markers.firstIndex(of: didEndDraggingMarker) ?? 0
        let newModel = viewModel.itineraryViewModel
        let activityViewModel = (newModel.rows.value[index+1] as! ActivityViewModel)
        activityViewModel.locationToString = true
        activityViewModel.location = didEndDraggingMarker.position
        viewModel.refreshMarkers.accept(true)
        drawDirectionPath()
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        let index = markers.firstIndex(of: marker) ?? 0
        collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: .centeredHorizontally, animated: true)
        viewModel.selectedActivityIndex = index
        viewModel.refreshMarkers.accept(true)
        return false
    }
    
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        zoomLevel = position.zoom
    }
}

extension MapViewController: UICollectionViewDelegate {}

// MARK: - UIScrollViewDelegate
extension MapViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let layout = self.collectionView.collectionViewLayout as! UPCarouselFlowLayout
        let pageSide = (layout.scrollDirection == .horizontal) ? self.pageSize.width : self.pageSize.height
        let offset = (layout.scrollDirection == .horizontal) ? scrollView.contentOffset.x : scrollView.contentOffset.y
        viewModel.selectedActivityIndex = Int(floor((offset - pageSide / 2) / pageSide) + 1)
        viewModel.refreshMarkers.accept(true)
    }
}

// MARK: - Keyboard
extension MapViewController {
    private func addKeyboardNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification ) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            keyboardHeight = keyboardRectangle.height
            dropdownViewHeight.constant = view.height - (searchFieldBaseView.frame.minY + searchFieldBaseView.frame.height/2) - keyboardHeight - 4
        }
    }
}

