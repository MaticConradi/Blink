//
//  SettingsTableViewController.swift
//  Blink
//
//  Created by Matic Conradi on 16/08/2016.
//  Copyright © 2016 Conradi.si. All rights reserved.
//

import UIKit
import CoreData

class SettingsTableViewController: UITableViewController {
    
    //CORE DATA
    var container: NSPersistentContainer!
    var fetchedResultsController: NSFetchedResultsController<Post>!
    var commitPredicate: NSPredicate?
    
    let defaults = UserDefaults.standard
    let currentCal = Calendar(identifier: Calendar.Identifier.gregorian)
    
    var arrayForCheckDefTimes = [Int]()
    
    var numberOfPosts = 0
    var currentDayTime = Date()
    var lastDayTime = Date()
    
    var arrayDefaultPosts = [[String]]()
    var boolDefaultPosts = [Int]()
    
    var progressDefPosts = [false, false, false, false, false, false, false, false, false, false]
    var progressDefOrder = [[Int]]()
    var progressSortedDefOrder = [[Int]]()

    @IBOutlet var settingsTableView: UITableView!
    @IBOutlet weak var button: UIButton!
    
    var window: UIWindow?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        container = NSPersistentContainer(name: "myCoreDataModel")
        
        container.loadPersistentStores { storeDescription, error in
            self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            if let error = error {
                print("🆘 Unresolved error: \(error)")
            }
        }
        
        boolDefaultPosts = defaults.object(forKey: "boolDefaultPosts") as! [Int]
        arrayDefaultPosts = defaults.object(forKey: "arrayDefaultPosts") as! [[String]]
        
        let backButton = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.plain, target: navigationController, action: nil)
        navigationItem.leftBarButtonItem = backButton
        settingsTableView.rowHeight = 120
        settingsTableView.backgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1.0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIView.transition(with: self.view,
                                  duration: 0.3,
                                  options: UIViewAnimationOptions.transitionCrossDissolve,
                                  animations:{
                                    UIApplication.shared.statusBarStyle = .lightContent
                                    self.navigationController?.navigationBar.barTintColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
                                    if let font = UIFont(name: "CenturyCity", size: 20) {
                                        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: font, NSForegroundColorAttributeName: UIColor.white]
                                    }
            },
                                  completion:{
                                    (finished: Bool) -> () in
            }
        )
    }
    
    @IBAction func iconTapped(_ sender:UIButton) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIView.transition(with: self.view,
                                  duration: 0.3,
                                  options: UIViewAnimationOptions.transitionCrossDissolve,
                                  animations:{
                                    UIApplication.shared.statusBarStyle = .default
                                    self.navigationController?.navigationBar.barTintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1.0)
                                    if let font = UIFont(name: "CenturyCity", size: 20) {
                                        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: font, NSForegroundColorAttributeName: UIColor.black]
                                    }
            },
                                  completion:{
                                    (finished: Bool) -> () in
            }
        )
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MySettingCell", for: indexPath) as! SettingsCell
        let arrayTexts: [String] = ["Advice", "Cat facts", "Curiosities", "Mysteries", "Inspiring quotes", "Movie reviews", "News", "Number trivia", "Tech talk", "Weird but trending"]
        let colorValue: CGFloat = 0.10 - 0.005 * (1 + CGFloat((indexPath as NSIndexPath).row))
        cell.backgroundColor = UIColor(red: colorValue, green: colorValue, blue: colorValue, alpha: 1.0)
        cell.myTitle.text = arrayTexts[(indexPath as NSIndexPath).row]
        
        if boolDefaultPosts[(indexPath as NSIndexPath).row] == 1 {
            cell.myTitle.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        }else{
            cell.myTitle.textColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.66)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tapped()
        if boolDefaultPosts[indexPath.row] == 1 {
            boolDefaultPosts[indexPath.row] = 0
            defaults.set(boolDefaultPosts, forKey: "boolDefaultPosts")
        }else{
            defaults.set(true, forKey: "newCategory")
            arrayDefaultPosts = defaults.object(forKey: "arrayDefaultPosts") as! [[String]]
            boolDefaultPosts[indexPath.row] = 1
            defaults.set(boolDefaultPosts, forKey: "boolDefaultPosts")
            addDefPost(indexPath.row)
        }
        saveContext()
        let range = NSMakeRange(0, self.tableView.numberOfSections)
        let sections = IndexSet(integersIn: range.toRange() ?? 0..<0)
        self.tableView.reloadSections(sections, with: .fade)
    }
    
    func tapped() {
        //Generate haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    
    //**********************************
    // MARK: Configure default posts
    //**********************************
    
    func saveContext() {
        if container.viewContext.hasChanges {
            do {
                try container.viewContext.save()
            } catch {
                print("🆘 An error occurred while saving: \(error)")
            }
        }
    }
    
    func configure(post: Post, text: String, condition: String, link: String, time: Int) {
        post.post = text
        post.condition = condition
        post.link = link
        post.time = time
    }
    
    func configDefaultPosts() {
        for i in 0..<self.arrayDefaultPosts.count {
            if self.arrayDefaultPosts[i][1] != "" {
                let arr1 = Int(self.arrayDefaultPosts[i][1])!
                let arr2 = i
                let arr = [arr1, arr2]
                self.progressDefOrder.append(arr)
            }
        }
        
        self.progressSortedDefOrder = self.progressDefOrder.sorted { ($0[0] as Int) < ($1[0] as Int) }
        print("ℹ️ Default posts sorted order: \(progressSortedDefOrder)")
        
        for j in 0..<self.progressSortedDefOrder.count {
            self.addDefPost(self.progressSortedDefOrder[j][1])
        }
    }
    
    func addDefPost(_ i: Int) {
        if self.boolDefaultPosts[i] == 1 && self.arrayDefaultPosts[i][0] != "" && progressDefPosts[i] == false {
            let data = Post(context: self.container.viewContext)
            var time = Int(NSDate().timeIntervalSince1970)
            while arrayForCheckDefTimes.contains(time) {
                time += 1
            }
            arrayForCheckDefTimes.append(time)
            self.configure(post: data, text: self.arrayDefaultPosts[i][0], condition: "\(i + 1)", link: "0" , time: time)
            defaults.set(time, forKey: "lastTime")
            progressDefPosts[i] = true
            print("✅ Added default post: \(self.arrayDefaultPosts[i][0])")
        }else{
            print("🆘 Failed: (\(self.boolDefaultPosts[i]) == 1; \"\(self.arrayDefaultPosts[i][0])\" != \"\"; \(progressDefPosts[i]) == false) for i = \(i): \(self.arrayDefaultPosts[i][0])")
        }
    }
}
