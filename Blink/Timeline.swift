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
import UserNotifications
import UserNotificationsUI

class PostCell: UITableViewCell {
    @IBOutlet var postLabel: UILabel!
    @IBOutlet var typeLabel: UILabel!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var imageShadowView: UIView!
    @IBOutlet weak var heightViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var alternativeImage: UIImageView!
    @IBOutlet weak var alternativeImageHeight: NSLayoutConstraint!
    @IBOutlet weak var alternativeImageWidth: NSLayoutConstraint!
    @IBOutlet weak var alternativeImageBlur: UIVisualEffectView!
    
    override func didMoveToSuperview() {
        self.layoutIfNeeded()
    }
    
    /*override func awakeFromNib() {
        super.awakeFromNib()
        self.layoutIfNeeded()
    }*/
}

class PostsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, UIViewControllerPreviewingDelegate {
    
    //**********************************
    // MARK: Variables
    //**********************************
    
    //Outlets
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var navigationView: UIView!
    @IBOutlet weak var blur: UIVisualEffectView!
    @IBOutlet weak var blurView: UIView!
    @IBOutlet weak var cardView: UIView!
    
    //Notifications
    let requestIdentifier = "DailyReminder"
    let center = UNUserNotificationCenter.current()
    
    //Transition
    let interactor = Interactor()
    
    //Core data
    var container: NSPersistentContainer!
    
    //Stuff
    var screenSize = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    let refreshControl: UIRefreshControl = UIRefreshControl()
    let defaults = UserDefaults.standard
    let calendar = Calendar(identifier: .gregorian)
    var version = "1.0"
    
    var arrayPosts = [String]()
    var arrayDescriptions = [String]()
    var arrayLinks = [String]()
    var arrayImages = [String]()
    var arrayImageSizes = [[Double]]()
    var arrayTimes = [Int]()
    var arrayConditions = [String]()
    
    //Helpers: appearance
    var arrayAnswered = [Int]()
    var arrayClicked = [Int]()
    var hasAnimated = false
    var landscape = false
    
    //Helpers: time managment
    var currentDayTime = Date()
    var lastDayTime = Date()
    var isUpdating = false
    
    //Helpers: post management
    var boolDefaultPosts = [Int]()
    var dailyPostNumber = 0
    var fridayPostNumber = 0
    var requestCount = 0
    var baseURL = ""
    var olderHeaderIndex = 0
    var configureFridayPost = false
    
    //Helpers: default posts
    var arrayDefaultPosts = [String]()
    var arrayAddedDefaultPosts = [Int: String]()
    
    //Helpers: 3D touch previews
    var indexPathRow = 0
    
