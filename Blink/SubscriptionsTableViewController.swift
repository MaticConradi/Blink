//
//  SettingsTableViewController.swift
//  Blink
//
//  Created by Matic Conradi on 16/08/2016.
//  Copyright © 2016 Conradi.si. All rights reserved.
//

import UIKit
import CoreData

class SubscriptionsTableViewController: UITableViewController {
    
    //Outlets
    @IBOutlet var settingsTableView: UITableView!
    
    //CORE DATA
    var container: NSPersistentContainer!
    var fetchedResultsController: NSFetchedResultsController<Post>!
    var commitPredicate: NSPredicate?
    
    //Stuff
    let defaults = UserDefaults.standard
    
    var arrayDefaultPosts = [[String]]()
    var boolDefaultPosts = [Int]()
    
    
    //**********************************
    // MARK: Essential functions
    //**********************************
    
    
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
        
        settingsTableView.rowHeight = 100
        settingsTableView.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 1.0)
        settingsTableView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0)
    }
    
    
    //**********************************
    // MARK: TableView
    //**********************************
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MySettingCell", for: indexPath) as! SettingsCell
        let arrayTexts: [String] = ["Advice", "Cat facts", "Curiosities", "Mysteries", "Inspiring quotes", "Movie reviews", "News", "Number trivia", "Tech talk", "Weird but trending"]
        cell.myTitle.text = arrayTexts[(indexPath as NSIndexPath).row]
        let offColorValue: CGFloat = 0.04 + 0.002 * (CGFloat(arrayTexts.count - (indexPath as NSIndexPath).row))
        
        if boolDefaultPosts[(indexPath as NSIndexPath).row] == 1 {
            cell.myTitle.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
            let colorValue: CGFloat = offColorValue + (0.02 + 0.002 * (CGFloat(arrayTexts.count - (indexPath as NSIndexPath).row)))
            cell.backgroundColor = UIColor(red: colorValue, green: colorValue, blue: colorValue, alpha: 1.0)
        }else{
            cell.myTitle.textColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 0.5)
            cell.backgroundColor = UIColor(red: offColorValue, green: offColorValue, blue: offColorValue, alpha: 1.0)
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
            boolDefaultPosts[indexPath.row] = 1
            defaults.set(boolDefaultPosts, forKey: "boolDefaultPosts")
            addDefPost(indexPath.row)
        }
        saveContext()
        let range = NSMakeRange(0, self.tableView.numberOfSections)
        let sections = IndexSet(integersIn: range.toRange() ?? 0..<0)
        self.tableView.reloadSections(sections, with: .fade)
    }
    
    
    //**********************************
    // MARK: Configure default posts
    //**********************************
    
    
    func addDefPost(_ i: Int) {
        let data = Post(context: container.viewContext)
        
        configure(post: data, text: arrayDefaultPosts[i][0], description: "", condition: "\(i + 1)", link: "0", image: "0", time: i + 1)
        saveContext()
    }
    
    func saveContext() {
        if container.viewContext.hasChanges {
            do {
                try container.viewContext.save()
            } catch {
                print("🆘 An error occurred while saving: \(error)")
            }
        }
    }
    
    func configure(post: Post, text: String, description: String, condition: String, link: String, image: String, time: Int) {
        post.post = text
        post.desc = description
        post.condition = condition
        post.link = link
        post.image = image
        post.time = time
    }
    
    
    //**********************************
    // MARK: Other methods
    //**********************************
    
    
    func tapped() {
        //Generate haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}
