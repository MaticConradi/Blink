//
//  PhotoGalleryViewController.swift
//  Blink
//
//  Created by Matic Conradi on 14/04/2017.
//  Copyright © 2017 Conradi.si. All rights reserved.
//

import UIKit

class PhotoGalleryViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var dismissToolbar: UIToolbar!
    
    var imageURL: String?
    var imageText: String?
    var dismissToolbarHidden = false
    var width: CGFloat = 0
    var height: CGFloat = 0
    var animateDuration = 0.0
    
    var interactor: Interactor? = nil
    
    override func viewDidLoad() {
        prepareVars()
        
        scrollView.minimumZoomScale = 1;
        scrollView.maximumZoomScale = 1;
        scrollView.isHidden = true
        activityIndicator.startAnimating()
        if let url = imageURL {
            imageView.sd_setImage(with: URL(string: url), placeholderImage: nil, options: SDWebImageOptions.highPriority, completed: { (image, error, cacheType, imageURL) in
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true
                self.scrollView.isHidden = false
                self.updateConstraintsForSize(size: self.view.bounds.size)
                self.updateMinZoomScaleForSize(size: self.view.bounds.size)
            })
        }
        
        //Toolbar
        let color3 = UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor
        let color4 = UIColor(red: 0, green: 0, blue: 0, alpha: 0.66).cgColor
        
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.colors = [color3, color4]
        gradient.locations = [0.0 , 1.0]
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: width, height: 64)
        dismissToolbar.layer.insertSublayer(gradient, at: 0)
        
        dismissToolbar.setBackgroundImage(UIImage(), forToolbarPosition: UIBarPosition.any, barMetrics: UIBarMetrics.default)
        dismissToolbar.setShadowImage(UIImage(), forToolbarPosition: UIBarPosition.any)
        
        setupGestureRecognizer()
    }
    
    func setupGestureRecognizer() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(PhotoGalleryViewController.handleDoubleTap(recognizer:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(PhotoGalleryViewController.handleTap(recognizer:)))
        tap.numberOfTapsRequired = 1
        scrollView.addGestureRecognizer(tap)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(PhotoGalleryViewController.save(recognizer:)))
        longPressGesture.minimumPressDuration = 1.0 // 1 second press
        longPressGesture.allowableMovement = 15 // 15 points
        scrollView.addGestureRecognizer(longPressGesture)
    }
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        UIView.animate(withDuration: duration / 2) {
            self.scrollView.layer.opacity = 0
            self.animateDuration = duration / 2.0
        }
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        if !scrollView.isHidden {
            self.updateConstraintsForSize(size: self.view.bounds.size)
            self.updateMinZoomScaleForSize(size: self.view.bounds.size)
            UIView.animate(withDuration: animateDuration) {
                self.scrollView.layer.opacity = 1
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
    
    @objc func handleDoubleTap(recognizer: UITapGestureRecognizer) {
        if (scrollView.zoomScale > scrollView.minimumZoomScale) {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }else{
            scrollView.setZoomScale(scrollView.maximumZoomScale, animated: true)
        }
    }
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        if dismissToolbarHidden {
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
                self.dismissToolbar.transform = CGAffineTransform(translationX: 0, y: 0)
            })
        }else{
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
                self.dismissToolbar.transform = CGAffineTransform(translationX: 0, y: 64)
            })
        }
        dismissToolbarHidden = !dismissToolbarHidden
    }
    
    func updateMinZoomScaleForSize(size: CGSize) {
        let widthScale = size.width / imageView.bounds.width
        let heightScale = size.height / imageView.bounds.height
        let minScale = min(widthScale, heightScale)
        scrollView.minimumZoomScale = minScale
        scrollView.zoomScale = minScale
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //updateMinZoomScaleForSize(size: view.bounds.size)
    }
    
    func updateConstraintsForSize(size: CGSize) {
        let yOffset = max(0, (size.height - imageView.frame.height) / 2)
        imageViewTopConstraint.constant = yOffset
        imageViewBottomConstraint.constant = yOffset
        
        let xOffset = max(0, (size.width - imageView.frame.width) / 2)
        imageViewLeadingConstraint.constant = xOffset
        imageViewTrailingConstraint.constant = xOffset
        
        view.layoutIfNeeded()
    }
    
    @objc func save(recognizer: UILongPressGestureRecognizer) {
        //Disable gesture recognizers so
        for recognizer in scrollView.gestureRecognizers! {
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
            let isSharing = true
            
            let manager = SDWebImageManager.shared()
            manager.loadImage(with: URL(string: self.imageURL!), options: .highPriority, progress: nil, completed: { (image, data, error, cacheType, finished, url) in
                if isSharing {
                    if let shareImage = image {
                        var objectsToShare = [Any]()
                        
                        objectsToShare.append("\(self.imageText ?? "")\n\nvia Blink for iPhone: https://appsto.re/si/jxhUib.i")
                        objectsToShare.append(shareImage)
                        
                        let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                        activityViewController.popoverPresentationController?.sourceView = self.view
                        activityViewController.excludedActivityTypes = [UIActivityType.airDrop, UIActivityType.addToReadingList, UIActivityType.postToVimeo, UIActivityType.openInIBooks]
                        if needSrecognizer {
                            activityViewController.popoverPresentationController?.sourceRect = CGRect(x: recognizer!.location(ofTouch: 0, in: nil).x, y: recognizer!.location(ofTouch: 0, in: nil).y, width: 0, height: 0)
                        }else{
                            activityViewController.popoverPresentationController?.barButtonItem = barButton as? UIBarButtonItem
                        }
                        self.present(activityViewController, animated: true, completion: nil)
                    }
                }
            })
        })
        
        let saveAction = UIAlertAction(title: "Save screenshot", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            let isSharing = true
            
            let manager = SDWebImageManager.shared()
            manager.loadImage(with: URL(string: self.imageURL!), options: .highPriority, progress: nil, completed: { (image, data, error, cacheType, finished, url) in
                if isSharing {
                    if let shareImage = image {
                        UIImageWriteToSavedPhotosAlbum(shareImage, nil, nil, nil)
                    }
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
    
    func prepareVars() {
        if UIScreen.main.bounds.size.height > UIScreen.main.bounds.size.width {
            width = UIScreen.main.bounds.size.width
            height = UIScreen.main.bounds.size.height
        }else{
            width = UIScreen.main.bounds.size.height
            height = UIScreen.main.bounds.size.width
        }
    }
}

extension PhotoGalleryViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateConstraintsForSize(size: view.bounds.size)
    }
    
}
