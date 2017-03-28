//
//  PostsCollectionViewController.swift
//  Blink
//
//  Created by Matic Conradi on 06/08/2016.
//  Copyright © 2016 Conradi.si. All rights reserved.
//

import UIKit
import SafariServices
import CoreData
import SystemConfiguration
import MessageUI

class PostCell: UITableViewCell {
    @IBOutlet var myTextLabel: UILabel!
    @IBOutlet var myTypeLabel: UILabel!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var imageShadowView: UIView!
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if UIScreen.main.bounds.size.width < UIScreen.main.bounds.size.height {
            widthConstraint.constant = UIScreen.main.bounds.size.width - 80
        }else{
            widthConstraint.constant = UIScreen.main.bounds.size.height - 80
        }
    }
}

class PostsViewController: UIViewController {
    @IBOutlet weak var navigationView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        
        let color1 = UIColor(red: 222/255, green: 222/255, blue: 222/255, alpha: 1).cgColor
        let color2 = UIColor(red: 222/255, green: 222/255, blue: 222/255, alpha: 0).cgColor
        
        var x: CGFloat = 0
        if UIScreen.main.bounds.size.height > UIScreen.main.bounds.size.width {
            x = UIScreen.main.bounds.size.height
        }else{
            x = UIScreen.main.bounds.size.width
        }
        
        let gradient: CAGradientLayer = CAGradientLayer()
        
