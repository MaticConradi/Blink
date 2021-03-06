//
//  AboutTableViewController.swift
//  Blink
//
//  Created by Matic Conradi on 09/02/2017.
//  Copyright © 2017 Conradi.si. All rights reserved.
//

import UIKit
import SafariServices
import UserNotifications
import UserNotificationsUI

class AboutTableViewController: UITableViewController {
    let defaults = UserDefaults.standard
    let currentCal = Calendar(identifier: Calendar.Identifier.gregorian)
    
    let requestIdentifier = "DailyReminder"
    let center = UNUserNotificationCenter.current()
    let calendar = Calendar.current
    
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    
    @IBOutlet var aboutTableView: UITableView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var notifications: UISwitch!
    @IBOutlet weak var feedback: UISwitch!
    @IBOutlet weak var datePickerLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var notificationTime = (calendar as NSCalendar).components([.year, .month, .day, .hour, .minute, .second], from: Date())
        notificationTime.hour = defaults.integer(forKey: "notificationTimeHour")
        notificationTime.minute = defaults.integer(forKey: "notificationTimeMinute")
        
        datePicker.date = calendar.date(from: notificationTime)!
        notifications.isOn = defaults.bool(forKey: "dailyNotifications")
        if defaults.bool(forKey: "dailyNotifications") {
            self.datePickerLabel.layer.opacity = 1
            self.datePicker.layer.opacity = 1
        }else{
            self.datePickerLabel.layer.opacity = 0.4
            self.datePicker.layer.opacity = 0.2
        }
        feedback.isOn = defaults.bool(forKey: "shakeToSendFeedback")
        
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowRadius = 25
        cardView.layer.shadowOpacity = 0.15
        
        if UIScreen.main.bounds.size.width < UIScreen.main.bounds.size.height {
            widthConstraint.constant = UIScreen.main.bounds.size.width - 70
        }else{
            widthConstraint.constant = UIScreen.main.bounds.size.height - 70
        }
        
        aboutTableView.contentInset = UIEdgeInsetsMake(0, 0, 64, 0)
    }
    
    @IBAction func notificationsChanged(_ sender: UISwitch) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        defaults.set(notifications.isOn, forKey: "dailyNotifications")
        if notifications.isOn {
            createLocalNotification()
            UIView.animate(withDuration: 0.3, animations: {
                self.datePickerLabel.layer.opacity = 1
                self.datePicker.layer.opacity = 1
            })
        }else{
            UIView.animate(withDuration: 0.3, animations: {
                self.datePickerLabel.layer.opacity = 0.4
                self.datePicker.layer.opacity = 0.2
            })
        }
    }
    
    @IBAction func feedbackChanged(_ sender: UISwitch) {
        defaults.set(feedback.isOn, forKey: "shakeToSendFeedback")
    }
    
    @IBAction func timeChanged(_ sender: UIDatePicker) {
        notifications.setOn(true, animated: true)
        UIView.animate(withDuration: 0.3, animations: {
            self.datePickerLabel.layer.opacity = 1
            self.datePicker.layer.opacity = 1
        })
        
        defaults.set(true, forKey: "dailyNotifications")
        let notificationTime = (calendar as NSCalendar).components([.year, .month, .day, .hour, .minute, .second], from: datePicker.date)
        defaults.set(notificationTime.hour, forKey: "notificationTimeHour")
        defaults.set(notificationTime.minute, forKey: "notificationTimeMinute")
        createLocalNotification()
    }
    
    func tapped() {
        //Generate haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 1 {
            UIApplication.shared.open(URL(string: "http://www.conradi.si")!, options: [:], completionHandler: {(true) in })
        }
    }
    
    func createLocalNotification() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        var oneDayfromNow: Date {
            return (Calendar.current as NSCalendar).date(byAdding: .day, value: 1, to: Date(), options: [])!
        }
        
        var notificationTime = (calendar as NSCalendar).components([.year, .month, .day, .hour, .minute, .second], from: oneDayfromNow)
        notificationTime.hour = defaults.integer(forKey: "notificationTimeHour")
        notificationTime.minute = defaults.integer(forKey: "notificationTimeMinute")
        
        let content = UNMutableNotificationContent()
        content.body = "I have something for you..."
        content.sound = UNNotificationSound.default()
        content.badge = 1
        
        let trigger = UNCalendarNotificationTrigger.init(dateMatching: notificationTime, repeats: true)
        let request = UNNotificationRequest(identifier:requestIdentifier, content: content, trigger: trigger)
        
        center.add(request)
    }
}
