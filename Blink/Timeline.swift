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
    @IBOutlet weak var heightImageConstraint: NSLayoutConstraint!
    @IBOutlet weak var heightViewConstraint: NSLayoutConstraint!
    
    let screenSize = UIScreen.main.bounds.size
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if screenSize.width < screenSize.height {
            widthConstraint.constant = screenSize.width - 70
        }else{
            widthConstraint.constant = screenSize.height - 70
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layoutIfNeeded()
    }
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
    var hasAnimated = false
    var landscape = false
    
    //Helpers: time managment
    var currentDayTime = Date()
    var lastDayTime = Date()
    
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
    
    //Helpers: 3D touch previews
    var indexPathRow = 0
    
    
    //**********************************
    // MARK: Essential functions
    //**********************************
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Core data
        container = NSPersistentContainer(name: "myCoreDataModel")
        container.loadPersistentStores { storeDescription, error in
            self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            if let error = error {
                print("🆘 Unresolved error while configuring core data: \(error)")
            }
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: tableView)
        } else {
            //No 3D touch
        }
        
        //Check app version and perform necessary updates
        versionChech()
        //Load previusly saved data
        loadSavedData(onUpdate: false)
        
        //TableView UI changes
        //tableView.estimatedRowHeight = 370
        //tableView.rowHeight = UITableViewAutomaticDimension
        myRefreshControl.addTarget(self, action: #selector(PostsViewController.dataRefresh), for: .valueChanged)
        tableView.addSubview(myRefreshControl)
        tableView.contentInset = UIEdgeInsetsMake(94, 0, 20, 0)
        
        //Apple bug fix lol
        tableView.setNeedsLayout()
        tableView.layoutIfNeeded()
        
        if (defaults.bool(forKey: "welcomeBlur")) {
            blur.effect = nil
            blurView.layer.opacity = 0
            blur.isHidden = true
        }else{
            blur.effect = UIBlurEffect(style: .regular)
            defaults.set(true, forKey: "welcomeBlur")
        }
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        let color1 = UIColor(red: 222/255, green: 222/255, blue: 222/255, alpha: 1).cgColor
        let color2 = UIColor(red: 222/255, green: 222/255, blue: 222/255, alpha: 0).cgColor
        
        var x: CGFloat = 0
        if UIScreen.main.bounds.size.height > UIScreen.main.bounds.size.width {
            x = UIScreen.main.bounds.size.height
        }else{
            x = UIScreen.main.bounds.size.width
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
        
        self.view.layoutIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if (defaults.bool(forKey: "welcomeScreen")) {
            tableView.layer.opacity = 1
            dataRefresh()
            if !hasAnimated {
                hasAnimated = true
                animateTable()
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
        myRefreshControl.endRefreshing()
    }
    
    override func didReceiveMemoryWarning() {
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
        scrollToTop()
    }
    
    @IBAction func presentSettingsAction(_ sender: Any) {
        tapped()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
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
    
    
    //**********************************
    // MARK: Peek & poop
    //**********************************
    
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if !landscape {
            guard let indexPath = tableView.indexPathForRow(at: location), let cell = tableView.cellForRow(at: indexPath) as? PostCell else { return nil }
            
            if arrayConditions[indexPath.row] == "10" {
                guard let detailViewController = storyboard?.instantiateViewController(withIdentifier: "PhotoPreviewViewController") as? PhotoPreviewViewController else { return nil }
                detailViewController.imageURL = arrayImages[indexPath.row]
                indexPathRow = indexPath.row
                
                let manager = SDWebImageManager.shared()
                manager.loadImage(with: URL(string: arrayImages[indexPath.row]), options: .highPriority, progress: nil, completed: { (image, data, error, cacheType, finished, url) in
                    if let loadedImage = image {
                        let width: CGFloat = 300
                        let height = (width * loadedImage.size.height) / loadedImage.size.width
                        detailViewController.preferredContentSize = CGSize(width: width, height: height)
                    }
                })
                
                previewingContext.sourceRect = tableView.convert(cell.imageShadowView.frame, from: cell.imageShadowView.superview)
                return detailViewController
            }else if arrayLinks[indexPath.row] != "" && arrayDescriptions[indexPath.row] != "" && arrayImages[indexPath.row] != "" {
                guard let detailViewController = storyboard?.instantiateViewController(withIdentifier: "PreviewViewController") as? PreviewViewController else { return nil }
                detailViewController.headline = arrayPosts[indexPath.row]
                detailViewController.desc = arrayDescriptions[indexPath.row]
                detailViewController.imageUrl = arrayImages[indexPath.row]
                detailViewController.condition = arrayConditions[indexPath.row]
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
            if let vc = storyboard?.instantiateViewController(withIdentifier: "PhotoGalleryViewController") as? PhotoGalleryViewController {
                vc.imageURL = arrayImages[indexPathRow]
                vc.modalPresentationStyle = .overFullScreen
                present(vc, animated: true)
            }
        }else if arrayLinks[indexPathRow] != "" {
            if let url = URL(string: arrayLinks[indexPathRow]) {
                let vc = SFSafariViewController(url: url, entersReaderIfAvailable: false)
                vc.preferredControlTintColor = UIColor.black
                vc.modalPresentationStyle = .overFullScreen
                present(vc, animated: true)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.cellForRow(at: indexPath)?.isSelected = false;
            
            if segue.identifier == "showImageSegue" {
                if let photoGalleryViewController = segue.destination as? PhotoGalleryViewController {
                    photoGalleryViewController.imageURL = arrayImages[indexPath.row]
                }
            }else if segue.identifier == "showPostSegue" {
                if let postGalleryViewController = segue.destination as? PostGalleryViewController {
                    postGalleryViewController.post = arrayPosts[indexPath.row]
                }
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "showCategoriesSegue" {
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
                    case "1", "2", "4", "5", "6", "9", "13":
                        return true
                    default:
                        return false
                    }
                }else{
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                    return false
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
        }
        //Data managment
        let post = NSMutableAttributedString()
        let rawPost = arrayPosts[indexPath.row]
        
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
            if arrayPosts[indexPath.row] != "Beeb boop... ℏ ℇ ≺ ℔ ∦ ℵ ℞ ℬ." {
                let attributes = [NSForegroundColorAttributeName: UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1)]
                let touchForMore = NSMutableAttributedString(string: " Touch to view...", attributes: attributes)
                
                post.append(NSMutableAttributedString(string: rawPost))
                post.append(touchForMore)
            }else{
                post.append(NSMutableAttributedString(string: rawPost))
            }
        case "3" :
            if !arrayAnswered.contains(indexPath.row) && arrayPosts[indexPath.row] != "I'll satisfy your inner nerd by sending you interesting facts. ⭐️" {
                let attributes = [NSForegroundColorAttributeName: UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1)]
                let touchForMore = NSMutableAttributedString(string: " Touch to reveal...", attributes: attributes)
                
                post.append(NSMutableAttributedString(string: rawPost))
                post.append(touchForMore)
            }else if arrayAnswered.contains(indexPath.row) && arrayPosts[indexPath.row] != "I'll satisfy your inner nerd by sending you interesting facts. ⭐️" {
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
        default:
            post.append(NSMutableAttributedString(string: rawPost))
        }
        
        if arrayImages[indexPath.row] == "" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "postCellNoImage", for: indexPath) as! PostCell
            
            cell.cardView.layer.shadowColor = UIColor.black.cgColor
            cell.cardView.layer.shadowRadius = 25
            cell.cardView.layer.shadowOpacity = 0.15
            
            cell.myTypeLabel.text = getCondition(arrayConditions[indexPath.row])
            cell.myTextLabel.attributedText = post
            
            cell.layoutIfNeeded()
            
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "postCellWithImage", for: indexPath) as! PostCell
            
            cell.imageShadowView.layer.shadowColor = UIColor.black.cgColor
            cell.imageShadowView.layer.shadowRadius = 25
            cell.imageShadowView.layer.shadowOpacity = 0.15
            cell.postImageView.sd_setImage(with: URL(string: arrayImages[indexPath.row]), placeholderImage: nil, options: [.progressiveDownload, .continueInBackground])
            
            
            cell.cardView.layer.shadowColor = UIColor.black.cgColor
            cell.cardView.layer.shadowRadius = 25
            cell.cardView.layer.shadowOpacity = 0.15
            
            cell.myTypeLabel.text = getCondition(arrayConditions[indexPath.row])
            cell.myTextLabel.attributedText = post
            
            cell.layoutIfNeeded()
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !arrayDefaultPosts.contains(arrayPosts[indexPath.row]) {
            switch arrayConditions[indexPath.row] {
            case "7", "8", "11", "12":
                if let url = URL(string: arrayLinks[indexPath.row]) {
                    let vc = SFSafariViewController(url: url, entersReaderIfAvailable: false)
                    vc.preferredControlTintColor = UIColor.black
                    vc.modalPresentationStyle = .overFullScreen
                    present(vc, animated: true)
                }
            case "3":
                if arrayAnswered.count >= 3 {
                    let row = arrayAnswered[0]
                    arrayAnswered.removeFirst()
                    tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
                }else if !arrayAnswered.contains(indexPath.row) {
                    arrayAnswered.append(indexPath.row)
                    tableView.reloadRows(at: [indexPath], with: .automatic)
                }else{
                    for i in 0..<arrayAnswered.count {
                        if arrayAnswered[i] == indexPath.row {
                            arrayAnswered.remove(at: i)
                            tableView.reloadRows(at: [indexPath], with: .automatic)
                            break;
                        }
                    }
                }
            case "10": break
                //self.performSegue(withIdentifier: "showImageSegue", sender: indexPath)
            case "1", "2", "4", "5", "6", "9", "13": break
                //self.performSegue(withIdentifier: "showPostSegue", sender: indexPath)
            default:
                break
            }
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if arrayImages[indexPath.row] == "" {
            return 200
        }else if arrayPosts[indexPath.row] == "**EARLY**" {
            return 75
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
    
    
    func dataRefresh() {
        //Reload all variables
        reloadData()
        
        //Remove all anwsers
        let tempAnwsers = arrayAnswered
        arrayAnswered.removeAll()
        for i in 0..<tempAnwsers.count {
            tableView.reloadRows(at: [IndexPath(row: tempAnwsers[i], section: 0)], with: .automatic)
        }
        
        requestCount += 1
        print("📳 REQUEST UPDATE #\(requestCount)")
        
        if defaults.bool(forKey: "newCategory") {
            defaults.set(false, forKey: "newCategory")
            loadSavedData(onUpdate: true)
        }else{
            if requestCount > 1 {
                if dailyPostNumber == 0 {
                    //First refresh
                    defaults.set(1, forKey: "dailyPostNumber")
                    print("📳 DAY #\(defaults.integer(forKey: "dayNumber") + 1)")
                    lastDayTime = currentDayTime
                    defaults.set(lastDayTime, forKey: "lastDayTime")
                    
                    loadSavedData(onUpdate: true)
                }
                
                if currentDayTime.compare(lastDayTime) == .orderedDescending {
                    print("📳 DAY #\(defaults.integer(forKey: "dayNumber") + 1)")
                    lastDayTime = currentDayTime
                    defaults.set(lastDayTime, forKey: "lastDayTime")
                    
                    loadSavedData(onUpdate: true)
                    update(newDay: true)
                }else{
                    loadSavedData(onUpdate: true)
                    update(newDay: false)
                }
            }
        }
        
        defaults.set(requestCount, forKey: "requestCount")
    }
    
    func update(newDay: Bool) {
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
            baseURL = "http://services.conradi.si/blink/download.php?num=\(dailyPostNumber)&advice=\(boolDefaultPosts[0])&cats=\(boolDefaultPosts[1])&curiosities=\(boolDefaultPosts[2])&daily=\(boolDefaultPosts[3])&quotes=\(boolDefaultPosts[4])&movies=\(boolDefaultPosts[6])&news=\(boolDefaultPosts[7])&numbers=\(boolDefaultPosts[8])&space=\(boolDefaultPosts[9])&sports=\(boolDefaultPosts[10])&tech=\(boolDefaultPosts[11])&trending=\(boolDefaultPosts[12])&time=\(self.defaults.integer(forKey: "lastTime"))&version=2&token=cb5ffe91b428bed8a251dc098feced975687e0204d44451dc4869498311196fd"
            print("ℹ️ URL: \(baseURL)")
            //DOWNLOAD POSTS FROM SERVER
            performSelector(inBackground: #selector(downloadData), with: nil)
        }else{
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.myRefreshControl.endRefreshing()
            }
        }
    }
    
    func addFridayPost() {
        //ADD NEW POSTS
        var text = ""
        switch getDayOfWeek() {
        case 1:
            //"Sun"
            //let anwsers = ["No. Sadly."]
            //text = anwsers[Int(arc4random_uniform(UInt32(anwsers.count)))]
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
            let anwsers = ["I thought it was yesterday but I was wrong.", "I'm pretty sure it was supposed to be today."]
            text = anwsers[Int(arc4random_uniform(UInt32(anwsers.count)))]
        case 5:
            //"Thu"
            let anwsers = ["Soon.", "Very close."]
            text = anwsers[Int(arc4random_uniform(UInt32(anwsers.count)))]
        case 6:
            //"Fri"
            let anwsers = ["Yep.", "Yes!", "It is indeed.", "Finally.", "This is a day I've been looking forward to for a month."]
            text = anwsers[Int(arc4random_uniform(UInt32(anwsers.count)))]
        case 7:
            //"Sat"
            //let anwsers = ["You've missed it."]
            //text = anwsers[Int(arc4random_uniform(UInt32(anwsers.count)))]
            text = "You just missed it."
        default:
            print("🆘 Error fetching days")
            return
        }
        
        let data = Post(context: self.container.viewContext)
        self.configure(post: data, text: text, description: "", condition: "6", link: "", image: "", time: Int(Date().timeIntervalSince1970))
        self.saveContext()
        self.addPost(text: text, description: "", condition: "6", link: "", image: "", time: Int(Date().timeIntervalSince1970))
        self.tableView.beginUpdates()
        self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
        self.tableView.endUpdates()
        print("✅ Added Friday post.")
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
                                
                                DispatchQueue.main.sync {
                                    if self.olderHeaderIndex > 0 {
                                        //Remove old header
                                        self.arrayPosts.remove(at: self.olderHeaderIndex)
                                        self.arrayDescriptions.remove(at: self.olderHeaderIndex)
                                        self.arrayLinks.remove(at: self.olderHeaderIndex)
                                        self.arrayImages.remove(at: self.olderHeaderIndex)
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
                                                                        
                                                                        if !self.arrayPosts.contains(text) {
                                                                            olderHeaderNewIndex += 1
                                                                            //ADD NEW POSTS
                                                                            let data = Post(context: self.container.viewContext)
                                                                            self.configure(post: data, text: text, description: description, condition: condition, link: url, image: image, time: time)
                                                                            self.saveContext()
                                                                            
                                                                            self.addPost(text: text, description: description, condition: condition, link: url, image: image, time: time)
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
                                        self.arrayTimes.insert(Int(Date().timeIntervalSince1970), at: olderHeaderNewIndex)
                                        self.arrayConditions.insert("", at: olderHeaderNewIndex)
                                        self.tableView.beginUpdates()
                                        self.tableView.insertRows(at: [IndexPath(row: olderHeaderNewIndex, section: 0)], with: .top)
                                        self.tableView.endUpdates()
                                        self.olderHeaderIndex = olderHeaderNewIndex
                                    }
                                }
                            }else{
                                print("⏸ Timeout: \(self.defaults.integer(forKey: "lastTime")) < \(current_time - 3)")
                            }
                        }
                    }else if json?["status"] as? String == "update" {
                        let alert = UIAlertController(title: "Update Blink", message: "New version of Blink is available for download.", preferredStyle: .alert)
                        self.present(alert, animated: true, completion:nil)
                    }
                    print("❎ Download process complete.")
                    
                    DispatchQueue.main.sync {
                        self.myRefreshControl.endRefreshing()
                    }
                } catch {
                    print("🆘 Something went wrong during data download from the server.")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.myRefreshControl.endRefreshing()
                    }
                }
            }
        }
        
        task.resume()
    }
    
    func setUp() {
        //SET UP
        print("📳 Set up")
        version = "1.1"
        defaults.set("1.1", forKey: "version")
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
                             "💻 and ⌨️ and 🖥 and 🎮",
                             "When something weird happens, you'll know. 🔥"]
        
        //Set default values
        boolDefaultPosts = [0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 1]
        defaults.set(arrayDefaultPosts, forKey: "arrayDefaultPosts")
        defaults.set(boolDefaultPosts, forKey: "boolDefaultPosts")
        defaults.set(68, forKey: "dailyPostNumber")
        defaults.set(0, forKey: "fridayPostNumber")
        defaults.set(0, forKey: "dayNumber")
        defaults.set(Int(Date().timeIntervalSince1970) - 5, forKey: "lastTime")
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
            
            if olderHeaderIndex > 0 {
                //Remove old header
                arrayPosts.remove(at: self.olderHeaderIndex)
                arrayDescriptions.remove(at: self.olderHeaderIndex)
                arrayLinks.remove(at: self.olderHeaderIndex)
                arrayImages.remove(at: self.olderHeaderIndex)
                arrayTimes.remove(at: self.olderHeaderIndex)
                arrayConditions.remove(at: self.olderHeaderIndex)
                tableView.beginUpdates()
                tableView.deleteRows(at: [IndexPath(row: self.olderHeaderIndex, section: 0)], with: .top)
                tableView.endUpdates()
                olderHeaderIndex = 0
            }
            
            if !onUpdate {
                //On launch
                for item in result {
                    if !self.arrayPosts.contains(item.post) {
                        self.addPost(text: item.post, description: item.desc, condition: item.condition, link: item.link, image: item.image, time: item.time)
                    }
                }
            }else{
                for item in result {
                    if !self.arrayPosts.contains(item.post) {
                        addPost(text: item.post, description: item.desc, condition: item.condition, link: item.link, image: item.image, time: item.time)
                        tableView.beginUpdates()
                        tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .top)
                        tableView.endUpdates()
                    }
                }
            }
        } catch {
            print("🆘 Unable to fetch managed objects for entity Post.")
        }
    }
    
    func reloadData() {
        arrayDefaultPosts = defaults.object(forKey: "arrayDefaultPosts") as! [String]
        boolDefaultPosts = defaults.object(forKey: "boolDefaultPosts") as! [Int]
        dailyPostNumber = defaults.integer(forKey: "dailyPostNumber")
        fridayPostNumber = defaults.integer(forKey: "fridayPostNumber")
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
        let data0 = Post(context: container.viewContext)
        configure(post: data0, text: "Hi! I'm Blink. Return every day and I'll try to make your day better. 🍹", description: "", condition: "100", link: "", image: "", time: 100)
        saveContext()
        //addPost(text: "Hi! I'm Blink. Return every day and I'll try to make your day better. 🍹", description: "", condition: "100", link: "", image: "", time: 100)
        
        let data1 = Post(context: container.viewContext)
        configure(post: data1, text: arrayDefaultPosts[12], description: "", condition: "13", link: "", image: "", time: 1)
        saveContext()
        //addPost(text: arrayDefaultPosts[12], description: "", condition: "11", link: "", image: "", time: 1)
        
        let data2 = Post(context: container.viewContext)
        configure(post: data2, text: arrayDefaultPosts[7], description: "", condition: "8", link: "", image: "", time: 2)
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
        
        
        //First posts
        let data5 = Post(context: container.viewContext)
        configure(post: data5, text: "\"Life's challenges are not supposed to paralyse you, they're supposed to help you discover who you are.\" — Bernice Reagon", description: "", condition: "5", link: "", image: "", time: Int(Date().timeIntervalSince1970))
        saveContext()
        //addPost(text: "\"Life's challenges are not supposed to paralyse you, they're supposed to help you discover who you are.\" — Bernice Reagon", description: "", condition: "5", link: "", image: "", time: Int(Date().timeIntervalSince1970) + 3)
        
        let data7 = Post(context: container.viewContext)
        configure(post: data7, text: "Silence is golden. Duck tape is silver.", description: "", condition: "4", link: "", image: "", time: Int(Date().timeIntervalSince1970))
        saveContext()
        //addPost(text: "Silence is golden. Duck tape is silver.", description: "", condition: "4", link: "", image: "", time: Int(Date().timeIntervalSince1970) + 3)
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
        let isSharing = true
        let button = sender
        let view = button.superview!
        let cell = view.superview?.superview as! PostCell
        let indexPath: IndexPath = tableView.indexPath(for: cell)!
        
        if arrayLinks[indexPath.row] != "" {
            preparesShare(shareText: "\(arrayPosts[indexPath.row]): \(arrayLinks[indexPath.row])\n\nvia Blink for iPhone: https://appsto.re/si/jxhUib.i", shareImage: nil)
        }else if arrayConditions[indexPath.row] == "10" {
            let manager = SDWebImageManager.shared()
            manager.loadImage(with: URL(string: arrayImages[indexPath.row]), options: .highPriority, progress: nil, completed: { (image, data, error, cacheType, finished, url) in
                if isSharing {
                    if let imageToShare = image {
                        self.preparesShare(shareText: "\(self.arrayPosts[indexPath.row])\n\nvia Blink for iPhone: https://appsto.re/si/jxhUib.i", shareImage: imageToShare)
                    }
                }
            })
        }else{
            preparesShare(shareText: "\(arrayPosts[indexPath.row])\n\nvia Blink for iPhone: https://appsto.re/si/jxhUib.i", shareImage: nil)
        }
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
                boolDefaultPosts = defaults.object(forKey: "boolDefaultPosts") as! [Int]
                boolDefaultPosts.insert(0, at: 5)
                boolDefaultPosts.insert(0, at: 10)
                defaults.set(boolDefaultPosts, forKey: "boolDefaultPosts")
                
                arrayDefaultPosts = defaults.object(forKey: "arrayDefaultPosts") as! [String]
                arrayDefaultPosts.insert("Let me answer this mighty question.", at: 5)
                arrayDefaultPosts.insert("No one ever says, “It’s only a game.” when their team is winning.", at: 10)
                defaults.set(arrayDefaultPosts, forKey: "arrayDefaultPosts")
                
                defaults.set(0, forKey: "fridayPostNumber")
            default:
                break
            }
        }
        
        version = "1.1"
        defaults.set("1.1", forKey: "version")
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
        tableView.setContentOffset(CGPoint(x: 0,y :-94), animated: true)
    }
    
    func getDayOfWeek() -> Int {
        let myCalendar = Calendar(identifier: .gregorian)
        let weekDay = myCalendar.component(.weekday, from: Date())
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
            return "Space photo of the day" //10 (9)
        case "11":
            return "Sports stuff" //11 (10)
        case "12":
            return "Tech talk" //12 (11)
        case "13":
            return "Weird but trending" //13 (12)
        default:
            return "Blink" //Other
        }
    }
}
