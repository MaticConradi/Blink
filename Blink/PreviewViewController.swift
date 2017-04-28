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
    
    @IBOutlet var previewTableView: UITableView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleView: UILabel!
    @IBOutlet weak var descriptionView: UILabel!
    @IBOutlet weak var titleCardView: UIView!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var footerCardView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.sd_setImage(with: URL(string: imageUrl!))
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
            return 250
        }else if indexPath.row == 3 {
            return 300
        }
        return UITableViewAutomaticDimension
    }
}

