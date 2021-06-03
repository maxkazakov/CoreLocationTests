//
//  AuthViewController.swift
//  CoreLocationTests
//
//  Created by Максим Казаков on 04.05.2021.
//

import UIKit
import CoreLocation

class AuthViewController: UIViewController {

    lazy var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
    }

    @IBOutlet weak var authStatusLabel: UILabel!
    
    @IBAction func openSettings(_ sender: Any) {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                print("Settings opened: \(success)")
            })
        }
    }
    
    @IBAction func authWhenInUse(_ sender: Any) {
        locationManager.requestWhenInUseAuthorization()
    }
    
    @IBAction func authAlways(_ sender: Any) {
        locationManager.requestAlwaysAuthorization()
    }
}

extension AuthViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        authStatusLabel.text = status.stringValue
    }
}

// MARK: -

extension CLAuthorizationStatus {
    var stringValue: String {
        switch self {
        case .notDetermined:
            return "notDetermined"
        case .restricted:
            return "restricted"
        case .denied:
            return "denied"
        case .authorizedAlways:
            return "authorizedAlways"
        case .authorizedWhenInUse:
            return "authorizedWhenInUse"
        @unknown default:
            return "unknown"
        }
    }
}
