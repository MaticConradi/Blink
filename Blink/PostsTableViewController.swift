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

class PostsTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, MFMailComposeViewControllerDelegate, UIViewControllerPreviewingDelegate {
    
    //**********************************
    // MARK: Variables
    //**********************************
    
    
    //Outlets
    @IBOutlet var blinkTableView: UITableView!
    @IBOutlet weak var button: UIButton!
    
    //Core data
    var container: NSPersistentContainer!
    var fetchedResultsController: NSFetchedResultsController<Post>!
    var commitPredicate: NSPredicate?
    
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
    var boolDefaultPosts = [Int]()
    var evenPostOrder = [Int]()
    var oddPostOrder = [Int]()
    var numberOfPosts = 0
    var requestCount = 0
    var baseURL = ""
    
    //Helpers: default posts
    var arrayDefaultPosts = [[String]]()
    var progressDefPosts = [false, false, false, false, false, false, false, false, false, false]
    var progressDefOrder = [[Int]]()
    var progressSortedDefOrder = [[Int]]()
    
    //Helpers: 3D touch previews
    var indexPathRow = 0
    
    
    //**********************************
    // MARK: Essential functions
    //**********************************
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //ViewController UI changes
        UIApplication.shared.statusBarStyle = .default
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1.0)
        self.navigationController?.navigationBar.tintColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        let backButton = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.plain, target: self.navigationController, action: nil)
        self.navigationItem.leftBarButtonItem = backButton
        
        //Necessary stuff
        NotificationCenter.default.addObserver(self, selector: #selector(PostsTableViewController.dataRefresh), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil )
        container = NSPersistentContainer(name: "myCoreDataModel")
        container.loadPersistentStores { storeDescription, error in
            self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            if let error = error {
                print("🆘 Unresolved error \(error)")
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
        loadSavedData()
        
        //TableView UI changes
        blinkTableView.estimatedRowHeight = 50
        blinkTableView.rowHeight = UITableViewAutomaticDimension
        myRefreshControl.addTarget(self, action: #selector(PostsTableViewController.dataRefresh), for: .valueChanged)
        blinkTableView.addSubview(myRefreshControl)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dataRefresh()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        myRefreshControl.endRefreshing()
    }
    
    @IBAction func iconTapped(_ sender:UIButton) {
        tapped()
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    
    //**********************************
    // MARK: Peek & poop
    //**********************************
    
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let indexPath = tableView.indexPathForRow(at: location), let cell = tableView.cellForRow(at: indexPath) as? PostCell else {
            return nil }
        
        guard let detailViewController = storyboard?.instantiateViewController(withIdentifier: "PreviewViewController") as? PreviewViewController else {
            return nil }
        
        if arrayLinks[indexPath.row] == "" || arrayLinks[indexPath.row] == "0" || arrayDescriptions[indexPath.row] == "" || arrayImages[indexPath.row] == "" {
            return nil
        }
        
        detailViewController.headline = arrayPosts[indexPath.row]
        detailViewController.desc = arrayDescriptions[indexPath.row]
        detailViewController.imageUrl = arrayImages[indexPath.row]
        detailViewController.condition = arrayConditions[indexPath.row]
        indexPathRow = indexPath.row
        detailViewController.preferredContentSize = CGSize(width: 0.0, height: 550)
        
        previewingContext.sourceRect = blinkTableView.convert(cell.cardView.frame, from: cell.cardView.superview)
        
        return detailViewController
    }
    
    private func touchedView(view: UIView, location: CGPoint) -> Bool {
        return view.bounds.contains(view.convert(location, from: tableView))
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if arrayLinks[indexPathRow] != "0" && arrayLinks[indexPathRow] != "" {
            if let url = URL(string: arrayLinks[indexPathRow]) {
                let vc = SFSafariViewController(url: url, entersReaderIfAvailable: false)
                vc.preferredControlTintColor = UIColor.black
                navigationController?.present(vc, animated: true)
            }
        }
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
        
        let moreOptions = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let shareAction = UIAlertAction(title: "Share", style: .default, handler: {(alert :UIAlertAction!) in
            var textToShare = ""
            
            if self.arrayLinks[indexPath.row] == "0" || self.arrayLinks[indexPath.row] == "" {
                textToShare = "\(self.arrayPosts[indexPath.row])\n\nvia Blink for iPhone: http://www.conradi.si/"
            }else{
                textToShare = "\(self.arrayPosts[indexPath.row]): \(self.arrayLinks[indexPath.row])\n\nvia Blink for iPhone: http://www.conradi.si/"
            }
            
            let objectsToShare = [textToShare] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityVC.excludedActivityTypes = [UIActivityType.airDrop, UIActivityType.addToReadingList, UIActivityType.print, UIActivityType.postToVimeo, UIActivityType.openInIBooks, UIActivityType.postToVimeo, UIActivityType.postToFlickr, UIActivityType.assignToContact, UIActivityType.saveToCameraRoll]
            self.present(activityVC, animated: true, completion: nil)
        })
        moreOptions.addAction(shareAction)
        
        let unsubscribeAction = UIAlertAction(title: "Unfollow", style: .destructive, handler: {(alert :UIAlertAction!) in
            //Confirmation
            let confirmation = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let confirmationUnsubscribeAction = UIAlertAction(title: "Unfollow", style: .destructive, handler: {(alert :UIAlertAction!) in
                if let kategorija = Int(self.arrayConditions[indexPath.row]) {
                    if kategorija < self.boolDefaultPosts.count {
                        if self.boolDefaultPosts[kategorija - 1] == 1 {
                            self.boolDefaultPosts[kategorija - 1] = 0
                            self.defaults.set(self.boolDefaultPosts, forKey: "boolDefaultPosts")
                        }
                    }
                }
            })
            confirmation.addAction(confirmationUnsubscribeAction)
            
            let confirmationCancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {(alert :UIAlertAction!) in
            })
            confirmation.addAction(confirmationCancelAction)
            
            self.present(confirmation, animated: true, completion: nil)
            
            confirmation.popoverPresentationController?.sourceView = view
            confirmation.popoverPresentationController?.sourceRect = sender.frame
            //End confirmation
        })
        moreOptions.addAction(unsubscribeAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {(alert :UIAlertAction!) in
        })
        moreOptions.addAction(cancelAction)
        
        present(moreOptions, animated: true, completion: nil)
        
        moreOptions.popoverPresentationController?.sourceView = view
        moreOptions.popoverPresentationController?.sourceRect = sender.frame
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyPostCell", for: indexPath) as! PostCell
        
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
        
        if arrayConditions[indexPath.row] == "6" || arrayConditions[indexPath.row] == "7" || arrayConditions[indexPath.row] == "9" {
            if rawPost.characters.last != "?" && rawPost.characters.last != "!" && rawPost.characters.last != "." {
                rawPost += "."
            }
        }
        
        if arrayLinks[indexPath.row] != "0" {
            let attributes = [NSForegroundColorAttributeName: UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1)]
            let touchForMore = NSMutableAttributedString(string: " Touch for more...", attributes: attributes)
            
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
        
        cell.myTypeLabel.text = getCondition(arrayConditions[indexPath.row])
        cell.myTextLabel.attributedText = post
        
        cell.cardView.layer.shadowColor = UIColor.black.cgColor
        cell.cardView.layer.shadowOpacity = 0.10
        cell.cardView.layer.shadowOffset = CGSize.zero
        cell.cardView.layer.shadowRadius = 3
        cell.cardView.layer.cornerRadius = 3
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if arrayLinks[indexPath.row] != "0" && arrayLinks[indexPath.row] != "" {
            if let url = URL(string: arrayLinks[indexPath.row]) {
                let vc = SFSafariViewController(url: url, entersReaderIfAvailable: false)
                vc.preferredControlTintColor = UIColor.black
                present(vc, animated: true)
            }
        }else if arrayConditions[indexPath.row] == "3" && !arrayAnswered.contains(indexPath.row) && arrayPosts[indexPath.row] != "I'll satisfy your inner nerd by sending you interesting facts. ⭐️" {
            if arrayAnswered.count >= 3 {
                let row = arrayAnswered[0]
                arrayAnswered.removeFirst()
                blinkTableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
            }
            arrayAnswered.append(indexPath.row)
            blinkTableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
    
    //**********************************
    // MARK: Getting data
    //**********************************
    
    
    func dataRefresh() {
        //Reload all variables
        reloadData()
        
        //Remove all anwsers
        let tempAnwsers = arrayAnswered
        arrayAnswered.removeAll()
        for i in 0..<tempAnwsers.count {
            blinkTableView.reloadRows(at: [IndexPath(row: tempAnwsers[i], section: 0)], with: .automatic)
        }
        
        requestCount += 1
        print("📳 REQUEST UPDATE #\(requestCount)")
        
        if defaults.bool(forKey: "newCategory") {
            loadSavedData()
            DispatchQueue.main.async { [unowned self] in
                self.tableView.reloadData()
                let range = NSMakeRange(0, self.tableView.numberOfSections)
                let sections = IndexSet(integersIn: range.toRange() ?? 0..<0)
                self.tableView.reloadSections(sections, with: .fade)
            }
            defaults.set(false, forKey: "newCategory")
        }
        
        if requestCount > 1 {
            if currentDayTime.compare(lastDayTime) == .orderedDescending || numberOfPosts == 0 {
                if numberOfPosts == 0 {
                    //First refresh
                    defaults.set(1, forKey: "NumberOfPosts")
                }
                print("📳 DAY #\(defaults.integer(forKey: "dayNumber") + 1)")
                lastDayTime = currentDayTime
                defaults.set(lastDayTime, forKey: "lastDayTime")
                
                update(true)
            }else{
                update(false)
            }
        }
        
        defaults.set(requestCount, forKey: "requestCount")
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
                                        if var text = post["text"] as? String {
                                            if let condition = post["conditions"] as? String{
                                                if let url = post["url"] as? String {
                                                    if let time = post["time"] as? Int {
                                                        if let image = post["image"] as? String {
                                                            if var description = post["description"] as? String {
                                                                DispatchQueue.main.async { [unowned self] in
                                                                    
                                                                    //Replace HTML special characters
                                                                    text = text.replacingOccurrences(of: "&quot;", with: "\"")
                                                                    text = text.replacingOccurrences(of: "&#039;", with: "'")
                                                                    description = description.replacingOccurrences(of: "&quot;", with: "\"")
                                                                    description = description.replacingOccurrences(of: "&#039;", with: "'")
                                                                    
                                                                    if self.arrayPosts.contains(text) == false && self.arrayTimes.contains(time) == false {
                                                                        print("✅ Added post: \"\(text)\" with time: \(time) and condition \(condition).")
                                                                        //ADD NEW POSTS
                                                                        let data = Post(context: self.container.viewContext)
                                                                        self.configure(post: data, text: text, description: description, condition: condition, link: url, image: image, time: time)
                                                                        self.saveContext()
                                                                        
                                                                        self.addPost(text: text, description: description, condition: condition, link: url, image: image, time: time)
                                                                        
                                                                        self.blinkTableView.beginUpdates()
                                                                        self.blinkTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
                                                                        self.blinkTableView.endUpdates()
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
            
            DispatchQueue.main.async { [unowned self] in
                self.myRefreshControl.endRefreshing()
            }
        }
        
        task.resume()
    }
    
    func update(_ newDay: Bool) {
        if isConnectedToNetwork(){
            if newDay {
                //Update day count
                let day = defaults.integer(forKey: "dayNumber") + 1
                defaults.set(day, forKey: "dayNumber")
                if day < 2 {
                    //First day update
                    baseURL = "http://services.conradi.si/blink/json.php?num=\(numberOfPosts)&advice=\(boolDefaultPosts[0])&cats=\(boolDefaultPosts[1])&curiosities=\(boolDefaultPosts[2])&daily=\(boolDefaultPosts[3])&quotes=\(boolDefaultPosts[4])&movies=\(boolDefaultPosts[5])&news=\(boolDefaultPosts[6])&numbers=\(boolDefaultPosts[7])&tech=\(boolDefaultPosts[8])&trending=\(boolDefaultPosts[9])&time=\(self.defaults.integer(forKey: "lastTime"))&token=cb5ffe91b428bed8a251dc098feced975687e0204d44451dc4869498311196fd"
                }else if day%2 == 0 {
                    //Make post order
                    var lastEvenUsed = Int(arc4random_uniform(2))
                    var lastOddUsed = 0
                    
                    evenPostOrder.removeAll()
                    oddPostOrder.removeAll()
                    
                    for i in 0..<boolDefaultPosts.count {
                        if boolDefaultPosts[i] == 1 && i != 5 && i != 6 && i != 8 && i != 9 {
                            if lastEvenUsed == 1 {
                                lastEvenUsed = 0
                                lastOddUsed = 1
                            }else{
                                lastEvenUsed = 1
                                lastOddUsed = 0
                            }
                            
                            evenPostOrder.append(lastEvenUsed)
                            oddPostOrder.append(lastOddUsed)
                        }else{
                            evenPostOrder.append(0)
                            oddPostOrder.append(0)
                        }
                    }
                    
                    //Save next day's schedule
                    defaults.set(oddPostOrder, forKey: "oddPostOrder")
                    
                    if evenPostOrder[3] == 1 {
                        //Increment post number for categories: Mysteries
                        numberOfPosts += 1
                        defaults.set(numberOfPosts, forKey: "NumberOfPosts")
                    }
                    
                    baseURL = "http://services.conradi.si/blink/json.php?num=\(numberOfPosts)&advice=\(evenPostOrder[0])&cats=\(evenPostOrder[1])&curiosities=\(evenPostOrder[2])&daily=\(evenPostOrder[3])&quotes=\(evenPostOrder[4])&movies=\(boolDefaultPosts[5])&news=\(boolDefaultPosts[6])&numbers=\(evenPostOrder[7])&tech=\(boolDefaultPosts[8])&trending=\(boolDefaultPosts[9])&time=\(self.defaults.integer(forKey: "lastTime"))&token=cb5ffe91b428bed8a251dc098feced975687e0204d44451dc4869498311196fd"
                }else{
                    oddPostOrder = defaults.object(forKey: "oddPostOrder") as! [Int]
                    
                    //Check if user has unsubscribed to any categories.
                    for i in 0..<boolDefaultPosts.count {
                        if boolDefaultPosts[i] == 0 && oddPostOrder[i] == 1 {
                            oddPostOrder[i] = 0
                        }
                    }
                    
                    if oddPostOrder[3] == 1 {
                        numberOfPosts += 1
                        defaults.set(numberOfPosts, forKey: "NumberOfPosts")
                    }
                    
                    baseURL = "http://services.conradi.si/blink/json.php?num=\(numberOfPosts)&advice=\(oddPostOrder[0])&cats=\(oddPostOrder[1])&curiosities=\(oddPostOrder[2])&daily=\(oddPostOrder[3])&quotes=\(oddPostOrder[4])&movies=\(boolDefaultPosts[5])&news=\(boolDefaultPosts[6])&numbers=\(oddPostOrder[7])&tech=\(boolDefaultPosts[8])&trending=\(boolDefaultPosts[9])&time=\(self.defaults.integer(forKey: "lastTime"))&token=cb5ffe91b428bed8a251dc098feced975687e0204d44451dc4869498311196fd"
                }
            }else{
                baseURL = "http://services.conradi.si/blink/json.php?num=\(numberOfPosts)&advice=0&cats=0&curiosities=0&daily=0&quotes=0&movies=\(boolDefaultPosts[5])&news=\(boolDefaultPosts[6])&numbers=0&tech=\(boolDefaultPosts[8])&trending=\(boolDefaultPosts[9])&time=\(self.defaults.integer(forKey: "lastTime"))&token=cb5ffe91b428bed8a251dc098feced975687e0204d44451dc4869498311196fd"
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
    
    func setUp() {
        //SET UP
        print("📳 Set up")
        arrayDefaultPosts = [["I'll try to help you with some advice. ⚖️", ""],
                             ["I know some of the best cat facts. 🐈 Because why not. And I'm lonely. Mostly because I'm lonely.", ""],
                             ["I'll satisfy your inner nerd by sending you interesting facts. ⭐️", ""],
                             ["Pure random stuff. Just for you. 💎", "0"],
                             ["Do you need some inspiration? I know some good quotes... 💬", ""],
                             ["I love movies. 🎬 I hope you love them too!", ""],
                             ["Jokes aside. Expect actual news from New York Times. 📰", "2"],
                             ["Some numbers are pretty mind-boggling. Here are especially nice ones. 🕵️‍♀️", ""],
                             ["💻 and ⌨️ and 🖥 and 🎮", ""],
                             ["When something weird happens, you'll know. 🔥", "1"]]
        /*["Beeb boop... ℏ ℇ ≺ ℔ ∦ ℵ ℞ ℬ.", ""],*/
        
        //Set default values
        boolDefaultPosts = [0, 0, 0, 1, 1, 0, 1, 0, 0, 1]
        defaults.set(arrayDefaultPosts, forKey: "arrayDefaultPosts")
        defaults.set(boolDefaultPosts, forKey: "boolDefaultPosts")
        defaults.set(0, forKey: "NumberOfPosts")
        defaults.set(0, forKey: "dayNumber")
        defaults.set(Int(NSDate().timeIntervalSince1970) - 5, forKey: "lastTime")
        defaults.set(true, forKey: "dailyNotifications")
        defaults.set(true, forKey: "shakeToSendFeedback")
        defaults.set(8, forKey: "notificationTimeHour")
        defaults.set(0, forKey: "notificationTimeMinute")
        defaults.set(calendar.startOfDay(for: Date()), forKey: "lastDayTime")
        
        //UPDATE
        //DEFINE URL
        //baseURL = "http://services.conradi.si/blink/json.php?num=0&cats=0&caveman=0&curiosities=0&daily=1&quotes=0&movies=0&news=1&numbers=0&space=0&tech=0&trending=1&time=\(Int(NSDate().timeIntervalSince1970))&token=cb5ffe91b428bed8a251dc098feced975687e0204d44451dc4869498311196fd"
        //print("ℹ️ URL: \(baseURL)")
        
        //ADD DEFAULT POSTS
        configDefaultPosts()
        saveContext()
    }
    
    
    //**********************************
    // MARK: Data managment
    //**********************************
    
    
    func addPost(text: String, description: String, condition: String, link: String, image: String, time: Int) {
        self.arrayPosts.insert(text, at: 0)
        self.arrayDescriptions.insert(description, at: 0)
        self.arrayLinks.insert(link, at: 0)
        self.arrayImages.insert(image, at: 0)
        self.arrayTimes.insert(time, at: 0)
        self.arrayConditions.insert(condition, at: 0)
    }
    
    func loadSavedData() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Post")
        
        // Helpers
        var result = [Post]()
        
        arrayPosts.removeAll()
        arrayDescriptions.removeAll()
        arrayLinks.removeAll()
        arrayImages.removeAll()
        arrayPosts.removeAll()
        arrayConditions.removeAll()
        
        do {
            // Execute Fetch Request
            let records = try container.viewContext.fetch(fetchRequest)
            
            if let records = records as? [Post] {
                result = records
            }
            
            for item in result {
                addPost(text: item.post, description: item.desc, condition: item.condition, link: item.link, image: item.image, time: item.time)
            }
        } catch {
            print("🆘 Unable to fetch managed objects for entity Post.")
        }
    }
    
    func reloadData() {
        boolDefaultPosts = defaults.object(forKey: "boolDefaultPosts") as! [Int]
        numberOfPosts = defaults.integer(forKey: "NumberOfPosts")
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
        configure(post: data1, text: arrayDefaultPosts[9][0], description: "", condition: "10", link: "0", image: "0", time: 1)
        saveContext()
        addPost(text: arrayDefaultPosts[9][0], description: "", condition: "10", link: "0", image: "0", time: 1)
        
        let data2 = Post(context: container.viewContext)
        configure(post: data2, text: arrayDefaultPosts[6][0], description: "", condition: "7", link: "0", image: "0", time: 2)
        saveContext()
        addPost(text: arrayDefaultPosts[6][0], description: "", condition: "7", link: "0", image: "0", time: 2)
        
        let data3 = Post(context: container.viewContext)
        configure(post: data3, text: arrayDefaultPosts[3][0], description: "", condition: "4", link: "0", image: "0", time: 3)
        saveContext()
        addPost(text: arrayDefaultPosts[3][0], description: "", condition: "4", link: "0", image: "0", time: 3)
        
        let data4 = Post(context: container.viewContext)
        configure(post: data4, text: "Hi! I'm Blink. Return every day and I'll try to make your day better. 🍹", description: "", condition: "100", link: "0", image: "0", time: 100)
        saveContext()
        addPost(text: "Hi! I'm Blink. Return every day and I'll try to make your day better. 🍹", description: "", condition: "100", link: "0", image: "0", time: 100)
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
    
    func getCondition(_ i: String) -> String {
        if i == "1" {
            return "Advice"
        }else if i == "2"{
            return "Cat facts"
        }else if i == "3" {
            return "Curiosities"
        }else if i == "4" {
            return "Mysteries"
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
