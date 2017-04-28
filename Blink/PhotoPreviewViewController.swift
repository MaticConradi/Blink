//
//  PhotoPreviewViewController.swift
//  Blink
//
//  Created by Matic Conradi on 15/04/2017.
//  Copyright © 2017 Conradi.si. All rights reserved.
//

import UIKit

class PhotoPreviewViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    
    var imageURL: String?
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let url = imageURL {
            imageView.sd_setImage(with: URL(string: url), placeholderImage: nil, options: SDWebImageOptions.highPriority)
        }
    }
    
    override var previewActionItems: [UIPreviewActionItem] {
        let saveAction = UIPreviewAction(title: "Save", style: .default) { (action, viewController) -> Void in
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
        
        return [saveAction]
    }
}