    //Helpers: version checking
    var updates = [String: Int]()
    
    
    //**********************************
    // MARK: Essential functions
    //**********************************
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        screenSize = self.view.bounds
        NotificationCenter.default.addObserver(self, selector: #selector(dataRefresh), name: .UIApplicationDidBecomeActive, object: nil)
        prepareCoreData()
        prepareTableView()
        getData()
        prepareViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if (defaults.bool(forKey: "welcomeScreen")) {
            tableView.layer.opacity = 1
            if !hasAnimated {
                hasAnimated = true
                animateTable()
            }else{
                dataRefresh()
            }
        }else{
            tableView.layer.opacity = 0
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (!defaults.bool(forKey: "welcomeScreen")) {
            let welcomeViewController = self.storyboard?.instantiateViewController(withIdentifier: "WelcomeViewController") as! WelcomeViewController
            welcomeViewController.modalTransitionStyle = .coverVertical
            welcomeViewController.modalPresentationStyle = .fullScreen
            self.present(welcomeViewController, animated: true, completion: {})
            defaults.set(true, forKey: "welcomeScreen")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        refreshControl.endRefreshing()
        defaults.synchronize()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        SDImageCache.shared().clearMemory()
    }
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        switch toInterfaceOrientation {
        case .landscapeLeft, .landscapeRight:
            landscape = true
        default:
            landscape = false
        }
    }
    
    func animateTable() {
        tableView.reloadData()
        
        let cells = tableView.visibleCells
        let tableHeight: CGFloat = tableView.bounds.size.height
        
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
    
    @IBAction func scrollToTop(_ sender: Any) {
        tableView.setContentOffset(CGPoint(x: 0,y :-94), animated: true)
    }
    
    @IBAction func presentSettingsAction(_ sender: Any) {
        tapped()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            self.blur.effect = nil
            self.blurView.layer.opacity = 0
            self.blur.isHidden = true
        }
    }
    
    @IBAction func skipAction(_ sender: Any) {
        UIView.animate(withDuration: 0.5, animations: {
            self.blur.effect = nil
            self.blurView.layer.opacity = 0
        }) { (true) in
            self.blur.isHidden = true
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    //**********************************
    // MARK: Peek & poop
    //**********************************
    
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if !landscape {
            guard let indexPath = tableView.indexPathForRow(at: location), let cell = tableView.cellForRow(at: indexPath) as? PostCell else { return nil }
            
            if arrayConditions[indexPath.row] == "10" && arrayImages[indexPath.row] != "" {
                guard let detailViewController = storyboard?.instantiateViewController(withIdentifier: "PhotoPreviewViewController") as? PhotoPreviewViewController else { return nil }
                detailViewController.imageURL = arrayImages[indexPath.row]
                indexPathRow = indexPath.row
                
                detailViewController.preferredContentSize = CGSize(width: CGFloat(arrayImageSizes[indexPathRow][0]), height: CGFloat(arrayImageSizes[indexPathRow][1]))
                
                previewingContext.sourceRect = tableView.convert(cell.imageShadowView.frame, from: cell.imageShadowView.superview)
                return detailViewController
            }else if arrayLinks[indexPath.row] != "" && arrayDescriptions[indexPath.row] != "" && arrayImages[indexPath.row] != "" {
                guard let detailViewController = storyboard?.instantiateViewController(withIdentifier: "PreviewViewController") as? PreviewViewController else { return nil }
                detailViewController.headline = arrayPosts[indexPath.row]
                detailViewController.desc = arrayDescriptions[indexPath.row]
                detailViewController.imageUrl = arrayImages[indexPath.row]
                detailViewController.condition = arrayConditions[indexPath.row]
                detailViewController.imageSize = arrayImageSizes[indexPath.row]
                indexPathRow = indexPath.row
                detailViewController.preferredContentSize = CGSize(width: 0.0, height: 650)
                
                //previewingContext.sourceRect = cell.frame
                let rect1 = tableView.convert(cell.cardView.frame, from: cell.cardView.superview)
                let rect2 = tableView.convert(cell.imageShadowView.frame, from: cell.imageShadowView.superview)
                previewingContext.sourceRect = rect1.union(rect2)
                
                return detailViewController
            }
        }
        
        return nil
    }
    
    private func touchedView(view: UIView, location: CGPoint) -> Bool {
        return view.bounds.contains(view.convert(location, from: tableView))
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if arrayConditions[indexPathRow] == "10" {
            if let photoGalleryViewController = storyboard?.instantiateViewController(withIdentifier: "PhotoGalleryViewController") as? PhotoGalleryViewController {
                photoGalleryViewController.imageURL = arrayImages[indexPathRow]
                photoGalleryViewController.imageText = arrayPosts[indexPathRow]
                photoGalleryViewController.transitioningDelegate = self
                photoGalleryViewController.interactor = interactor
                present(photoGalleryViewController, animated: true)
            }
        }else if arrayLinks[indexPathRow] != "" {
            if let url = URL(string: arrayLinks[indexPathRow]) {
                let webPreview = SFSafariViewController(url: url, entersReaderIfAvailable: false)
                webPreview.preferredControlTintColor = UIColor.black
                webPreview.modalPresentationStyle = .overFullScreen
                present(webPreview, animated: true)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.cellForRow(at: indexPath)?.isSelected = false;
            
            if segue.identifier == "showImageSegue" {
                if let photoGalleryViewController = segue.destination as? PhotoGalleryViewController {
                    photoGalleryViewController.imageURL = arrayImages[indexPath.row]
                    photoGalleryViewController.imageText = arrayPosts[indexPath.row]
                    photoGalleryViewController.transitioningDelegate = self
                    photoGalleryViewController.interactor = interactor
                }
            }else if segue.identifier == "showPostSegue" {
                if let postGalleryViewController = segue.destination as? PostGalleryViewController {
                    postGalleryViewController.post = arrayPosts[indexPath.row]
                    postGalleryViewController.desc = arrayDescriptions[indexPath.row]
                    postGalleryViewController.url = arrayLinks[indexPath.row]
                    postGalleryViewController.condition = arrayConditions[indexPath.row]
                    postGalleryViewController.transitioningDelegate = self
                    postGalleryViewController.interactor = interactor
                }
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "showCategoriesSegue" || identifier == "noConnectionSegue" {
            return true
        }
        if let indexPath = tableView.indexPathForSelectedRow {
            if identifier == "showImageSegue" {
                if arrayConditions[indexPath.row] == "10" && arrayPosts[indexPath.row] != "Beeb boop... ℏ ℇ ≺ ℔ ∦ ℵ ℞ ℬ." {
                    return true
                }
            }else if identifier == "showPostSegue" {
                if !(defaults.object(forKey: "arrayDefaultPosts") as! [String]).contains(arrayPosts[indexPath.row]) && arrayPosts[indexPath.row] != "Hi! I'm Blink. Return every day and I'll try to make your day better. 🍹" {
                    switch arrayConditions[indexPath.row] {
                    case "1", "2", "3", "4", "5", "6", "9", "13":
                        return true
                    default:
                        return false
                    }
                }
            }
        }
        
        return false
    }
    
    
    //**********************************
    // MARK: TableView
    //**********************************
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayPosts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if arrayPosts[indexPath.row] == "**EARLY**" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "olderHeaderCell", for: indexPath) as UITableViewCell
            return cell
        }else if arrayPosts[indexPath.row] == "**NOCON**" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "noConnectionCell", for: indexPath) as! PostCell
            return cell
        }
        //Data managment
        let post = NSMutableAttributedString()
        let rawPost = arrayPosts[indexPath.row]
        var cellWidth = self.view.bounds.width - 70
        
        if self.view.bounds.width > 570 {
            cellWidth = 500
        }
        
        if arrayDefaultPosts.contains(rawPost) {
            if arrayClicked.contains(indexPath.row) {
                post.append(NSMutableAttributedString(string: "You've subscribed to \(getCondition(arrayConditions[indexPath.row]))."))
            }else{
                post.append(NSMutableAttributedString(string: rawPost))
            }
        }else{
            switch arrayConditions[indexPath.row] {
            case "7", "8", "11", "12" :
                if arrayLinks[indexPath.row] != "" {
                    let attributes = [NSForegroundColorAttributeName: UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1)]
                    let touchForMore = NSMutableAttributedString(string: " Touch for more...", attributes: attributes)
                    
                    post.append(NSMutableAttributedString(string: rawPost))
                    post.append(touchForMore)
                }else{
                    post.append(NSMutableAttributedString(string: rawPost))
                }
            case "10" :
                let attributes = [NSForegroundColorAttributeName: UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1)]
                let touchForMore = NSMutableAttributedString(string: " Touch to view...", attributes: attributes)
                
                post.append(NSMutableAttributedString(string: rawPost))
                post.append(touchForMore)
            default:
                post.append(NSMutableAttributedString(string: rawPost))
            }
        }
        
        switch arrayImages[indexPath.row] {
        case "":
            let cell = tableView.dequeueReusableCell(withIdentifier: "postCellNoImage", for: indexPath) as! PostCell
            
            cell.cardView.layer.shadowColor = UIColor.black.cgColor
            cell.cardView.layer.shadowRadius = 25
            cell.cardView.layer.shadowOpacity = 0.15
            
            cell.typeLabel.text = getCondition(arrayConditions[indexPath.row])
            cell.postLabel.attributedText = post
            
            cell.layoutIfNeeded()
            
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "postCellWithImage", for: indexPath) as! PostCell
            
            cell.imageShadowView.layer.shadowColor = UIColor.black.cgColor
            cell.imageShadowView.layer.shadowRadius = 25
            cell.imageShadowView.layer.shadowOpacity = 0.15
            cell.postImageView.sd_setImage(with: URL(string: arrayImages[indexPath.row]), placeholderImage: nil, options: [.progressiveDownload, .continueInBackground])
            cell.alternativeImageBlur.isHidden = true
            
            if arrayImageSizes[indexPath.row].count == 2 {
                if arrayImageSizes[indexPath.row][0] != 0 || arrayImageSizes[indexPath.row][1] != 0 {
                    if CGFloat(arrayImageSizes[indexPath.row][0]) >= cellWidth + 30 {
                        let newHeight = (cellWidth + 30) * CGFloat(arrayImageSizes[indexPath.row][1]) / CGFloat(arrayImageSizes[indexPath.row][0])
                        if newHeight < screenSize.height - 200 {
                            cell.heightViewConstraint.constant = newHeight
                        }else{
                            cell.heightViewConstraint.constant = screenSize.height - 200
                        }
                    }else{
                        cell.alternativeImageBlur.isHidden = false
                        cell.alternativeImage.sd_setImage(with: URL(string: arrayImages[indexPath.row]), placeholderImage: nil, options: [.progressiveDownload, .continueInBackground])
                        cell.alternativeImageWidth.constant = CGFloat(arrayImageSizes[indexPath.row][0])
                        cell.alternativeImageHeight.constant = CGFloat(arrayImageSizes[indexPath.row][1])
                        cell.heightViewConstraint.constant = CGFloat(arrayImageSizes[indexPath.row][1]) + (cellWidth + 30 - CGFloat(arrayImageSizes[indexPath.row][0])) / 2
                    }
                }else{
                    cell.heightViewConstraint.constant = 225
                }
            }else{
                cell.heightViewConstraint.constant = 225
            }
            
            cell.cardView.layer.shadowColor = UIColor.black.cgColor
            cell.cardView.layer.shadowRadius = 25
            cell.cardView.layer.shadowOpacity = 0.15
            
            cell.typeLabel.text = getCondition(arrayConditions[indexPath.row])
            cell.postLabel.attributedText = post
            
            cell.layoutIfNeeded()
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !arrayDefaultPosts.contains(arrayPosts[indexPath.row]) {
            switch arrayConditions[indexPath.row] {
            case "7", "8", "11", "12":
                if let url = URL(string: arrayLinks[indexPath.row]) {
                    let safariViewController = SFSafariViewController(url: url, entersReaderIfAvailable: false)
                    safariViewController.preferredControlTintColor = UIColor.black
                    safariViewController.modalPresentationStyle = .overFullScreen
                    present(safariViewController, animated: true)
                }
            default:
                break
            }
        }else{
            if arrayClicked.count >= 3 {
                let row = arrayClicked[0]
                arrayClicked.removeFirst()
                tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
            }else if !arrayClicked.contains(indexPath.row) {
                arrayClicked.append(indexPath.row)
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }else{
                for i in 0..<arrayClicked.count {
                    if arrayClicked[i] == indexPath.row {
                        arrayClicked.remove(at: i)
                        tableView.reloadRows(at: [indexPath], with: .automatic)
                        break;
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if arrayImages[indexPath.row] == "" {
            return 200
        }else if arrayPosts[indexPath.row] == "**EARLY**" {
            return 75
        }else if arrayPosts[indexPath.row] == "**NOCON**" {
            return 150
        }
        
        return 500
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if arrayPosts[indexPath.row] == "**EARLY**" {
            return 75
        }
        
        return UITableViewAutomaticDimension
    }
    
    
    //**********************************
    // MARK: Getting data
    //**********************************
    
    
    @objc func dataRefresh() {
        if !isUpdating {
            isUpdating = true
            defaults.synchronize()
            //Reload all variables
            if hasAnimated {
                reloadVariables()
            }
            
            //Remove old no connection row
            if arrayPosts.count > 0 {
                if arrayPosts[0] == "**NOCON**" {
                    self.arrayPosts.remove(at: 0)
                    self.arrayDescriptions.remove(at: 0)
                    self.arrayLinks.remove(at: 0)
                    self.arrayImages.remove(at: 0)
                    self.arrayImageSizes.remove(at: 0)
                    self.arrayTimes.remove(at: 0)
                    self.arrayConditions.remove(at: 0)
                    tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                }
            }
            
            //Remove all anwsers
            let tempAnwsers = arrayAnswered
            arrayAnswered.removeAll()
            for i in 0..<tempAnwsers.count {
                tableView.reloadRows(at: [IndexPath(row: tempAnwsers[i], section: 0)], with: .automatic)
            }
            
            if defaults.bool(forKey: "newCategory") {
                defaults.set(false, forKey: "newCategory")
                loadSavedData()
                isUpdating = false
            }else{
                requestCount += 1
                print("📳 REQUEST UPDATE #\(requestCount)")
                if requestCount > 1 {
                    if dailyPostNumber == 0 {
                        //First refresh
                        defaults.set(1, forKey: "dailyPostNumber")
                        print("📳 DAY #\(defaults.integer(forKey: "dayNumber") + 1)")
                        lastDayTime = currentDayTime
                        defaults.set(lastDayTime, forKey: "lastDayTime")
                        
                        loadSavedData()
                    }
                    
                    if currentDayTime.compare(lastDayTime) == .orderedDescending {
                        print("📳 DAY #\(defaults.integer(forKey: "dayNumber") + 1)")
                        lastDayTime = currentDayTime
                        defaults.set(lastDayTime, forKey: "lastDayTime")
                        
                        loadSavedData()
                        prepareRequest(newDay: true)
                    }else{
                        loadSavedData()
                        prepareRequest(newDay: false)
                    }
                    //isUpdating = false will be called once download completes
                }else{
                    loadSavedData()
                    isUpdating = false
                }
                defaults.set(requestCount, forKey: "requestCount")
            }
            
            defaults.synchronize()
        }else{
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    func prepareRequest(newDay: Bool) {
        if isConnectedToNetwork(){
            if newDay {
                //Update day count
                let day = defaults.integer(forKey: "dayNumber") + 1
                defaults.set(day, forKey: "dayNumber")
                //Fortune cookies
                if boolDefaultPosts[3] == 1 && day%2 == 0 {
                    //Increment post number for categories: Fortune cookies
                    dailyPostNumber += 1
                    defaults.set(dailyPostNumber, forKey: "dailyPostNumber")
                }
                //Is it Friday yet?
                configureFridayPost = true
            }
            baseURL = "http://services.conradi.si/blink/download.php?num=\(dailyPostNumber)&advice=\(boolDefaultPosts[0])&cats=\(boolDefaultPosts[1])&curiosities=\(boolDefaultPosts[2])&daily=\(boolDefaultPosts[3])&quotes=\(boolDefaultPosts[4])&movies=\(boolDefaultPosts[6])&news=\(boolDefaultPosts[7])&numbers=\(boolDefaultPosts[8])&space=\(boolDefaultPosts[9])&sports=\(boolDefaultPosts[10])&tech=\(boolDefaultPosts[11])&time=\(self.defaults.integer(forKey: "lastTime"))&version=3&token=\(ApiKeys().iOSKey)"
            //DELAY 1 MIN
            if defaults.integer(forKey: "lastTime") < Int(Date().timeIntervalSince1970) - 60 {
                defaults.set(Int(Date().timeIntervalSince1970), forKey: "lastTime")
                print("ℹ️ Request URL: \(baseURL)")
                //DOWNLOAD POSTS FROM SERVER
                performSelector(inBackground: #selector(makeRemoteRequest), with: nil)
            }
            if defaults.bool(forKey: "dailyNotifications") {
                scheduleNotification()
            }
        }else{
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                /*self.arrayPosts.insert("**NOCON**", at: 0)
                self.arrayDescriptions.insert("", at: 0)
                self.arrayLinks.insert("", at: 0)
                self.arrayImages.insert("", at: 0)
                self.arrayImageSizes.insert([0, 0], at: 0)
                self.arrayTimes.insert(Int(Date().timeIntervalSince1970), at: 0)
                self.arrayConditions.insert("", at: 0)
                self.tableView.beginUpdates()
                self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
                self.tableView.endUpdates()*/
            
                self.refreshControl.endRefreshing()
                self.isUpdating = true
            }
        }
    }
    
    func addFridayPost() {
        var text = ""
        switch getDayOfWeek() {
        case 1:
            //"Sun"
            text = "No. Sadly."
        case 2:
            //"Mon"
            let anwsers = ["Nope.", "Not even close.", "Help."]
            text = anwsers[Int(arc4random_uniform(UInt32(anwsers.count)))]
        case 3:
            //"Tue"
            let anwsers = ["I think not. But I'm not sure either.", "Probably not.", "I think the last Friday was nine days ago."]
            text = anwsers[Int(arc4random_uniform(UInt32(anwsers.count)))]
        case 4:
            //"Wed"
            let anwsers = ["I thought it was yesterday, but I was wrong.", "I'm pretty sure it was supposed to be today."]
            text = anwsers[Int(arc4random_uniform(UInt32(anwsers.count)))]
        case 5:
            //"Thu"
            let anwsers = ["Soon.", "Very close."]
            text = anwsers[Int(arc4random_uniform(UInt32(anwsers.count)))]
        case 6:
            //"Fri"
            let anwsers = ["Yep.", "Yes!", "It is indeed.", "Finally."]
            text = anwsers[Int(arc4random_uniform(UInt32(anwsers.count)))]
        case 7:
            //"Sat"
            text = "You've missed it."
        default:
            print("🆘 Error fetching days")
            return
        }
        
        let data = Post(context: self.container.viewContext)
        self.configure(post: data, text: text, description: "", condition: "6", link: "", image: "", imageSize: [0, 0], time: Int(Date().timeIntervalSince1970))
        self.saveContext()
        self.addPost(text: text, description: "", condition: "6", link: "", image: "", imageSize: [0, 0], time: Int(Date().timeIntervalSince1970))
        self.tableView.beginUpdates()
        self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
        self.tableView.endUpdates()
        print("✅ Added Friday post.")
    }
    
    @objc func makeRemoteRequest() {
        let url = URL(string: self.baseURL)
        let session = URLSession.shared
        
        let task = session.dataTask(with: url!) { (data:Data?, response:URLResponse?, error:Error?) in
            if error != nil {
                print("🆘 Error with connection: \(String(describing: error))")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.refreshControl.endRefreshing()
                }
                self.isUpdating = false
            } else {
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options:.allowFragments) as? [String: Any]
                    
                    if json?["status"] as? String == "ok" {
                        DispatchQueue.main.sync {
                            if self.olderHeaderIndex > 0 {
                                //Remove old header
                                self.arrayPosts.remove(at: self.olderHeaderIndex)
                                self.arrayDescriptions.remove(at: self.olderHeaderIndex)
                                self.arrayLinks.remove(at: self.olderHeaderIndex)
                                self.arrayImages.remove(at: self.olderHeaderIndex)
                                self.arrayImageSizes.remove(at: self.olderHeaderIndex)
                                self.arrayTimes.remove(at: self.olderHeaderIndex)
                                self.arrayConditions.remove(at: self.olderHeaderIndex)
                                self.tableView.reloadData()
                            }
                        }
                        
                        var olderHeaderNewIndex = 0
                        
                        if let posts = json?["posts"] as? [[String: AnyObject]] {
                            for post in posts {
                                if var text = post["text"] as? String {
                                    if let condition = post["conditions"] as? String{
                                        if let url = post["url"] as? String {
                                            if let time = post["time"] as? Int {
                                                if let image = post["image"] as? String {
                                                    if let description = post["description"] as? String {
                                                        if let imageSize = post["imageSize"] as? String {
                                                            DispatchQueue.main.sync {
                                                                //Safety check
                                                                if text != "" {
                                                                    switch condition {
                                                                    case "7":
                                                                        text = "Review: " + text
                                                                    case "8":
                                                                        text = "Headline: " + text
                                                                    default:
                                                                        break;
                                                                    }
                                                                    
                                                                    if condition == "7" || condition == "8" || condition == "10" || condition == "11" || condition == "12" {
                                                                        if text.characters.last != "?" && text.characters.last != "!" && text.characters.last != "." && text.characters.last != "\"" && text.characters.last != ")" {
                                                                            text = text + "."
                                                                        }
                                                                    }
                                                                    
                                                                    let imageSizeComponents: [String] = imageSize.components(separatedBy: "*")
                                                                    
                                                                    // And then to access the individual words:
                                                                    var width: Double = 0
                                                                    var height: Double = 0
                                                                    if imageSizeComponents.count == 2 {
                                                                        width = Double(imageSizeComponents[0]) ?? 0
                                                                        height = Double(imageSizeComponents[1]) ?? 0
                                                                    }
                                                                    
                                                                    if !self.arrayPosts.contains(text) {
                                                                        olderHeaderNewIndex += 1
                                                                        //ADD NEW POSTS
                                                                        let data = Post(context: self.container.viewContext)
                                                                        self.configure(post: data, text: text, description: description, condition: condition, link: url, image: image, imageSize: [width, height], time: time)
                                                                        self.saveContext()
                                                                        
                                                                        self.addPost(text: text, description: description, condition: condition, link: url, image: image, imageSize: [width, height], time: time)
                                                                        self.tableView.beginUpdates()
                                                                        self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
                                                                        self.tableView.endUpdates()
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
                            
                            DispatchQueue.main.sync {
                                //Is it friday yet?
                                if self.boolDefaultPosts[5] == 1 && self.configureFridayPost {
                                    self.fridayPostNumber = self.defaults.integer(forKey: "fridayPostNumber")
                                    if self.fridayPostNumber == 0 {
                                        self.fridayPostNumber = Int(arc4random_uniform(UInt32(4))) + 1
                                        self.addFridayPost()
                                        olderHeaderNewIndex += 1
                                    }
                                    self.fridayPostNumber -= 1
                                    self.defaults.set(self.fridayPostNumber, forKey: "fridayPostNumber")
                                    self.configureFridayPost = false
                                }
                                
                                if olderHeaderNewIndex > 0 {
                                    //Header
                                    self.arrayPosts.insert("**EARLY**", at: olderHeaderNewIndex)
                                    self.arrayDescriptions.insert("", at: olderHeaderNewIndex)
                                    self.arrayLinks.insert("", at: olderHeaderNewIndex)
                                    self.arrayImages.insert("", at: olderHeaderNewIndex)
                                    self.arrayImageSizes.insert([0, 0], at: olderHeaderNewIndex)
                                    self.arrayTimes.insert(Int(Date().timeIntervalSince1970), at: olderHeaderNewIndex)
                                    self.arrayConditions.insert("", at: olderHeaderNewIndex)
                                    self.tableView.beginUpdates()
                                    self.tableView.insertRows(at: [IndexPath(row: olderHeaderNewIndex, section: 0)], with: .top)
                                    self.tableView.endUpdates()
                                    self.olderHeaderIndex = olderHeaderNewIndex
                                }
                            }
                        }else{
                            print("⏸ Timeout: \(self.defaults.integer(forKey: "lastTime")) < \(Int(Date().timeIntervalSince1970) - 60)")
                        }
                    }else if json?["status"] as? String == "update" {
                        let alert = UIAlertController(title: "Update Blink", message: "New version of Blink is available for download.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true, completion:nil)
                    }
                    print("❎ Download process complete.")
                    
                    DispatchQueue.main.sync {
                        self.refreshControl.endRefreshing()
                    }
                    self.isUpdating = false
                } catch {
                    print("🆘 Something went wrong during data download from the server.")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.refreshControl.endRefreshing()
                        let alert = UIAlertController(title: "Something failed", message: "An error occurred connectiong to network.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true, completion:nil)
                        self.isUpdating = false
                    }
                }
            }
        }
        
        task.resume()
    }
    
    func setUp() {
        //SET UP
        print("📳 Set up")
        version = "1.5.2"
        defaults.set(version, forKey: "version")
        defaults.set(version, forKey: "setUpVersion")
        arrayDefaultPosts = ["I'll try to help you with some advice. ⚖️",
                             "I know some of the best cat facts. 🐈 Because why not. And I'm lonely. Mostly because I'm lonely.",
                             "I'll satisfy your inner nerd by sending you interesting facts. ⭐️",
                             "Pure random stuff. Just for you. 💎",
                             "Do you need some inspiration? I know some good quotes... 💬",
                             "Let me answer this mighty question. 🔮",
                             "I love movies. 🎬 I hope you love them too!",
                             "Jokes aside. Expect actual news from New York Times. 📰",
                             "Some numbers are pretty mind-boggling. Here are especially nice ones. 🕵️‍♀️",
                             "Beeb boop... ℏ ℇ ≺ ℔ ∦ ℵ ℞ ℬ.",
                             "No one ever says, “It’s only a game.” when their team is winning. 🏋️‍♀️",
                             "💻 and ⌨️ and 🖥 and 🎮"]
        
        //Set default values
        boolDefaultPosts = [0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0]
        updates = ["1.3.1": 0]
        defaults.set(updates, forKey: "updates")
        defaults.set(arrayDefaultPosts, forKey: "arrayDefaultPosts")
        defaults.set(boolDefaultPosts, forKey: "boolDefaultPosts")
        defaults.set(0, forKey: "dailyPostNumber")
        defaults.set(0, forKey: "fridayPostNumber")
        defaults.set(0, forKey: "dayNumber")
        defaults.set(Int(Date().timeIntervalSince1970) - 60, forKey: "lastTime")
        defaults.set(true, forKey: "dailyNotifications")
        defaults.set(true, forKey: "shakeToSendFeedback")
        defaults.set(8, forKey: "notificationTimeHour")
        defaults.set(0, forKey: "notificationTimeMinute")
        defaults.set(calendar.startOfDay(for: Date()), forKey: "lastDayTime")
        
        //ADD DEFAULT POSTS
        configDefaultPosts()
        
        defaults.synchronize()
    }
    
    
    //**********************************
    // MARK: Data managment
    //**********************************
    
    
    func addPost(text: String, description: String, condition: String, link: String, image: String, imageSize: [Double], time: Int) {
        arrayPosts.insert(text, at: 0)
        arrayDescriptions.insert(description, at: 0)
        arrayLinks.insert(link, at: 0)
        arrayImages.insert(image, at: 0)
        arrayImageSizes.insert(imageSize, at: 0)
        arrayTimes.insert(time, at: 0)
        arrayConditions.insert(condition, at: 0)
    }
    
    func loadSavedData() {
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
            
            if olderHeaderIndex > 0 {
                //Remove old header
                arrayPosts.remove(at: self.olderHeaderIndex)
                arrayDescriptions.remove(at: self.olderHeaderIndex)
                arrayLinks.remove(at: self.olderHeaderIndex)
                arrayImages.remove(at: self.olderHeaderIndex)
                arrayImageSizes.remove(at: self.olderHeaderIndex)
                arrayTimes.remove(at: self.olderHeaderIndex)
                arrayConditions.remove(at: self.olderHeaderIndex)
                tableView.beginUpdates()
                tableView.deleteRows(at: [IndexPath(row: self.olderHeaderIndex, section: 0)], with: .top)
                tableView.endUpdates()
                olderHeaderIndex = 0
            }
            
            if !hasAnimated {
                //On launch
                for item in result {
                    if !arrayPosts.contains(item.post) {
                        addPost(text: item.post, description: item.desc, condition: item.condition, link: item.link, image: item.image, imageSize: item.imageSize, time: item.time)
                        
                        //Because I was stubid
                        if item.time > updates["1.3.1"]! {
                            if arrayDefaultPosts.contains(item.post) {
                                arrayAddedDefaultPosts[item.time] = item.post
                            }
                        }
                    }else if arrayDefaultPosts.contains(item.post) {
                        if arrayAddedDefaultPosts[item.time] != item.post && item.time > updates["1.3.1"]! {
                            addPost(text: item.post, description: item.desc, condition: item.condition, link: item.link, image: item.image, imageSize: item.imageSize, time: item.time)
                            
                            arrayAddedDefaultPosts[item.time] = item.post
                        }
                    }
                }
            }else{
                for item in result {
                    if !arrayPosts.contains(item.post) {
                        addPost(text: item.post, description: item.desc, condition: item.condition, link: item.link, image: item.image, imageSize: item.imageSize, time: item.time)
                        tableView.beginUpdates()
                        tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
                        tableView.endUpdates()
                        
                        //Because I was stubid
                        if item.time > updates["1.3.1"]! {
                            if arrayDefaultPosts.contains(item.post) {
                                arrayAddedDefaultPosts[item.time] = item.post
                            }
                        }
                    }else if arrayDefaultPosts.contains(item.post) {
                        if arrayAddedDefaultPosts[item.time] != item.post && item.time > updates["1.3.1"]! {
                            addPost(text: item.post, description: item.desc, condition: item.condition, link: item.link, image: item.image, imageSize: item.imageSize, time: item.time)
                            tableView.beginUpdates()
                            tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
                            tableView.endUpdates()
                            
                            arrayAddedDefaultPosts[item.time] = item.post
                        }
                    }
                }
            }
        } catch {
            print("🆘 Unable to fetch managed objects for entity Post.")
        }
    }
    
    func reloadVariables() {
        defaults.synchronize()
        arrayDefaultPosts = defaults.object(forKey: "arrayDefaultPosts") as! [String]
        boolDefaultPosts = defaults.object(forKey: "boolDefaultPosts") as! [Int]
        updates = defaults.dictionary(forKey: "updates") as! [String : Int]
        dailyPostNumber = defaults.integer(forKey: "dailyPostNumber")
        fridayPostNumber = defaults.integer(forKey: "fridayPostNumber")
        currentDayTime = calendar.startOfDay(for: Date())
        lastDayTime = defaults.object(forKey: "lastDayTime") as! Date
        requestCount = defaults.integer(forKey: "requestCount")
        defaults.synchronize()
    }
    
    func configure(post: Post, text: String, description: String, condition: String, link: String, image: String, imageSize: [Double], time: Int) {
        post.post = text
        post.desc = description
        post.condition = condition
        post.link = link
        post.image = image
        post.imageSize = imageSize
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
        let data2 = Post(context: container.viewContext)
        configure(post: data2, text: arrayDefaultPosts[4], description: "", condition: "5", link: "", image: "", imageSize: [0, 0], time: 1)
        saveContext()
        //addPost(text: arrayDefaultPosts[4], description: "", condition: "5", link: "", image: "", time: 3)
        
        let data3 = Post(context: container.viewContext)
        configure(post: data3, text: arrayDefaultPosts[3], description: "", condition: "4", link: "", image: "", imageSize: [0, 0], time: 2)
        saveContext()
        //addPost(text: arrayDefaultPosts[3], description: "", condition: "4", link: "", image: "", time: 4)
        
        
        //First posts
        let data4 = Post(context: container.viewContext)
        configure(post: data4, text: "\"Life's challenges are not supposed to paralyse you, they're supposed to help you discover who you are.\" — Bernice Reagon", description: "", condition: "5", link: "", image: "", imageSize: [0, 0], time: Int(Date().timeIntervalSince1970))
        saveContext()
        //addPost(text: "\"Life's challenges are not supposed to paralyse you, they're supposed to help you discover who you are.\" — Bernice Reagon", description: "", condition: "5", link: "", image: "", time: Int(Date().timeIntervalSince1970) + 3)
        
        let data5 = Post(context: container.viewContext)
        configure(post: data5, text: "Silence is golden. Duck tape is silver.", description: "", condition: "4", link: "", image: "", imageSize: [0, 0], time: Int(Date().timeIntervalSince1970))
        saveContext()
        //addPost(text: "Silence is golden. Duck tape is silver.", description: "", condition: "4", link: "", image: "", time: Int(Date().timeIntervalSince1970) + 3)
        
        let data1 = Post(context: container.viewContext)
        configure(post: data1, text: "Hi! I'm Blink. Return every day and I'll try to make your day better. 🍹", description: "", condition: "100", link: "", image: "", imageSize: [0, 0], time: 100)
        saveContext()
        //addPost(text: "Hi! I'm Blink. Return every day and I'll try to make your day better. 🍹", description: "", condition: "100", link: "", image: "", time: 100)
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
    
    func preparesShare(shareText: String?, shareImage: UIImage?){
        var objectsToShare = [Any]()
        
        if let shareTextObj = shareText{
            objectsToShare.append(shareTextObj)
        }
        if let shareImageObj = shareImage{
            objectsToShare.append(shareImageObj)
        }
        
        if shareText != nil || shareImage != nil{
            let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view
            activityViewController.excludedActivityTypes = [UIActivityType.airDrop, UIActivityType.addToReadingList, UIActivityType.postToVimeo, UIActivityType.openInIBooks]
            present(activityViewController, animated: true, completion: nil)
        }
    }
    
    
    //**********************************
    // MARK: Other methods
    //**********************************
    
    
    func versionChech() {
        defaults.synchronize()
        if (defaults.string(forKey: "version") == nil) {
            setUp()
        }else{
            switch defaults.string(forKey: "version")! {
            case "1.0" :
                arrayDefaultPosts = defaults.object(forKey: "arrayDefaultPosts") as! [String]
                boolDefaultPosts = defaults.object(forKey: "boolDefaultPosts") as! [Int]
                
                boolDefaultPosts.insert(0, at: 5)
                boolDefaultPosts.insert(0, at: 10)
                boolDefaultPosts.removeLast()
                defaults.set(boolDefaultPosts, forKey: "boolDefaultPosts")
                
                arrayDefaultPosts.insert("Let me answer this mighty question.", at: 5)
                arrayDefaultPosts.insert("No one ever says, “It’s only a game.” when their team is winning.", at: 10)
                arrayDefaultPosts.removeLast()
                defaults.set(arrayDefaultPosts, forKey: "arrayDefaultPosts")
                
                defaults.set(0, forKey: "fridayPostNumber")
                
                //1.3.1
                updates["1.3.1"] = Int(Date().timeIntervalSince1970)
                defaults.set(updates, forKey: "updates")
            case "1.1":
                arrayDefaultPosts = defaults.object(forKey: "arrayDefaultPosts") as! [String]
                boolDefaultPosts = defaults.object(forKey: "boolDefaultPosts") as! [Int]
                
                boolDefaultPosts.removeLast()
                defaults.set(boolDefaultPosts, forKey: "boolDefaultPosts")
                
                arrayDefaultPosts.removeLast()
                defaults.set(arrayDefaultPosts, forKey: "arrayDefaultPosts")
                
                //1.3.1
                updates["1.3.1"] = Int(Date().timeIntervalSince1970)
                defaults.set(updates, forKey: "updates")
            case "1.3":
                updates["1.3.1"] = Int(Date().timeIntervalSince1970)
                defaults.set(updates, forKey: "updates")
            default:
                break
            }
        }
        
        //dailyPostNumber = 100
        //defaults.set(dailyPostNumber, forKey: "dailyPostNumber")
        
        version = "1.5.2"
        defaults.set(version, forKey: "version")
        print("📳 Version: \(version)")
        defaults.synchronize()
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
    
    func getDayOfWeek() -> Int {
        let weekDay = calendar.component(.weekday, from: Date())
        return weekDay
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
            return "Fortune cookies" //4 (3)
        case "5":
            return "Inspiring quotes" //5 (4)
        case "6":
            return "Is it Friday yet?" //6 (5)
        case "7":
            return "Movie reviews" //7 (6)
        case "8":
            return "News" //8 (7)
        case "9":
            return "Number trivia" //9 (8)
        case "10":
            return "Space photos" //10 (9)
        case "11":
            return "Sports stuff" //11 (10)
        case "12":
            return "Tech talk" //12 (11)
        default:
            return "Blink" //Other
        }
    }
    
    
    //**********************************
    // MARK: Preparing app
    //**********************************
    
    
    func scheduleNotification() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        var oneDayfromNow: Date {
            return (Calendar.current as NSCalendar).date(byAdding: .day, value: 1, to: Date(), options: [])!
        }
        
        var notificationTime = (calendar as NSCalendar).components([.year, .month, .day, .hour, .minute, .second], from: oneDayfromNow)
        notificationTime.hour = defaults.integer(forKey: "notificationTimeHour")
        notificationTime.minute = defaults.integer(forKey: "notificationTimeMinute")
        
        let content = UNMutableNotificationContent()
        content.body = "I have something for you..."
        content.sound = UNNotificationSound.default()
        content.badge = 1
        
        let trigger = UNCalendarNotificationTrigger.init(dateMatching: notificationTime, repeats: true)
        let request = UNNotificationRequest(identifier:requestIdentifier, content: content, trigger: trigger)
        
        center.add(request)
    }
    
    func prepareViews() {
        //Welcome blur
        if (defaults.bool(forKey: "welcomeBlur")) {
            blur.effect = nil
            blurView.layer.opacity = 0
            blur.isHidden = true
        }else{
            blur.effect = UIBlurEffect(style: .regular)
            defaults.set(true, forKey: "welcomeBlur")
        }
        
        let color1 = UIColor(red: 222/255, green: 222/255, blue: 222/255, alpha: 1).cgColor
        let color2 = UIColor(red: 222/255, green: 222/255, blue: 222/255, alpha: 0).cgColor
        
        //NavigationBar
        var x: CGFloat = 0
        if screenSize.height > screenSize.width {
            x = screenSize.height
        }else{
            x = screenSize.width
            landscape = true
        }
        
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.colors = [color2, color1]
        gradient.locations = [0.0 , 0.3]
        gradient.startPoint = CGPoint(x: 1.0, y:1.0)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.0)
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: x, height: 94)
        navigationView.layer.insertSublayer(gradient, at: 0)
        
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowRadius = 25
        cardView.layer.shadowOpacity = 0.25
        
        //LayoutIfNeeded
        self.view.layoutIfNeeded()
    }
    
    func prepareTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        refreshControl.addTarget(self, action: #selector(dataRefresh), for: .valueChanged)
        tableView.addSubview(refreshControl)
        self.automaticallyAdjustsScrollViewInsets = false
        tableView.contentInset = UIEdgeInsetsMake(94, 0, 20, 0)
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()
        
        //3D touch
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: tableView)
        } else {
            //No 3D touch
        }
    }
    
    func getData() {
        //Check app version and perform necessary updates
        versionChech()
        //Reload data
        reloadVariables()
        //Load posts
        dataRefresh()
    }
    
    func prepareCoreData() {
        container = NSPersistentContainer(name: "myCoreDataModel")
        container.loadPersistentStores { storeDescription, error in
            self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            if let error = error {
                print("🆘 Unresolved error while configuring core data: \(error)")
            }
        }
    }
}

extension PostsViewController: UIViewControllerTransitioningDelegate {
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissAnimator()
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
}
