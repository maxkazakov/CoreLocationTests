//
//  LocationInfo.swift
//  CoreLocationTests
//
//  Created by Максим Казаков on 26.05.2021.
//

import UIKit
import CoreLocation

struct LocationInfo {
    struct PizzeriaRelated {
        var distanceToPizzeria: Double
        var movingPace: Double? // метр/сек
        var timeToCome: Double? // сек
    }
    
    let location: CLLocation
    let appState: UIApplication.State
    let pizzeriaRelatedInfo: PizzeriaRelated?
}
