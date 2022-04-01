//
//  MapViewController.swift
//  LedgerLinkV2
//
//  Created by J C on 2022-03-31.
//

/*
 Abstract:
 Shows the location of the user in order to estimate the distance to the host since the connectivity is important.
 */

import UIKit
import MapKit
import Intents /// for CLPlacemark
import Contacts /// CLPlacemark

final class MapViewController: UIViewController {
    private var mapView: MKMapView!
    private var locationManager: CLLocationManager!
    private let regionRadius: CLLocationDistance = 200 /// For the map center zoom in
    private let radius: CLLocationDistance = 80 /// For showing the circle radius of the host
    private var mapTypeStackView: UIStackView!
    private var pinStackView: UIStackView!
    private var hostLocation: CLLocationCoordinate2D!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        checkLocationServices()
        setConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = UIColor.clear
    }
    
    private func configureUI() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: <#T##UIImage?#>, style: <#T##UIBarButtonItem.Style#>, target: <#T##Any?#>, action: <#T##Selector?#>)
        
        mapView = MKMapView()
        mapView.userTrackingMode = .follow
        mapView.mapType = .hybrid
        mapView.showsUserLocation = true
        mapView.delegate = self
        view.addSubview(mapView)
        mapView.setFill()
        
        /// The host location delegate fetches the location of the host during the process of VerifyBlock as a non-validator
        Node.shared.hostLocationDelegate = self
        
        let button0 = createMapTypeButton(title: "Standard", tag: 0)
        let button1 = createMapTypeButton(title: "Satellite", tag: 1)
        let button2 = createMapTypeButton(title: "Hybrid", tag: 2)
        let button4 = createMapTypeButton(title: "Flyover", tag: 4)
        let button5 = createMapTypeButton(title: "Muted", tag: 5)
        
        mapTypeStackView = UIStackView(arrangedSubviews: [button0, button1, button2, button4, button5])
        mapTypeStackView.clipsToBounds = true
        mapTypeStackView.layer.cornerRadius = 10
        mapTypeStackView.axis = .vertical
        mapTypeStackView.distribution = .fillEqually
        mapTypeStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapTypeStackView)
        
        let myLocationButton = createMapTypeButton(title: "Me", tag: 6)
        let hostLocationButton = createMapTypeButton(title: "Host", tag: 7)
        
        pinStackView = UIStackView(arrangedSubviews: [myLocationButton, hostLocationButton])
        pinStackView.clipsToBounds = true
        pinStackView.layer.cornerRadius = 10
        pinStackView.axis = .horizontal
        pinStackView.distribution = .fillEqually
        pinStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pinStackView)
    }
    
    private func setConstraints() {
        NSLayoutConstraint.activate([
            mapTypeStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            mapTypeStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            mapTypeStackView.widthAnchor.constraint(equalToConstant: 50),
            mapTypeStackView.heightAnchor.constraint(equalToConstant: 250),
            
            pinStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            pinStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pinStackView.widthAnchor.constraint(equalToConstant: 120),
            pinStackView.heightAnchor.constraint(equalToConstant: 40),
        ])
    }
    
    @objc func buttonPressed(_ sender: UIButton) {
        switch sender.tag {
            case 0:
                mapView.mapType = .standard
            case 1:
                mapView.mapType = .satellite
            case 2:
                mapView.mapType = .hybrid
            case 3:
                mapView.mapType = .satelliteFlyover
            case 4:
                mapView.mapType = .hybridFlyover
            case 5:
                mapView.mapType = .mutedStandard
            case 6:
                guard let coordinate = locationManager.location?.coordinate else {return}
                centerMapOnLocation(coordinate: coordinate)
            case 7:
                guard let coordinate = hostLocation else { return }
                centerMapOnLocation(coordinate: coordinate)
            default:
                break
        }
    }
    
    private func createMapTypeButton(title: String, tag: Int) -> UIButton {
        let button = UIButton()
        let attTitle = createAttributedString(imageString: nil, imageColor: nil, text: title, textColor: .lightGray, fontSize: 8)
        button.setAttributedTitle(attTitle, for: .normal)
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        button.tag = tag
        button.backgroundColor = .black
        return button
    }
    
    private func centerMapOnLocation(coordinate: CLLocationCoordinate2D) {
        let coordinateRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    // MARK:- Location permission
    private func checkLocationServices() {
        locationManager = NetworkManager.shared.locationManager
        locationManager.delegate = self
        
        if CLLocationManager.locationServicesEnabled() {
            checkLocationAuthorization()
        } else {
            showAlert()
        }
    }

    private func checkLocationAuthorization() {
        
        switch locationManager.authorizationStatus {
            case .authorizedWhenInUse:
                guard let coordinate = locationManager.location?.coordinate else {return}
                centerMapOnLocation(coordinate: coordinate)
                break
            case .denied:
                showAlert()
            case .notDetermined:
                locationManager.requestAlwaysAuthorization()
            case .restricted:
                showAlert()
            case .authorizedAlways:
                break
            default:
                break
        }
    }
    
    /// Explains to the new user how the backgrounding will trigger the beeping sound
    private func showAlert() {
        // delete
        let content = [
            StandardAlertContent(
                titleString: "Welcome!",
                body: ["": "The app requires the location tracking to be authorized. Please go to your Settings -> Privacy -> Location Services enable it."],
                fieldViewHeight: 200,
                messageTextAlignment: .left,
                alertStyle: .oneButton,
                buttonAction: { [weak self](_) in
                    self?.dismiss(animated: true, completion: nil)
                },
                borderColor: UIColor.clear.cgColor
            )
        ]
        
        let alertVC = AlertViewController(height: 400, standardAlertContent: content)
        alertVC.action = { [weak self] (modal, mainVC) in
            mainVC.buttonAction = { _ in
                
                self?.dismiss(animated: true, completion: {
                    
                })
            }
        }
        self.present(alertVC, animated: true, completion: nil)
    }
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard UserDefaults.standard.bool(forKey: UserDefaultKey.distanceNotificationAllowed),
            let location = locations.last as CLLocation? else {
            return
        }
        
        let hostCLLocation = CLLocation(latitude: hostLocation.latitude, longitude: hostLocation.longitude)
        
        guard hostCLLocation.distance(from: location) > radius else {
            return
        }
        
        /// Only send a notification if there is no notification sent already
        NetworkManager.shared.getDeliveredNotifications { notifications in
            guard notifications.count == 0 else { return }
            NetworkManager.shared.sendNotification(notificationType: "You are too far away from the host. The transactions may not work.")
        }
    }
}

