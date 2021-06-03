//
//  ListLocationsViewController.swift
//  CoreLocationTests
//
//  Created by Максим Казаков on 04.05.2021.
//

import UIKit

class ListLocationsViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.locationsDidUpdate,
            object: nil,
            queue: nil,
            using: { _ in
                self.tableView.reloadData()
            }
        )
    }
    
    @IBAction func onupdate(_ sender: Any) {
        tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    var data: [LocationInfo] {
        return LocationsStorage.shared.allLocations.reversed()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell") as! LocationCell
        let row = indexPath.row
        let location = data[row]
        let isBg = location.appState == .background
        let diff: String
        if row == data.count - 1 {
            diff = "0"
        } else {
            let next = data[row + 1]
            let diffDouble = abs(next.location.distance(from: location.location))
            diff = String(format: "%.1f", diffDouble)
        }
        
        let accString = String(format: "%.1f", location.location.horizontalAccuracy)
        cell.setup(
            isBg: isBg,
            diff: diff,
            accuracy: accString,
            isOdd: indexPath.row % 2 == 0,
            timestamp: location.location.timestamp,
            toPizzeria: location.pizzeriaRelatedInfo
        )
        return cell
    }
}

class LocationCell: UITableViewCell {
    @IBOutlet weak var dataLabel: UILabel!
    
    @IBOutlet weak var timeToPizzeriaLabel: UILabel!
    func setup(
        isBg: Bool,
        diff: String,
        accuracy: String,
        isOdd: Bool,
        timestamp: Date,
        toPizzeria: LocationInfo.PizzeriaRelated?
    ) {
        if isOdd {
            backgroundColor = UIColor.secondarySystemGroupedBackground
        } else {
            backgroundColor = UIColor.systemGroupedBackground
        }
        let bgString = isBg ? "Background. " : ""
        let time = Self.timeFormatter.string(from: timestamp)
        dataLabel.text = "\(bgString)Diff: \(diff). Acc: \(accuracy), Time: \(time)"
        
        if let toPizzeria = toPizzeria {
            timeToPizzeriaLabel.isHidden = false
            let distanceFormatted = String(format: "%.1f", toPizzeria.distanceToPizzeria)
            var text = "Distance to: \(distanceFormatted) m"
            
            if let timeToPizzeria = toPizzeria.timeToCome {
                let formattedString = Self.timeToPizzeriaFormatter.string(from: TimeInterval(timeToPizzeria))!
                text += ". Time to: \(formattedString)"
            }
            
            if let movingPace = toPizzeria.movingPace {
                let kmPerHour = movingPace * 3600 / 1000
                let paceFormatted = String(format: "%.1f", kmPerHour)
                text += ". Pace: \(paceFormatted) km/h"
            }
            
            timeToPizzeriaLabel.text = text
        } else {
            timeToPizzeriaLabel.isHidden = true
        }
    }
    
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
    
    static let timeToPizzeriaFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
}
