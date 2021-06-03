//
//  SceneDelegate.swift
//  CoreLocationTests
//
//  Created by Максим Казаков on 24.05.2021.
//

import UIKit
import CoreLocation

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    let locationManager = CLLocationManager()
    
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        locationManager.delegate = self
    }
}

// MARK: - Location Manager Delegate
extension SceneDelegate: CLLocationManagerDelegate {
    func locationManager(
        _ manager: CLLocationManager,
        didEnterRegion region: CLRegion
    ) {
        NotificationCenter.default.post(name: Notification.Name.enterRegion, object: nil)
        if region is CLCircularRegion {
            handleEvent(for: region)
        }
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didExitRegion region: CLRegion
    ) {
        if region is CLCircularRegion {
            handleEvent(for: region)
        }
    }
    
    func handleEvent(for region: CLRegion) {
        let notificationMessage = "Вы близко к пиццерии!"
        if UIApplication.shared.applicationState == .active {
            window?.rootViewController?.showAlert(withTitle: nil, message: notificationMessage)
        } else {
            let notificationContent = UNMutableNotificationContent()
            notificationContent.body = notificationMessage
            notificationContent.sound = .default
            notificationContent.badge = UIApplication.shared.applicationIconBadgeNumber + 1 as NSNumber
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(
                identifier: "location_change",
                content: notificationContent,
                trigger: trigger)
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error: \(error)")
                }
            }
        }
    }
}

extension UIViewController {
    func showAlert(withTitle title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
}
