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
    
    //Notifications
    let center = UNUserNotificationCenter.current()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        UIApplication.shared.applicationIconBadgeNumber = 0
        center.requestAuthorization(options: [.badge, .sound, .alert]) { (granted, error) in }
        return true
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        SDImageCache.shared().clearMemory()
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        print("ℹ️ App will resign active.")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("ℹ️ App did enter background.")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("ℹ️ App will enter foreground.")
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("ℹ️ App did become active.")
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        SDImageCache.shared().clearMemory()
        //SDImageCache.shared().clearDisk()
        print("ℹ️ App will terminate.")
    }
}
