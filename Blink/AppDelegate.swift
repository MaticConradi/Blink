//
//  AppDelegate.swift
//  Blink
//
//  Created by Matic Conradi on 06/08/2016.
//  Copyright © 2016 Conradi.si. All rights reserved.
//

import UIKit
import SystemConfiguration
import UserNotifications
import UserNotificationsUI
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    let requestIdentifier = "DailyReminder"
    let center = UNUserNotificationCenter.current()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        UIApplication.shared.applicationIconBadgeNumber = 0
        center.requestAuthorization(options: [.badge, .sound, .alert]) { (granted, error) in }
        self.createLocalNotification()
        return true
    }
    
    func change() {
        if isConnectedToNetwork() {
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let offlineView = mainStoryboard.instantiateViewController(withIdentifier: "PostNavigationViewController") as! PostNavigationController
            window!.rootViewController = offlineView
            window!.makeKeyAndVisible()
        }
    }
    
    func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return (isReachable && !needsConnection)
    }
    
    func createLocalNotification() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        var oneDayfromNow: Date {
            return (Calendar.current as NSCalendar).date(byAdding: .day, value: 1, to: Date(), options: [])!
        }
        
        let cal = Calendar.current
        
        var oneDayfromNowDayTime = (cal as NSCalendar).components([.year, .month, .day, .hour, .minute, .second], from: oneDayfromNow)
        oneDayfromNowDayTime.hour = 8
        oneDayfromNowDayTime.minute = 0
        oneDayfromNowDayTime.second = 0
        
        let content = UNMutableNotificationContent()
        content.body = "A mystery awaits..."
        content.sound = UNNotificationSound.default()
        content.badge = 1
        
        let trigger = UNCalendarNotificationTrigger.init(dateMatching: oneDayfromNowDayTime, repeats: true)
        let request = UNNotificationRequest(identifier:requestIdentifier, content: content, trigger: trigger)
        
        center.add(request)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        print("ℹ️ App will resign active.")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("ℹ️ App did enter background.")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("ℹ️ App did enter foreground.")
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("ℹ️ App did become active.")
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        print("ℹ️ App will terminate.")
    }
}

