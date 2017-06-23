//
//  PostGalleryViewController.swift
//  Blink
//
//  Created by Matic Conradi on 15/04/2017.
//  Copyright © 2017 Conradi.si. All rights reserved.
//

import UIKit

class PostGalleryViewController: UIViewController {
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet var landscapeBackgroundView: UIView!
    @IBOutlet var portraitBackgroundView: UIView!
    @IBOutlet weak var landscapeHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var landscapeWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var portraitHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var portraitWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var dismissToolbar: UIToolbar!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var gestureRecognizerView: UIView!
    
    var colors = [[UIColor]]()
    var dismissToolbarHidden = false
    var width: CGFloat = 0
    var height: CGFloat = 0
    var post: String?
    
    var interactor: Interactor? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textLabel.text = post
        
        prepareVars()
        prepareViews()
        setupGestureRecognizer()
    }
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        if toInterfaceOrientation.isLandscape {
            landscapeBackgroundView.layer.opacity = 1
            UIView.animate(withDuration: duration, animations: {
                self.portraitBackgroundView.layer.opacity = 0
            })
        }else{
            UIView.animate(withDuration: duration, animations: {
                self.portraitBackgroundView.layer.opacity = 1
            })
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration) {
                self.landscapeBackgroundView.layer.opacity = 0
            }
        }
    }
    
    @IBAction func handleGesture(_ sender: UIPanGestureRecognizer) {
        let percentThreshold:CGFloat = 0.3
        
        // convert y-position to downward pull progress (percentage)
        let translation = sender.translation(in: view)
        let verticalMovement = translation.y / view.bounds.height
        let downwardMovement = fmaxf(Float(verticalMovement), 0.0)
        let downwardMovementPercent = fminf(downwardMovement, 1.0)
        let progress = CGFloat(downwardMovementPercent)
        
        guard let interactor = interactor else { return }
        
        switch sender.state {
        case .began:
            interactor.hasStarted = true
            dismiss(animated: true, completion: nil)
        case .changed:
            interactor.shouldFinish = progress > percentThreshold
            interactor.update(progress)
        case .cancelled:
            interactor.hasStarted = false
            interactor.cancel()
        case .ended:
            interactor.hasStarted = false
            interactor.shouldFinish
                ? interactor.finish()
                : interactor.cancel()
        default:
            break
        }
    }
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        if dismissToolbarHidden {
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
                self.dismissToolbar.transform = CGAffineTransform(translationX: 0, y: 0)
                self.imageView.transform = CGAffineTransform(translationX: 0, y: -64)
                self.imageView.layer.opacity = 0.33
            })
        }else{
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
                self.dismissToolbar.transform = CGAffineTransform(translationX: 0, y: 64)
                self.imageView.transform = CGAffineTransform(translationX: 0, y: 0)
                self.imageView.layer.opacity = 1
            })
        }
        dismissToolbarHidden = !dismissToolbarHidden
    }
    
    @objc func save(recognizer: UILongPressGestureRecognizer) {
        //Disable gesture recognizers so
        for recognizer in view.gestureRecognizers! {
            recognizer.isEnabled = false
            recognizer.isEnabled = true
        }
        
        share(needSrecognizer: true, recognizer: recognizer, barButton: nil)
    }
    
    @IBAction func shareAction(_ sender: Any) {
        share(needSrecognizer: false, recognizer: nil, barButton: sender)
    }
    
    func share(needSrecognizer: Bool, recognizer: UILongPressGestureRecognizer?, barButton: Any?) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let shareAction = UIAlertAction(title: "Share", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            
            var objectsToShare = [Any]()
            objectsToShare.append("\(self.post ?? "")\n\nvia Blink for iPhone: https://appsto.re/si/jxhUib.i")
            
            let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityViewController.excludedActivityTypes = [UIActivityType.airDrop, UIActivityType.addToReadingList, UIActivityType.postToVimeo, UIActivityType.openInIBooks]
            if needSrecognizer {
                activityViewController.popoverPresentationController?.sourceRect = CGRect(x: recognizer!.location(ofTouch: 0, in: nil).x, y: recognizer!.location(ofTouch: 0, in: nil).y, width: 0, height: 0)
                activityViewController.popoverPresentationController?.sourceView = self.view
            }else{
                activityViewController.popoverPresentationController?.barButtonItem = barButton as? UIBarButtonItem
            }
            self.present(activityViewController, animated: true, completion: nil)
        })
        
        let saveAction = UIAlertAction(title: "Save screenshot", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.dismissToolbarHidden = true
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
                self.dismissToolbar.transform = CGAffineTransform(translationX: 0, y: 64)
                self.imageView.transform = CGAffineTransform(translationX: 0, y: 0)
                self.imageView.layer.opacity = 1
            }, completion: { (true) in
                UIGraphicsBeginImageContext(self.view.frame.size)
                self.view.layer.render(in: UIGraphicsGetCurrentContext()!)
                let image = UIGraphicsGetImageFromCurrentImageContext()
                if let shareImage = image {
                    UIImageWriteToSavedPhotosAlbum(shareImage, nil, nil, nil)
                }
            })
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
        })
        actionSheet.addAction(shareAction)
        actionSheet.addAction(saveAction)
        actionSheet.addAction(cancelAction)
        if needSrecognizer {
            actionSheet.popoverPresentationController?.sourceRect = CGRect(x: recognizer!.location(ofTouch: 0, in: nil).x, y: recognizer!.location(ofTouch: 0, in: nil).y, width: 0, height: 0)
        }else{
            actionSheet.popoverPresentationController?.barButtonItem = barButton as? UIBarButtonItem
        }
        present(actionSheet, animated: true, completion: nil)
    }

    @IBAction func dismiss(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func prepareVars() {
        if UIScreen.main.bounds.size.height > UIScreen.main.bounds.size.width {
            landscapeBackgroundView.layer.opacity = 0
            width = UIScreen.main.bounds.size.width
            height = UIScreen.main.bounds.size.height
        }else{
            portraitBackgroundView.layer.opacity = 0
            width = UIScreen.main.bounds.size.height
            height = UIScreen.main.bounds.size.width
        }
        
        colors = [
            [UIColor(red: 54/255, green: 209/255, blue: 220/255, alpha: 1.0), UIColor(red: 91/255, green: 134/255, blue: 229/255, alpha: 1.0)], //0
            [UIColor(red: 203/255, green: 53/255, blue: 107/255, alpha: 1.0), UIColor(red: 189/255, green: 63/255, blue: 50/255, alpha: 1.0)], //1
            [UIColor(red: 192/255, green: 57/255, blue: 43/255, alpha: 1.0), UIColor(red: 142/255, green: 68/255, blue: 173/255, alpha: 1.0)], //2
            [UIColor(red: 0/255, green: 121/255, blue: 145/255, alpha: 1.0), UIColor(red: 120/255, green: 255/255, blue: 214/255, alpha: 1.0)], //3
            [UIColor(red: 86/255, green: 204/255, blue: 242/255, alpha: 1.0), UIColor(red: 47/255, green: 128/255, blue: 237/255, alpha: 1.0)], //4
            [UIColor(red: 242/255, green: 153/255, blue: 74/255, alpha: 1.0), UIColor(red: 242/255, green: 201/255, blue: 76/255, alpha: 1.0)], //5
            [UIColor(red: 48/255, green: 232/255, blue: 191/255, alpha: 1.0), UIColor(red: 255/255, green: 130/255, blue: 53/255, alpha: 1.0)], //6
            [UIColor(red: 195/255, green: 55/255, blue: 100/255, alpha: 1.0), UIColor(red: 29/255, green: 38/255, blue: 113/255, alpha: 1.0)], //7
            [UIColor(red: 69/255, green: 104/255, blue: 220/255, alpha: 1.0), UIColor(red: 176/255, green: 106/255, blue: 179/255, alpha: 1.0)], //8
            [UIColor(red: 67/255, green: 198/255, blue: 172/255, alpha: 1.0), UIColor(red: 248/255, green: 255/255, blue: 174/255, alpha: 1.0)], //9
            [UIColor(red: 220/255, green: 227/255, blue: 91/255, alpha: 1.0), UIColor(red: 69/255, green: 182/255, blue: 73/255, alpha: 1.0)], //10
            [UIColor(red: 52/255, green: 148/255, blue: 230/255, alpha: 1.0), UIColor(red: 236/255, green: 110/255, blue: 173/255, alpha: 1.0)], //11
            [UIColor(red: 103/255, green: 178/255, blue: 111/255, alpha: 1.0), UIColor(red: 76/255, green: 162/255, blue: 205/255, alpha: 1.0)], //12
            [UIColor(red: 238/255, green: 9/255, blue: 121/255, alpha: 1.0), UIColor(red: 255/255, green: 106/255, blue: 0/255, alpha: 1.0)], //13
            [UIColor(red: 0/255, green: 195/255, blue: 255/255, alpha: 1.0), UIColor(red: 255/255, green: 255/255, blue: 28/255, alpha: 1.0)], //14
            [UIColor(red: 255/255, green: 126/255, blue: 95/255, alpha: 1.0), UIColor(red: 255/255, green: 126/255, blue: 95/255, alpha: 1.0)], //15
            [UIColor(red: 222/255, green: 97/255, blue: 97/255, alpha: 1.0), UIColor(red: 38/255, green: 87/255, blue: 235/255, alpha: 1.0)], //16
            [UIColor(red: 190/255, green: 147/255, blue: 197/255, alpha: 1.0), UIColor(red: 123/255, green: 198/255, blue: 204/255, alpha: 1.0)], //17
            [UIColor(red: 247/255, green: 157/255, blue: 0/255, alpha: 1.0), UIColor(red: 100/255, green: 243/255, blue: 140/255, alpha: 1.0)], //18
            [UIColor(red: 203/255, green: 45/255, blue: 62/255, alpha: 1.0), UIColor(red: 239/255, green: 71/255, blue: 58/255, alpha: 1.0)], //19
        ]
    }
    
    func prepareViews() {
        //Background
        landscapeHeightConstraint.constant = width
        landscapeWidthConstraint.constant = height
        portraitHeightConstraint.constant = height
        portraitWidthConstraint.constant = width
        
        let elementIndex = Int(arc4random_uniform(UInt32(colors.count)))
        let color1 = colors[elementIndex][0].cgColor
        let color2 = colors[elementIndex][1].cgColor
        
        let portraitGradient = CAGradientLayer()
        let landscapeGradient = CAGradientLayer()
        
        portraitGradient.colors = [color1, color2]
        portraitGradient.locations = [0, 1]
        portraitGradient.frame = CGRect(x: 0.0, y: 0.0, width: width, height: height)
        
        landscapeGradient.colors = [color1, color2]
        landscapeGradient.locations = [0, 1]
        landscapeGradient.frame = CGRect(x: 0.0, y: 0.0, width: height, height: width)
        
        portraitBackgroundView.layer.insertSublayer(portraitGradient, at: 0)
        landscapeBackgroundView.layer.insertSublayer(landscapeGradient, at: 0)
        
        //Toolbar
        let color3 = UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor
        let color4 = UIColor(red: 0, green: 0, blue: 0, alpha: 0.33).cgColor
        
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.colors = [color3, color4]
        gradient.locations = [0.0 , 1.0]
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: height, height: 64)
        dismissToolbar.layer.insertSublayer(gradient, at: 0)
        
        dismissToolbar.setBackgroundImage(UIImage(), forToolbarPosition: UIBarPosition.any, barMetrics: UIBarMetrics.default)
        dismissToolbar.setShadowImage(UIImage(), forToolbarPosition: UIBarPosition.any)
        
        //Blink image view
        imageView.transform = CGAffineTransform(translationX: 0, y: -64)
        imageView.layer.opacity = 0.33
    }
    
    func setupGestureRecognizer() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(PostGalleryViewController.handleTap(recognizer:)))
        tap.numberOfTapsRequired = 1
        gestureRecognizerView.addGestureRecognizer(tap)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(PostGalleryViewController.save(recognizer:)))
        longPressGesture.minimumPressDuration = 1.0 // 1 second press
        longPressGesture.allowableMovement = 15 // 15 points
        gestureRecognizerView.addGestureRecognizer(longPressGesture)
    }
}
