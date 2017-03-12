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
    
    //Stuff
    let defaults = UserDefaults.standard
    
    let arrayCategories = ["Advice", "Cat facts", "Curiosities", "Mysteries", "Inspiring quotes", "Movie reviews", "News", "Number trivia", "Space photo of the day", "Tech talk", "Weird but trending"]
    var arrayPosts = [String]()
    
    var arrayDefaultPosts = [String]()
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
        arrayDefaultPosts = defaults.object(forKey: "arrayDefaultPosts") as! [String]
        
        settingsTableView.rowHeight = 100
        settingsTableView.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 1.0)
        settingsTableView.contentInset = UIEdgeInsetsMake(UIApplication.shared.statusBarFrame.height + self.navigationController!.navigationBar.frame.height, 0, 0, 0)
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        settingsTableView.contentInset = UIEdgeInsetsMake(UIApplication.shared.statusBarFrame.height + self.navigationController!.navigationBar.frame.height, 0, 0, 0)
    }
    
    
    //**********************************
    // MARK: TableView
    //**********************************
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayCategories.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MySettingCell", for: indexPath) as! SettingsCell
        cell.myTitle.text = arrayCategories[(indexPath as NSIndexPath).row]
        let offColorValue: CGFloat = 0.04 + 0.002 * (CGFloat(arrayCategories.count - (indexPath as NSIndexPath).row))
        
        if boolDefaultPosts[(indexPath as NSIndexPath).row] == 1 {
            cell.myTitle.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
            let colorValue: CGFloat = offColorValue + (0.02 + 0.002 * (CGFloat(arrayCategories.count - (indexPath as NSIndexPath).row)))
            cell.backgroundColor = UIColor(red: colorValue, green: colorValue, blue: colorValue, alpha: 1.0)
        }else{
            cell.myTitle.textColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 0.5)
            cell.backgroundColor = UIColor(red: offColorValue, green: offColorValue, blue: offColorValue, alpha: 1.0)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tapped()
        loadSavedData()
        if boolDefaultPosts[indexPath.row] == 1 {
            boolDefaultPosts[indexPath.row] = 0
        }else if !arrayPosts.contains(arrayDefaultPosts[indexPath.row]){
            defaults.set(true, forKey: "newCategory")
            boolDefaultPosts[indexPath.row] = 1
            addDefPost(indexPath.row)
        }else{
            boolDefaultPosts[indexPath.row] = 1
        }
        defaults.set(boolDefaultPosts, forKey: "boolDefaultPosts")
        settingsTableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    func loadSavedData() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Post")
        
        // Helpers
        var result = [Post]()
        
        arrayPosts.removeAll()
        
        do {
            // Execute Fetch Request
            let records = try container.viewContext.fetch(fetchRequest)
            
            if let records = records as? [Post] {
                result = records
            }
            
            for i in result.count-4..<result.count {
                self.arrayPosts.insert(result[i].post, at: 0)
            }
        } catch {
            print("🆘 Unable to fetch managed objects for entity Post.")
        }
    }
    
    
    //**********************************
    // MARK: Add default posts
    //**********************************
    
    
    func addDefPost(_ i: Int) {
        let data = Post(context: container.viewContext)
        
        configure(post: data, text: arrayDefaultPosts[i], description: "", condition: "\(i + 1)", link: "", image: "", time: i + 1)
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
