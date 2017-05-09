//
//  SettingsTableViewController.swift
//  Blink
//
//  Created by Matic Conradi on 16/08/2016.
//  Copyright © 2016 Conradi.si. All rights reserved.
//

import UIKit
import CoreData

class SettingsCell: UICollectionViewCell {
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var backgroundContainerView: UIView!
}

class SubscriptionsCollectionViewController: UICollectionViewController {
    //OUTLETS
    @IBOutlet var subscriptionsCollectionView: UICollectionView!
    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout!
    
    //CORE DATA
    var container: NSPersistentContainer!
    
    //Stuff
    let defaults = UserDefaults.standard
    
    let arrayCategories = ["Advice", "Cat facts", "Curiosities", "Fortune cookies", "Inspiring quotes", "Is it Friday yet?", "Movie reviews", "News", "Number trivia", "Space photos", "Sports stuff", "Tech talk"]
    var arrayPosts = [String]()
    var arrayTimes = [Int]()
    
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
        collectionViewFlowLayout.estimatedItemSize = CGSize(width: 150, height: 60)
        
        subscriptionsCollectionView.contentInset = UIEdgeInsetsMake(10, 0, 0, 0)
    }
    
    
    //**********************************
    // MARK: TableView
    //**********************************
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrayCategories.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "subscriptionCell", for: indexPath) as! SettingsCell
        
        cell.categoryLabel.text = arrayCategories[indexPath.row]
        
        if boolDefaultPosts[indexPath.row] == 1 {
            cell.backgroundContainerView.backgroundColor = UIColor.black
            cell.categoryLabel.textColor = UIColor.white
            cell.layer.masksToBounds = false
            cell.backgroundContainerView.layer.masksToBounds = false
            cell.backgroundContainerView.layer.shadowColor = UIColor.black.cgColor
            cell.backgroundContainerView.layer.shadowRadius = 20
            cell.backgroundContainerView.layer.shadowOpacity = 0.5
        }else{
            cell.backgroundContainerView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
            cell.categoryLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        tapped()
        loadSavedData()
        if boolDefaultPosts[indexPath.row] == 1 {
            boolDefaultPosts[indexPath.row] = 0
        }else{
            var index = -1
            
            for i in 0..<arrayPosts.count {
                if arrayPosts[i] == arrayDefaultPosts[indexPath.row] {
                    index = i
                }
            }
            
            if index >= 0 {
                if arrayTimes[index] + 43200 < Int(Date().timeIntervalSince1970) && arrayPosts[0] != arrayDefaultPosts[indexPath.row] && arrayPosts[1] != arrayDefaultPosts[indexPath.row] && arrayPosts[2] != arrayDefaultPosts[indexPath.row] && arrayPosts[3] != arrayDefaultPosts[indexPath.row] {
                    defaults.set(true, forKey: "newCategory")
                    addDefPost(indexPath.row)
                }
            }else{
                defaults.set(true, forKey: "newCategory")
                addDefPost(indexPath.row)
            }
            boolDefaultPosts[indexPath.row] = 1
        }
        
        defaults.set(boolDefaultPosts, forKey: "boolDefaultPosts")
        subscriptionsCollectionView.reloadItems(at: [indexPath])
    }
    
    func loadSavedData() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Post")
        
        // Helpers
        var result = [Post]()
        
        arrayPosts.removeAll()
        arrayTimes.removeAll()
        
        do {
            // Execute Fetch Request
            let records = try container.viewContext.fetch(fetchRequest)
            
            if let records = records as? [Post] {
                result = records
            }
            
            var offset = 20
            if result.count < 20 {
                offset = result.count
            }
            
            for i in result.count-offset..<result.count {
                arrayPosts.insert(result[i].post, at: 0)
                arrayTimes.insert(result[i].time, at: 0)
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
        var time = Int(Date().timeIntervalSince1970) + i
        if arrayTimes[0] >= time {
            time = arrayTimes[0] + 1
        }
        configure(post: data, text: arrayDefaultPosts[i], description: "", condition: "\(i + 1)", link: "", image: "", time: time)
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
