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
    
    override func viewDidLoad() {
        dismissToolbar.layer.borderWidth = 0.5
        dismissToolbar.layer.borderColor = UIColor.clear.cgColor
        dismissToolbar.clipsToBounds = true
        
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
        setupGestureRecognizer()
    }
    
    func setupGestureRecognizer() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(PhotoGalleryViewController.handleDoubleTap(recognizer:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(PhotoGalleryViewController.close))
        swipeUp.direction = .up
        scrollView.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(PhotoGalleryViewController.close))
        swipeDown.direction = .down
        scrollView.addGestureRecognizer(swipeDown)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(PhotoGalleryViewController.save))
        longPressGesture.minimumPressDuration = 1.0 // 1 second press
        longPressGesture.allowableMovement = 15 // 15 points
        scrollView.addGestureRecognizer(longPressGesture)
    }
    
    func handleDoubleTap(recognizer: UITapGestureRecognizer) {
        if (scrollView.zoomScale > scrollView.minimumZoomScale) {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }else{
            scrollView.setZoomScale(scrollView.maximumZoomScale, animated: true)
        }
    }
    
    func updateMinZoomScaleForSize(size: CGSize) {
        let widthScale = size.width / imageView.bounds.width
        let heightScale = (size.height - 64) / imageView.bounds.height
        let minScale = min(widthScale, heightScale)
        scrollView.minimumZoomScale = minScale
        scrollView.zoomScale = minScale
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //updateMinZoomScaleForSize(size: view.bounds.size)
    }
    
    func updateConstraintsForSize(size: CGSize) {
        let yOffset = max(0, (size.height - 64 - imageView.frame.height) / 2)
        imageViewTopConstraint.constant = yOffset
        imageViewBottomConstraint.constant = yOffset
        
        let xOffset = max(0, (size.width - imageView.frame.width) / 2)
        imageViewLeadingConstraint.constant = xOffset
        imageViewTrailingConstraint.constant = xOffset
        
        view.layoutIfNeeded()
    }
    
    func close() {
        if scrollView.zoomScale == scrollView.minimumZoomScale {
            dismiss(animated: true, completion: nil)
        }
    }
    
    func save() {
        //Disable gesture recognizers so
        for recognizer in scrollView.gestureRecognizers! {
            recognizer.isEnabled = false
            recognizer.isEnabled = true
        }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let firstAction = UIAlertAction(title: "Save", style: .default) { (alert: UIAlertAction!) -> Void in
            let isSharing = true
            let manager = SDWebImageManager.shared()
            manager.loadImage(with: URL(string: self.imageURL!), options: .highPriority, progress: nil, completed: { (image, data, error, cacheType, finished, url) in
                if isSharing {
                    if let imageToShare = image {
                        UIImageWriteToSavedPhotosAlbum(imageToShare, nil, nil, nil)
                    }
                }
            })
            
        }
        
        let secondAction = UIAlertAction(title: "Cancel", style: .cancel) { (alert: UIAlertAction!) -> Void in
            //Cancel
        }
        
        alert.addAction(firstAction)
        alert.addAction(secondAction)
        present(alert, animated: true, completion:nil)
    }
    
    @IBAction func dismiss(_ sender: Any) {
        dismiss(animated: true, completion: nil)
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