// MARK: - HostLocationDelegate
extension MapViewController: HostLocationDelegate, MKMapViewDelegate {
    /// The location of the host is fetched from VerifyBlock in Node+CreateBlock when the block is verified as a non-validator.
    /// The extra data in the block is sent through a delegate.
    
    func didGetHostLocation(_ coordinate: HostLocation) {
        guard let latitude = Double(coordinate.latitude),
              let longitude = Double(coordinate.longitude) else { return }
        
        hostLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        showCircle(coordinate: hostLocation, radius: radius)
        dropPinZoomIn(location: hostLocation)
    }
    
    // Radius is measured in meters
    func showCircle(coordinate: CLLocationCoordinate2D,
                    radius: CLLocationDistance) {
        let circle = MKCircle(center: coordinate,
                              radius: radius)
        
        mapView.overlays.forEach { mapView.removeOverlay($0) }
        mapView.addOverlay(circle)
    }
    
    func mapView(_ mapView: MKMapView,
                 rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let circleRenderer = MKCircleRenderer(overlay: overlay)
        circleRenderer.fillColor = .green
        circleRenderer.alpha = 0.4
        
        return circleRenderer
    }
    
    private func dropPinZoomIn(location: CLLocationCoordinate2D) {
//        let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let clPlacemark = CLPlacemark(location: clLocation, name: "Host", postalAddress: nil)
        let placemark = MKPlacemark(placemark: clPlacemark)
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(placemark)
    }
}

protocol HostLocationDelegate: AnyObject {
    func didGetHostLocation(_ coordinate: HostLocation)
}
