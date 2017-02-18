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

class PostsTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, MFMailComposeViewControllerDelegate {
    
    //**********************************
    // MARK: Variables
    //**********************************
    
    //1
    //FUCKING CORE DATA
    var container: NSPersistentContainer!
    var fetchedResultsController: NSFetchedResultsController<Post>!
    var commitPredicate: NSPredicate?
    //NOT FUCKING CORE DATA
    let defaults = UserDefaults.standard
    let currentCal = Calendar(identifier: Calendar.Identifier.gregorian)
    
    //2
    var arrayForCheckPosts = [String]()
    var arrayForCheckLinks = [String]()
    var arrayForCheckTimes = [Int]()
    
    var baseURL = ""
    
    var numberOfPosts = 0
    var currentDayTime = Date()
    var lastDayTime = Date()
    
    var arrayDefaultPosts = [[String]]()
    var boolDefaultPosts = [Int]()
    
    var progressDefPosts = [false, false, false, false, false, false, false, false, false, false]
    var progressDefOrder = [[Int]]()
    var progressSortedDefOrder = [[Int]]()
    
    var needsRefresh = false
    
    var requestCount = 0;
    
    //Important
    //var posts = [Post]()
    
    //3
    @IBOutlet var blinkTableView: UITableView!
    let myRefreshControl: UIRefreshControl = UIRefreshControl()
    @IBOutlet weak var button: UIButton!
    
    
    //**********************************
    // MARK: Essential functions
    //**********************************
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(PostsTableViewController.dataRefresh), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil )
        
        container = NSPersistentContainer(name: "myCoreDataModel")
        
        container.loadPersistentStores { storeDescription, error in
            self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            if let error = error {
                print("🆘 Unresolved error \(error)")
            }
        }
        
        defaults.set(false, forKey: "newCategory")
        numberOfPosts = defaults.integer(forKey: "NumberOfPosts")
        currentDayTime = currentCal.startOfDay(for: Date())
        if numberOfPosts == 0 {
            lastDayTime = currentDayTime
            defaults.set(lastDayTime, forKey: "lastDayTime")
        }else{
            lastDayTime = defaults.object(forKey: "lastDayTime") as! Date
        }
        
        versionChech()
        loadSavedData()
        
        UIApplication.shared.statusBarStyle = .default
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1.0)
        self.navigationController?.navigationBar.tintColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        let backButton = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.plain, target: self.navigationController, action: nil)
        self.navigationItem.leftBarButtonItem = backButton
        
        self.blinkTableView.estimatedRowHeight = 50
        self.blinkTableView.rowHeight = UITableViewAutomaticDimension
        self.myRefreshControl.addTarget(self, action: #selector(PostsTableViewController.dataRefresh), for: .valueChanged)
        self.blinkTableView.addSubview(self.myRefreshControl)
        
        self.tableView.reloadData()
        let range = NSMakeRange(0, self.tableView.numberOfSections)
        let sections = IndexSet(integersIn: range.toRange() ?? 0..<0)
        self.tableView.reloadSections(sections, with: .fade)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        currentDayTime = currentCal.startOfDay(for: Date())
        lastDayTime = defaults.object(forKey: "lastDayTime") as! Date
        
        dataRefresh()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        myRefreshControl.endRefreshing()
    }

    @IBAction func iconTapped(_ sender:UIButton) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) {
        // Create the alert controller
        let alertController = UIAlertController(title: "Bug report", message: "You've opened a super secret menu. Just kidding. Want to send us your feedback?", preferredStyle: .alert)
        
        // Create the actions
        let bugAction = UIAlertAction(title: "Send feedback", style: UIAlertActionStyle.default) {
            UIAlertAction in
            self.sendEmail()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) {
            UIAlertAction in
        }
        
        // Add the actions
        alertController.addAction(cancelAction)
        alertController.addAction(bugAction)
        
        // Present the controller
        self.present(alertController, animated: true, completion: nil)
    }
    
    func sendEmail() {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["info@conradi.si"])
            mail.setMessageBody("<p>Bug report</p>", isHTML: true)
            
            present(mail, animated: true)
        } else {
            // show failure alert
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyPostCell", for: indexPath) as! PostCell
        
        
        let post = fetchedResultsController.object(at: indexPath)
        cell.myTextLabel.text = post.post
        if post.link != "0" {
            cell.myTypeLabel.text = "\(getCondition(post.condition)) (link)"
        }else{
            cell.myTypeLabel.text = getCondition(post.condition)
        }
        
        cell.cardView.layer.shadowColor = UIColor.black.cgColor
        cell.cardView.layer.shadowOpacity = 0.10
        cell.cardView.layer.shadowOffset = CGSize.zero
        cell.cardView.layer.shadowRadius = 3
        cell.cardView.layer.cornerRadius = 3
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = fetchedResultsController.object(at: indexPath)
        tapped()
        
        if post.link != "0" {
            showURL(post.link, post.condition)
        }else{
            let textToShare = "\(post.post) - via Blink:"
            if let myWebsite = URL(string: "http://www.conradi.si/") {
                let objectsToShare = [textToShare, myWebsite] as [Any]
                let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                activityVC.excludedActivityTypes = [UIActivityType.airDrop, UIActivityType.addToReadingList, UIActivityType.print, UIActivityType.postToVimeo, UIActivityType.openInIBooks, UIActivityType.postToVimeo, UIActivityType.postToFlickr, UIActivityType.assignToContact, UIActivityType.saveToCameraRoll]
                self.present(activityVC, animated: true, completion: nil)
            }
        }
    }
    
    func showURL(_ get_url: String, _ i: String) {
        if let url = URL(string: get_url) {
            let vc = SFSafariViewController(url: url, entersReaderIfAvailable: true)
            vc.modalPresentationStyle = .overFullScreen
            present(vc, animated: true, completion: nil)
        }
    }
    
    func tapped() {
        //Generate haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    
    //**********************************
    // MARK: Getting data
    //**********************************
    
    
    func dataRefresh() {
        requestCount = defaults.integer(forKey: "requestCount")
        requestCount += 1
        print("📳 REQUEST UPDATE #\(requestCount)")
        
        let newCategory = defaults.bool(forKey: "newCategory")
        if newCategory {
            loadSavedData()
            DispatchQueue.main.async { [unowned self] in
                self.tableView.reloadData()
                let range = NSMakeRange(0, self.tableView.numberOfSections)
                let sections = IndexSet(integersIn: range.toRange() ?? 0..<0)
                self.tableView.reloadSections(sections, with: .fade)
            }
        }
        defaults.set(false, forKey: "newCategory")
        
        if requestCount > 1 {
            currentDayTime = currentCal.startOfDay(for: Date())
            lastDayTime = defaults.object(forKey: "lastDayTime") as! Date
            
            if currentDayTime.compare(lastDayTime) == .orderedDescending || defaults.integer(forKey: "NumberOfPosts") == 0 {
                print("📳 DAY #\(defaults.integer(forKey: "NumberOfPosts"))")
                lastDayTime = currentDayTime
                defaults.set(lastDayTime, forKey: "lastDayTime")
                
                update(true)
            }else{
                update(false)
            }
        }
        
        defaults.set(requestCount, forKey: "requestCount")
    }
    
    func versionChech() {
        requestCount = defaults.integer(forKey: "requestCount")
        if requestCount == 0 {
            setUp()
        }
    }
    
    func downloadData() {
        DispatchQueue.main.async {
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
                                //DELAY 3 SEC
                                if self.defaults.integer(forKey: "lastTime") < current_time - 3 {
                                    self.defaults.set(current_time, forKey: "lastTime")
                                    
                                    if let posts = json?["posts"] as? [[String: AnyObject]] {
                                        for post in posts {
                                            if var text = post["text"] as? String {
                                                if let condition = post["conditions"] as? String{
                                                    if let url = post["url"] as? String {
                                                        if let time = post["time"] as? Int {
                                                            if condition == "7" || condition == "9"{
                                                                text += "."
                                                            }
                                                            if self.arrayForCheckPosts.contains(text) == false && self.arrayForCheckTimes.contains(time) == false {
                                                                print("✅ Added post: \"\(text)\" with time: \(time) and condition \(condition).")
                                                                //ADD NEW POSTS
                                                                let data = Post(context: self.container.viewContext)
                                                                self.configure(post: data, text: text, condition: condition, link: url, time: time)
                                                                self.saveContext()
                                                                
                                                                self.loadSavedData()
                                                                self.needsRefresh = true
                                                            }else{
                                                                print("⛔️ Rejected post: \"\(text)\" with time: \(time) and condition \(condition).")
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        
                                        if self.needsRefresh {
                                            DispatchQueue.main.async { [unowned self] in
                                                self.tableView.reloadData()
                                                let range = NSMakeRange(0, self.tableView.numberOfSections)
                                                let sections = IndexSet(integersIn: range.toRange() ?? 0..<0)
                                                self.tableView.reloadSections(sections, with: .fade)
                                                self.myRefreshControl.endRefreshing()
                                            }
                                            self.needsRefresh = false
                                        }
                                    }
                                }else{
                                    print("⏸ Timeout: \(self.defaults.integer(forKey: "lastTime")) < \(current_time - 3)")
                                }
                            }
                        }
                        
                        DispatchQueue.main.async { [unowned self] in
                            self.myRefreshControl.endRefreshing()
                        }
                        print("❎ Download process complete.")
                    } catch {
                        print("🆘 Something went wrong during data download from the server.")
                    }
                }
            }
            
            task.resume()
        }
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
    
    func loadSavedData() {
        if fetchedResultsController == nil {
            let request = Post.createFetchRequest()
            let sort = NSSortDescriptor(key: "time", ascending: false)
            request.sortDescriptors = [sort]
            request.fetchBatchSize = 20
            
            fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
            fetchedResultsController.delegate = self
        }
        
        fetchedResultsController.fetchRequest.predicate = commitPredicate
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("🆘 Fetch failed")
        }
    }
    
    func getArrayForChech() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Post")
        
        // Helpers
        var result = [Post]()
        
        do {
            // Execute Fetch Request
            let records = try container.viewContext.fetch(fetchRequest)
            
            if let records = records as? [Post] {
                result = records
            }
            
            for item in result {
                arrayForCheckPosts.append(item.post)
                arrayForCheckLinks.append(item.link)
                arrayForCheckTimes.append(item.time)
            }
        } catch {
            print("Unable to fetch managed objects for entity Post.")
        }
    }
    
    func configure(post: Post, text: String, condition: String, link: String, time: Int) {
        post.post = text
        post.condition = condition
        post.link = link
        post.time = time
    }
    
    func update(_ new: Bool) {
        loadSavedData()
        getArrayForChech()
        if isConnectedToNetwork(){
            boolDefaultPosts = defaults.object(forKey: "boolDefaultPosts") as! [Int]
            
            numberOfPosts = defaults.integer(forKey: "NumberOfPosts")
            if boolDefaultPosts[3] == 1 && new {
                numberOfPosts += 1
                defaults.set(numberOfPosts, forKey: "NumberOfPosts")
            }
            
            //DEFINE URL
            if new {
                baseURL = "http://account.conradi.si/blink/json.php?num=\(numberOfPosts)&advice=\(boolDefaultPosts[0])&cats=\(boolDefaultPosts[1])&curiosities=\(boolDefaultPosts[2])&daily=\(boolDefaultPosts[3])&quotes=\(boolDefaultPosts[4])&movies=\(boolDefaultPosts[5])&news=\(boolDefaultPosts[6])&numbers=\(boolDefaultPosts[7])&tech=\(boolDefaultPosts[8])&trending=\(boolDefaultPosts[9])&time=\(self.defaults.integer(forKey: "lastTime"))"
            }else{
                baseURL = "http://account.conradi.si/blink/json.php?num=\(numberOfPosts)&advice=0&cats=0&curiosities=\(boolDefaultPosts[2])&daily=0&quotes=0&movies=\(boolDefaultPosts[5])&news=\(boolDefaultPosts[6])&numbers=0&tech=\(boolDefaultPosts[8])&trending=\(boolDefaultPosts[9])&time=\(self.defaults.integer(forKey: "lastTime"))"
            }
            print("ℹ️ URL: \(baseURL)")
            //START DOWNLOAD
            //DOWNLOAD POSTS FROM SERVER
            performSelector(inBackground: #selector(downloadData), with: nil)
            //downloadData()
        }
    }
    
    func setUp() {
        loadSavedData()
        //SET UP
        print("📳 [DEBUG] Set up")
        numberOfPosts = 0
        defaults.set(numberOfPosts, forKey: "NumberOfPosts")
        arrayDefaultPosts = [["I'll try to help you with some advice. ⚖️", ""], ["I know some of the best cat facts. 🐈 Because why not. And I'm lonely. Mostly because I'm lonely.", ""], ["I'll satisfy your inner nerd by sending you interesting facts. ⭐️", ""], ["Pure random stuff will be waiting for you. 💎", "0"], ["Do you need some inspiration? I know some good quotes... 💬", ""], ["I love movies. 🎬 I hope you love them too!", ""], ["Jokes aside. Expect actual news from New York Times. 📰", "2"], ["Some numbers are pretty mind-boggling. Here are especially nice ones. 🕵️‍♀️", ""], ["💻 and ⌨️ and 🖥 and 🎮", ""], ["When something weird happens, you'll know. 🔥", "1"]]
        /*["Beeb boop... ℏ ℇ ≺ ℔ ∦ ℵ ℞ ℬ.", ""],*/
        boolDefaultPosts = [0, 0, 0, 1, 0, 0, 1, 0, 0, 1]
        defaults.set(arrayDefaultPosts, forKey: "arrayDefaultPosts")
        defaults.set(boolDefaultPosts, forKey: "boolDefaultPosts")
        defaults.set(Int(NSDate().timeIntervalSince1970) - 3, forKey: "lastTime")
        
        //UPDATE
        //DEFINE URL
        baseURL = "http://account.conradi.si/blink/json.php?num=0&cats=0&caveman=0&curiosities=0&daily=1&quotes=0&movies=0&news=1&numbers=0&space=0&tech=0&trending=1&time=\(Int(NSDate().timeIntervalSince1970))"
        print("ℹ️ URL: \(baseURL)")
        
        //ADD DEFAULT POSTS
        configDefaultPosts()
        saveContext()
        loadSavedData()
        //DOWNLOAD POSTS FROM SERVER
        /*if isConnectedToNetwork() {
            performSelector(inBackground: #selector(downloadData), with: nil)
        }*/
    }
    
    
    //**********************************
    // MARK: Default posts
    //**********************************
    
    
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
        //print("[DATA] [DEBUG] Default posts sorted order: \(progressSortedDefOrder)")
        
        for j in 0..<self.progressSortedDefOrder.count {
            self.addDefPost(self.progressSortedDefOrder[j][1])
        }
        //WELCOME MESSAGE
        self.addDefPost(10)
    }
    
    func addDefPost(_ i: Int) {
        if i != 10 {
            if self.boolDefaultPosts[i] == 1 && self.arrayDefaultPosts[i][1] != "" && progressDefPosts[i] == false {
                let data = Post(context: self.container.viewContext)
                self.configure(post: data, text: self.arrayDefaultPosts[i][0], condition: "\(i + 1)", link: "0" , time: i + 1)
                progressDefPosts[i] = true
                print("✅ Added default post: \(self.arrayDefaultPosts[i][0])")
            }else{
                print("🆘 Failed (\(self.boolDefaultPosts[i]) = 1; \"\(self.arrayDefaultPosts[i][1])\" != \"\"; \(progressDefPosts[i]) = false) for i = \(i): \(self.arrayDefaultPosts[i][0])")
            }
        }else{
            let data = Post(context: self.container.viewContext)
            self.configure(post: data, text: "Hi! I'm Blink. Return every day and I'll try to make your day better. 🍹", condition: "\(100)", link: "0" , time: 100)
        }
    }
    
    
    //**********************************
    // MARK: Other methods
    //**********************************
    
    
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
    
    func getCondition(_ i: String) -> String {
        if i == "1" {
            return "Advice"
        }else if i == "2"{
            return "Cat facts"
        }else if i == "3" {
            return "Curiosities"
        }else if i == "4" {
            return "Daily mistery"
        }else if i == "5" {
            return "Inspiring quotes"
        }else if i == "6" {
            return "Movie reviews"
        }else if i == "7" {
            return "News"
        }else if i == "8" {
            return "Number trivia"
        }else if i == "9" {
            return "Tech talk"
        }else if i == "10" {
            return "Weird but trending"
        }else{
            return "Blink"
        }
    }
}
