//
//  PreviewViewController.swift
//  Blink
//
//  Created by Matic Conradi on 14/04/2017.
//  Copyright © 2017 Conradi.si. All rights reserved.
//

import UIKit

class PreviewViewController: UITableViewController {
    var headline: String?
    var imageUrl: String?
    var desc: String?
    var condition: String?
    var imageSize: [Double]?
    
    @IBOutlet var previewTableView: UITableView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleView: UILabel!
    @IBOutlet weak var descriptionView: UILabel!
    @IBOutlet weak var titleCardView: UIView!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var footerCardView: UIView!
    @IBOutlet weak var alternativeImage: UIImageView!
    @IBOutlet weak var alternativeImageHeight: NSLayoutConstraint!
    @IBOutlet weak var alternativeImageWidth: NSLayoutConstraint!
    @IBOutlet weak var alternativeImageBlur: UIVisualEffectView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.sd_setImage(with: URL(string: imageUrl!), placeholderImage: nil, options: [.progressiveDownload])
        
        if imageSize?.count == 2 {
            if imageSize?[0] != 0 || imageSize?[1] != 0 {
                if CGFloat(imageSize![0]) < imageView.frame.size.width {
                    alternativeImageBlur.isHidden = false
                    alternativeImage.sd_setImage(with: URL(string: imageUrl!), placeholderImage: nil, options: [.progressiveDownload, .continueInBackground])
                    alternativeImageWidth.constant = CGFloat(imageSize![0])
                    alternativeImageHeight.constant = CGFloat(imageSize![1])
                }
            }
        }
        titleView.text = headline!
        descriptionView.text = desc!
        previewTableView.estimatedRowHeight = 250
        previewTableView.rowHeight = UITableViewAutomaticDimension
        titleCardView.layer.shadowColor = UIColor.black.cgColor
        titleCardView.layer.shadowRadius = 25
        titleCardView.layer.shadowOpacity = 0.25
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowRadius = 25
        cardView.layer.shadowOpacity = 0.25
        footerCardView.layer.shadowColor = UIColor.black.cgColor
        footerCardView.layer.shadowRadius = 25
        footerCardView.layer.shadowOpacity = 0.25
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            if imageSize?.count == 2 {
                if imageSize?[0] != 0 || imageSize?[1] != 0 {
                    if CGFloat(imageSize![0]) >= imageView.frame.size.width {
                        return imageView.frame.size.width * CGFloat(imageSize![1]) / CGFloat(imageSize![0])
                    }else{
                        return CGFloat(imageSize![1]) + (imageView.frame.size.width - CGFloat(imageSize![0])) / 2
                    }
                }
            }
            return 250
        }else if indexPath.row == 3 {
            return 300
        }
        return UITableViewAutomaticDimension
    }
}