        gradient.colors = [color2, color1]
        gradient.locations = [0.0 , 0.3]
        gradient.startPoint = CGPoint(x: 1.0, y:1.0)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.0)
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: x, height: 94)
        navigationView.layer.insertSublayer(gradient, at: 0)
        
        self.view.layoutIfNeeded()
    }
    
    @IBAction func scrollToTop(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name("scrollToTop"), object: nil)
    }
    
    @IBAction func presentSettingsAction(_ sender: Any) {
        tapped()
    }
    
    func tapped() {
        //Generate haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

class PostsTableViewController: UITableViewController, MFMailComposeViewControllerDelegate, UIViewControllerPreviewingDelegate {
    
    //**********************************
    // MARK: Variables
    //**********************************
    
    
    //Outlets
    @IBOutlet var blinkTableView: UITableView!
    
    //Core data
    var container: NSPersistentContainer!
    
    //Stuff
    let myRefreshControl: UIRefreshControl = UIRefreshControl()
    let defaults = UserDefaults.standard
    let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
    var version = "1.0"
    
    var arrayPosts = [String]()
    var arrayDescriptions = [String]()
    var arrayLinks = [String]()
    var arrayImages = [String]()
    var arrayTimes = [Int]()
    var arrayConditions = [String]()
    
    //Helpers: appearance
    var arrayAnswered = [Int]()
    
    //Helpers: time managment
    var currentDayTime = Date()
    var lastDayTime = Date()
    
    //Helpers: post management
    var arrayFuturePosts = [String]()
    var boolDefaultPosts = [Int]()
    var dailyPostNumber = 0
    var requestCount = 0
    var baseURL = ""
    
    //Helpers: default posts
    var arrayDefaultPosts = [String]()
    
    //Helpers: 3D touch previews
    var indexPathRow = 0
    
    
    //**********************************
    // MARK: Essential functions
    //**********************************
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Observers
        NotificationCenter.default.addObserver(self, selector: #selector(PostsTableViewController.dataRefresh), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PostsTableViewController.scrollToTop), name: Notification.Name("scrollToTop"), object: nil)
        
        //Core data
        container = NSPersistentContainer(name: "myCoreDataModel")
        container.loadPersistentStores { storeDescription, error in
            self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            if let error = error {
                print("🆘 Unresolved error while configuring core data: \(error)")
            }
        }
        
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        } else {
            //No 3D touch
        }
        
        //Check app version and perform necessary updates
        versionChech()
        //Load previusly saved data
        loadSavedData(onUpdate: false)
        
        //TableView UI changes
        blinkTableView.estimatedRowHeight = 370
        blinkTableView.rowHeight = UITableViewAutomaticDimension
        myRefreshControl.addTarget(self, action: #selector(PostsTableViewController.dataRefresh), for: .valueChanged)
        blinkTableView.addSubview(myRefreshControl)
        blinkTableView.contentInset = UIEdgeInsetsMake(94, 0, 20, 0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dataRefresh()
        animateTable()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        myRefreshControl.endRefreshing()
    }
    
    override func didReceiveMemoryWarning() {
        SDImageCache.shared().clearMemory()
    }
    
    func animateTable() {
        blinkTableView.reloadData()
        
        let cells = blinkTableView.visibleCells
        let tableHeight: CGFloat = blinkTableView.bounds.size.height
        
        for i in cells {
            let cell: UITableViewCell = i as UITableViewCell
            cell.transform = CGAffineTransform(translationX: 0, y: tableHeight)
        }
        
        var index = 0
        
        for a in cells {
            let cell: UITableViewCell = a as UITableViewCell
            UIView.animate(withDuration: 1.5, delay: 0.05 * Double(index), usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
                cell.transform = CGAffineTransform(translationX: 0, y: 0);
            }, completion: nil)
            
            index += 1
        }
    }
    
    
    //**********************************
    // MARK: Peek & poop
    //**********************************
    
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRow(at: location), let cell = tableView.cellForRow(at: indexPath) as? PostCell else {
            return nil }
        
        guard let detailViewController = storyboard?.instantiateViewController(withIdentifier: "PreviewViewController") as? PreviewViewController else {
            return nil }
        
        if arrayLinks[indexPath.row] == "" || arrayDescriptions[indexPath.row] == "" || arrayImages[indexPath.row] == "" {
            return nil
        }
        
        detailViewController.headline = arrayPosts[indexPath.row]
        detailViewController.desc = arrayDescriptions[indexPath.row]
        detailViewController.imageUrl = arrayImages[indexPath.row]
        detailViewController.condition = arrayConditions[indexPath.row]
        indexPathRow = indexPath.row
        detailViewController.preferredContentSize = CGSize(width: 0.0, height: 550)
        
        previewingContext.sourceRect = cell.frame
        //previewingContext.sourceRect = blinkTableView.convert(cell.cardView.frame, from: cell.cardView.superview)
        
        return detailViewController
    }
    
    private func touchedView(view: UIView, location: CGPoint) -> Bool {
        return view.bounds.contains(view.convert(location, from: tableView))
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if arrayLinks[indexPathRow] != "" {
            if let url = URL(string: arrayLinks[indexPathRow]) {
                let vc = SFSafariViewController(url: url, entersReaderIfAvailable: false)
                vc.preferredControlTintColor = UIColor.black
                navigationController?.present(vc, animated: true)
            }
        }
    }
    
    
    //**********************************
    // MARK: TableView
    //**********************************
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayPosts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //Data managment
        let post = NSMutableAttributedString()
        var rawPost = arrayPosts[indexPath.row]
        
        switch arrayConditions[indexPath.row] {
        case "6":
            rawPost = "Review: " + rawPost
        case "7":
            if arrayPosts[indexPath.row] != "Jokes aside. Expect actual news from New York Times. 📰" {
                rawPost = "Headline: " + rawPost
            }
        default:
            break;
        }
        
        if arrayConditions[indexPath.row] == "6" || arrayConditions[indexPath.row] == "7" || arrayConditions[indexPath.row] == "10" {
            if rawPost.characters.last != "?" && rawPost.characters.last != "!" && rawPost.characters.last != "." && rawPost.characters.last != "\"" && rawPost.characters.last != ")" {
                rawPost += "."
            }
        }
        
        if arrayConditions[indexPath.row] == "" {
            post.append(NSMutableAttributedString(string: rawPost))
        }else if arrayLinks[indexPath.row] != "" {
            let attributes = [NSForegroundColorAttributeName: UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1)]
            let touchForMore = NSMutableAttributedString(string: " Touch for more...", attributes: attributes)
            
            post.append(NSMutableAttributedString(string: rawPost))
            post.append(touchForMore)
        }else if arrayConditions[indexPath.row] == "9" && arrayPosts[indexPath.row] != "Beeb boop... ℏ ℇ ≺ ℔ ∦ ℵ ℞ ℬ." {
            let attributes = [NSForegroundColorAttributeName: UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1)]
            let touchForMore = NSMutableAttributedString(string: " Touch to view...", attributes: attributes)
            
            post.append(NSMutableAttributedString(string: rawPost))
            post.append(touchForMore)
        }else if arrayConditions[indexPath.row] == "3" && !arrayAnswered.contains(indexPath.row) && arrayPosts[indexPath.row] != "I'll satisfy your inner nerd by sending you interesting facts. ⭐️" {
            let attributes = [NSForegroundColorAttributeName: UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1)]
            let touchForMore = NSMutableAttributedString(string: " Touch to reveal...", attributes: attributes)
            
            post.append(NSMutableAttributedString(string: rawPost))
            post.append(touchForMore)
        }else if arrayConditions[indexPath.row] == "3" && arrayAnswered.contains(indexPath.row) && arrayPosts[indexPath.row] != "I'll satisfy your inner nerd by sending you interesting facts. ⭐️" {
            let attributes = [NSForegroundColorAttributeName: UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1)]
            let question = NSMutableAttributedString(string: rawPost, attributes: attributes)
            
            post.append(question)
            if arrayDescriptions[indexPath.row] == "True" {
                post.append(NSMutableAttributedString(string: " It's true."))
            }else if arrayDescriptions[indexPath.row] == "False" {
                post.append(NSMutableAttributedString(string: " It's false."))
            }else{
                post.append(NSMutableAttributedString(string: " \(arrayDescriptions[indexPath.row])"))
            }
        }else{
            post.append(NSMutableAttributedString(string: rawPost))
        }
        
        if arrayImages[indexPath.row] == "" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "postCellNoImage", for: indexPath) as! PostCell
            
            cell.cardView.layer.shadowColor = UIColor.black.cgColor
            cell.cardView.layer.shadowRadius = 25
            cell.cardView.layer.shadowOpacity = 0.15
            
            cell.myTypeLabel.text = getCondition(arrayConditions[indexPath.row])
            cell.myTextLabel.attributedText = post
            
            //cell.layoutIfNeeded()
            
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "postCellWithImage", for: indexPath) as! PostCell
            
            cell.imageShadowView.layer.shadowColor = UIColor.black.cgColor
            cell.imageShadowView.layer.shadowRadius = 25
            cell.imageShadowView.layer.shadowOpacity = 0.15
            cell.postImageView.sd_setImage(with: URL(string: arrayImages[indexPath.row]), placeholderImage: nil, options: .progressiveDownload)
            
            cell.cardView.layer.shadowColor = UIColor.black.cgColor
            cell.cardView.layer.shadowRadius = 25
            cell.cardView.layer.shadowOpacity = 0.15
            
            cell.myTypeLabel.text = getCondition(arrayConditions[indexPath.row])
            cell.myTextLabel.attributedText = post
            
            //cell.layoutIfNeeded()
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if arrayLinks[indexPath.row] != "" {
            if let url = URL(string: arrayLinks[indexPath.row]) {
                let vc = SFSafariViewController(url: url, entersReaderIfAvailable: false)
                vc.preferredControlTintColor = UIColor.black
                present(vc, animated: true)
            }
        }else if arrayConditions[indexPath.row] == "3" && arrayPosts[indexPath.row] != "I'll satisfy your inner nerd by sending you interesting facts. ⭐️" {
            if arrayAnswered.count >= 3 {
                let row = arrayAnswered[0]
                arrayAnswered.removeFirst()
                blinkTableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
            }else if !arrayAnswered.contains(indexPath.row) {
                arrayAnswered.append(indexPath.row)
                blinkTableView.reloadRows(at: [indexPath], with: .automatic)
            }else{
                for i in 0..<arrayAnswered.count {
                    if arrayAnswered[i] == indexPath.row {
                        arrayAnswered.remove(at: i)
                        blinkTableView.reloadRows(at: [indexPath], with: .automatic)
                        break;
                    }
                }
            }
        }else if arrayConditions[indexPath.row] == "9" && arrayPosts[indexPath.row] != "Beeb boop... ℏ ℇ ≺ ℔ ∦ ℵ ℞ ℬ." {
            if let url = URL(string: arrayImages[indexPath.row]) {
                let vc = SFSafariViewController(url: url, entersReaderIfAvailable: false)
                vc.preferredControlTintColor = UIColor.black
                present(vc, animated: true)
            }
        }
    }
    
    
    //**********************************
    // MARK: Getting data
    //**********************************
    
    
    func dataRefresh() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
            //Reload all variables
            self.reloadData()
            
            //Remove all anwsers
            let tempAnwsers = self.arrayAnswered
            self.arrayAnswered.removeAll()
            for i in 0..<tempAnwsers.count {
                self.blinkTableView.reloadRows(at: [IndexPath(row: tempAnwsers[i], section: 0)], with: .automatic)
            }
            
            self.requestCount += 1
            print("📳 REQUEST UPDATE #\(self.requestCount)")
            
            if self.defaults.bool(forKey: "newCategory") {
                self.defaults.set(false, forKey: "newCategory")
                self.loadSavedData(onUpdate: true)
            }
            
            if self.requestCount > 1 {
                if self.dailyPostNumber == 0 {
                    //First refresh
                    self.defaults.set(1, forKey: "dailyPostNumber")
                    print("📳 DAY #\(self.defaults.integer(forKey: "dayNumber") + 1)")
                    self.lastDayTime = self.currentDayTime
                    self.defaults.set(self.lastDayTime, forKey: "lastDayTime")
                    
                    self.loadSavedData(onUpdate: true)
                }
                
                if self.currentDayTime.compare(self.lastDayTime) == .orderedDescending {
                    print("📳 DAY #\(self.defaults.integer(forKey: "dayNumber") + 1)")
                    self.lastDayTime = self.currentDayTime
                    self.defaults.set(self.lastDayTime, forKey: "lastDayTime")
                    
                    self.loadSavedData(onUpdate: true)
                    self.update(true)
                }else{
                    self.loadSavedData(onUpdate: true)
                    self.update(false)
                }
            }
            
            self.defaults.set(self.requestCount, forKey: "requestCount")
            
            self.myRefreshControl.endRefreshing()
        }
    }
    
    func update(_ newDay: Bool) {
        if isConnectedToNetwork(){
            baseURL = "http://services.conradi.si/blink/json.php?num=\(dailyPostNumber)&advice=\(boolDefaultPosts[0])&cats=\(boolDefaultPosts[1])&curiosities=\(boolDefaultPosts[2])&daily=\(boolDefaultPosts[3])&quotes=\(boolDefaultPosts[4])&movies=\(boolDefaultPosts[5])&news=\(boolDefaultPosts[6])&numbers=\(boolDefaultPosts[7])&space=\(boolDefaultPosts[8])&tech=\(boolDefaultPosts[9])&trending=\(boolDefaultPosts[10])&time=\(self.defaults.integer(forKey: "lastTime"))&token=cb5ffe91b428bed8a251dc098feced975687e0204d44451dc4869498311196fd"
            if newDay {
                //Update day count
                let day = defaults.integer(forKey: "dayNumber") + 1
                defaults.set(day, forKey: "dayNumber")
                if boolDefaultPosts[3] == 1 && day%2 == 0 {
                    //Increment post number for categories: Mysteries
                    dailyPostNumber += 1
                    defaults.set(dailyPostNumber, forKey: "dailyPostNumber")
                }
            }
            print("ℹ️ URL: \(baseURL)")
            //DOWNLOAD POSTS FROM SERVER
            performSelector(inBackground: #selector(downloadData), with: nil)
        }else{
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
                self.myRefreshControl.endRefreshing()
            }
        }
    }
    
    func downloadData() {
        let url = URL(string: self.baseURL)
        let session = URLSession.shared
        
        let task = session.dataTask(with: url!) { (data:Data?, response:URLResponse?, error:Error?) in
            if error != nil {
                print("🆘 Error with connection: \(error)")
            } else {
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as? [String: Any]
                    
                    if json?["status"] as? String == "ok" {
                        if let current_time = json?["current_time"] as? Int {
                            //DELAY 5 SEC
                            if self.defaults.integer(forKey: "lastTime") < current_time - 5 {
                                self.defaults.set(current_time, forKey: "lastTime")
                                
                                if let posts = json?["posts"] as? [[String: AnyObject]] {
                                    for post in posts {
                                        if let text = post["text"] as? String {
                                            if let condition = post["conditions"] as? String{
                                                if let url = post["url"] as? String {
                                                    if let time = post["time"] as? Int {
                                                        if let image = post["image"] as? String {
                                                            if let description = post["description"] as? String {
                                                                DispatchQueue.main.sync {
                                                                    if !self.arrayPosts.contains(text) && !self.arrayFuturePosts.contains(text) {
                                                                        //ADD NEW POSTS
                                                                        let data = Post(context: self.container.viewContext)
                                                                        self.configure(post: data, text: text, description: description, condition: condition, link: url, image: image, time: time)
                                                                        self.saveContext()
                                                                        
                                                                        if condition == "6" || condition == "7" || condition == "10" || condition == "11" || time <= Int(NSDate().timeIntervalSince1970) {
                                                                            print("✅ Added post: \"\(text)\" with time: \(time) and condition \(condition).")
                                                                            self.addPost(text: text, description: description, condition: condition, link: url, image: image, time: time)
                                                                            self.blinkTableView.beginUpdates()
                                                                            self.blinkTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
                                                                            self.blinkTableView.endUpdates()
                                                                        }else{
                                                                            print("✅ Scheduled post: \"\(text)\" with time: \(time) and condition \(condition).")
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }else{
                                print("⏸ Timeout: \(self.defaults.integer(forKey: "lastTime")) < \(current_time - 3)")
                            }
                        }
                    }
                    print("❎ Download process complete.")
                } catch {
                    print("🆘 Something went wrong during data download from the server.")
                }
            }
        }
        
        task.resume()
    }
    
    func setUp() {
        //SET UP
        print("📳 Set up")
        arrayDefaultPosts = ["I'll try to help you with some advice. ⚖️",
                             "I know some of the best cat facts. 🐈 Because why not. And I'm lonely. Mostly because I'm lonely.",
                             "I'll satisfy your inner nerd by sending you interesting facts. ⭐️",
                             "Pure random stuff. Just for you. 💎",
                             "Do you need some inspiration? I know some good quotes... 💬",
                             "I love movies. 🎬 I hope you love them too!",
                             "Jokes aside. Expect actual news from New York Times. 📰",
                             "Some numbers are pretty mind-boggling. Here are especially nice ones. 🕵️‍♀️",
                             "Beeb boop... ℏ ℇ ≺ ℔ ∦ ℵ ℞ ℬ.",
                             "💻 and ⌨️ and 🖥 and 🎮",
                             "When something weird happens, you'll know. 🔥"]
        
        //Set default values
        boolDefaultPosts = [0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 1]
        defaults.set(arrayDefaultPosts, forKey: "arrayDefaultPosts")
        defaults.set(boolDefaultPosts, forKey: "boolDefaultPosts")
        defaults.set(0, forKey: "dailyPostNumber")
        defaults.set(0, forKey: "dayNumber")
        defaults.set(Int(NSDate().timeIntervalSince1970) - 5, forKey: "lastTime")
        defaults.set(true, forKey: "dailyNotifications")
        defaults.set(true, forKey: "shakeToSendFeedback")
        defaults.set(8, forKey: "notificationTimeHour")
        defaults.set(0, forKey: "notificationTimeMinute")
        defaults.set(calendar.startOfDay(for: Date()), forKey: "lastDayTime")
        
        //ADD DEFAULT POSTS
        configDefaultPosts()
    }
    
    
    //**********************************
    // MARK: Data managment
    //**********************************
    
    
    func addPost(text: String, description: String, condition: String, link: String, image: String, time: Int) {
        arrayPosts.insert(text, at: 0)
        arrayDescriptions.insert(description, at: 0)
        arrayLinks.insert(link, at: 0)
        arrayImages.insert(image, at: 0)
        arrayTimes.insert(time, at: 0)
        arrayConditions.insert(condition, at: 0)
    }
    
    func loadSavedData(onUpdate: Bool) {
        print("📳 Loading")
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Post")
        
        // Helpers
        var result = [Post]()
        
        do {
            // Execute Fetch Request
            let records = try container.viewContext.fetch(fetchRequest)
            
            if let records = records as? [Post] {
                result = records
            }
            
            if !onUpdate {
                for item in result {
                    if item.time <= Int(NSDate().timeIntervalSince1970) && !self.arrayPosts.contains(item.post) {
                        self.addPost(text: item.post, description: item.desc, condition: item.condition, link: item.link, image: item.image, time: item.time)
                    }else if item.time > Int(NSDate().timeIntervalSince1970) && !self.arrayFuturePosts.contains(item.post) {
                        self.arrayFuturePosts.insert(item.post, at: 0)
                        print("ℹ️ Post will be visible in: \((item.time - Int(NSDate().timeIntervalSince1970)) / 60) minutes. Post: \(item.post)")
                    }
                }
            }else{
                for item in result {
                    if item.time <= Int(NSDate().timeIntervalSince1970) && !arrayPosts.contains(item.post) {
                        addPost(text: item.post, description: item.desc, condition: item.condition, link: item.link, image: item.image, time: item.time)
                        blinkTableView.beginUpdates()
                        blinkTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
                        blinkTableView.endUpdates()
                    }else if item.time > Int(NSDate().timeIntervalSince1970) {
                        self.arrayFuturePosts.insert(item.post, at: 0)
                    }
                }
            }
        } catch {
            print("🆘 Unable to fetch managed objects for entity Post.")
        }
    }
    
    func reloadData() {
        boolDefaultPosts = defaults.object(forKey: "boolDefaultPosts") as! [Int]
        dailyPostNumber = defaults.integer(forKey: "dailyPostNumber")
        currentDayTime = calendar.startOfDay(for: Date())
        lastDayTime = defaults.object(forKey: "lastDayTime") as! Date
        requestCount = defaults.integer(forKey: "requestCount")
    }
    
    func configure(post: Post, text: String, description: String, condition: String, link: String, image: String, time: Int) {
        post.post = text
        post.desc = description
        post.condition = condition
        post.link = link
        post.image = image
        post.time = time
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
    
    
    //**********************************
    // MARK: Default posts
    //**********************************
    
    
    func configDefaultPosts() {
        let data1 = Post(context: container.viewContext)
        configure(post: data1, text: arrayDefaultPosts[10], description: "", condition: "11", link: "", image: "", time: 1)
        saveContext()
        //addPost(text: arrayDefaultPosts[10], description: "", condition: "11", link: "", image: "", time: 1)
        
        let data2 = Post(context: container.viewContext)
        configure(post: data2, text: arrayDefaultPosts[6], description: "", condition: "7", link: "", image: "", time: 2)
        saveContext()
        //addPost(text: arrayDefaultPosts[6], description: "", condition: "7", link: "", image: "", time: 2)
        
        let data3 = Post(context: container.viewContext)
        configure(post: data3, text: arrayDefaultPosts[4], description: "", condition: "5", link: "", image: "", time: 3)
        saveContext()
        //addPost(text: arrayDefaultPosts[4], description: "", condition: "5", link: "", image: "", time: 3)
        
        let data4 = Post(context: container.viewContext)
        configure(post: data4, text: arrayDefaultPosts[3], description: "", condition: "4", link: "", image: "", time: 4)
        saveContext()
        //addPost(text: arrayDefaultPosts[3], description: "", condition: "4", link: "", image: "", time: 4)
        
        let data5 = Post(context: container.viewContext)
        configure(post: data5, text: "Hi! I'm Blink. Return every day and I'll try to make your day better. 🍹", description: "", condition: "100", link: "", image: "", time: 100)
        saveContext()
        //addPost(text: "Hi! I'm Blink. Return every day and I'll try to make your day better. 🍹", description: "", condition: "100", link: "", image: "", time: 100)
        
        //First posts
        
        let data6 = Post(context: container.viewContext)
        configure(post: data6, text: "Congratulations on your first refresh. Wait ... is that weird? (Psst ... there's more.)", description: "", condition: "11", link: "", image: "", time: Int(NSDate().timeIntervalSince1970) + 3)
        saveContext()
        //addPost(text: "Congratulations on your first refresh. Wait ... is that weird? (Psst ... there's more.)", description: "", condition: "11", link: "", image: "", time: Int(NSDate().timeIntervalSince1970) + 3)
        
        let data7 = Post(context: container.viewContext)
        configure(post: data7, text: "\"Life's challenges are not supposed to paralyse you, they're supposed to help you discover who you are.\" — Bernice Reagon", description: "", condition: "5", link: "", image: "", time: Int(NSDate().timeIntervalSince1970) + 3)
        saveContext()
        //addPost(text: "\"Life's challenges are not supposed to paralyse you, they're supposed to help you discover who you are.\" — Bernice Reagon", description: "", condition: "5", link: "", image: "", time: Int(NSDate().timeIntervalSince1970) + 3)
        
        let data8 = Post(context: container.viewContext)
        configure(post: data8, text: "Silence is golden. Duck tape is silver.", description: "", condition: "4", link: "", image: "", time: Int(NSDate().timeIntervalSince1970) + 3)
        saveContext()
        //addPost(text: "Silence is golden. Duck tape is silver.", description: "", condition: "4", link: "", image: "", time: Int(NSDate().timeIntervalSince1970) + 3)
    }
    
    
    //**********************************
    // MARK: Alerts & popups
    //**********************************
    
    
    override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) {
        if defaults.bool(forKey: "shakeToSendFeedback") {
            let alertController = UIAlertController(title: "Send feedback", message: "You've opened a super secret menu. Just kidding. Do you want to send us your feedback?", preferredStyle: .alert)
            
            let bugAction = UIAlertAction(title: "Send feedback", style: UIAlertActionStyle.default) {
                UIAlertAction in
                self.sendEmail()
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) {
                UIAlertAction in
            }
            
            alertController.addAction(cancelAction)
            alertController.addAction(bugAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func sendEmail() {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["info@conradi.si"])
            mail.setSubject("Bug report/feedback")
            
            present(mail, animated: true)
        } else {
            let alertController = UIAlertController(title: "Can't compose email", message: "Something went wrong. Check your Mail app.", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) {
                UIAlertAction in
            }
            alertController.addAction(cancelAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
    @IBAction func share(_ sender: UIButton) {
        tapped()
        let button = sender
        let view = button.superview!
        let cell = view.superview?.superview as! PostCell
        let indexPath: IndexPath = blinkTableView.indexPath(for: cell)!
        
        var textToShare = ""
        
        if self.arrayLinks[indexPath.row] == "" {
            textToShare = "\(self.arrayPosts[indexPath.row])\n\nvia Blink for iPhone: http://www.conradi.si/"
        }else if self.arrayImages[indexPath.row] != "" {
            textToShare = "\(self.arrayPosts[indexPath.row]): \(self.arrayImages[indexPath.row])\n\nvia Blink for iPhone: http://www.conradi.si/"
        }else{
            textToShare = "\(self.arrayPosts[indexPath.row]): \(self.arrayLinks[indexPath.row])\n\nvia Blink for iPhone: http://www.conradi.si/"
        }
        
        let objectsToShare = [textToShare] as [Any]
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityVC.excludedActivityTypes = [UIActivityType.airDrop, UIActivityType.addToReadingList, UIActivityType.print, UIActivityType.postToVimeo, UIActivityType.openInIBooks, UIActivityType.postToVimeo, UIActivityType.postToFlickr, UIActivityType.assignToContact, UIActivityType.saveToCameraRoll]
        self.present(activityVC, animated: true, completion: nil)
    }
    
    
    //**********************************
    // MARK: Other methods
    //**********************************
    
    
    func versionChech() {
        if (defaults.string(forKey: "version") == nil) {
            setUp()
        }
        
        version = "1.0"
        defaults.set("1.0", forKey: "version")
        print("📳 Version: \(version)")
    }
    
    func tapped() {
        //Generate haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
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
    
    public func scrollToTop() {
        blinkTableView.setContentOffset(CGPoint(x: 0,y :-94), animated: true)
    }
    
    func getCondition(_ i: String) -> String {
        switch i {
        case "1":
            return "Advice" //1 (0)
        case "2":
            return "Cat facts" //2 (1)
        case "3":
            return "Curiosities" //3 (2)
        case "4":
            return "Mysteries" //4 (3)
        case "5":
            return "Inspiring quotes" //5 (4)
        case "6":
            return "Movie reviews" //6 (5)
        case "7":
            return "News" //7 (6)
        case "8":
            return "Number trivia" //8 (7)
        case "9":
            return "Space photo of the day" //9 (8)
        case "10":
            return "Tech talk" //10 (9)
        case "11":
            return "Weird but trending" //11 (10)
        default:
            return "Blink" //Other
        }
    }
}
