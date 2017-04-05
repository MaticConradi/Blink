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
    
    let arrayCategories = ["Advice", "Cat facts", "Curiosities", "Fortune cookies", "Inspiring quotes", "Is it Friday yet?", "Movie reviews", "News", "Number trivia", "Space photo of the day", "Sports stuff", "Tech talk", "Weird but trending"]
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
        collectionViewFlowLayout.estimatedItemSize = CGSize(width: 150, height: 60)
        
        let gradient = CAGradientLayer()
        
        gradient.frame = subscriptionsCollectionView.superview?.bounds ?? CGRect.null
        gradient.colors = [UIColor.clear.cgColor, UIColor.black.cgColor, UIColor.black.cgColor]
        gradient.locations = [0.0, 0.05, 1.0]
        subscriptionsCollectionView.superview?.layer.mask = gradient
        subscriptionsCollectionView.contentInset = UIEdgeInsetsMake(10, 0, 0, 0)
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        subscriptionsCollectionView.reloadData()
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
        }else if !arrayPosts.contains(arrayDefaultPosts[indexPath.row]) {
            defaults.set(true, forKey: "newCategory")
            boolDefaultPosts[indexPath.row] = 1
            addDefPost(indexPath.row)
        }else{
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
