//
//  PreviewViewController.swift
//  Blink
//
//  Created by Matic Conradi on 07/02/2017.
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.sd_setImage(with: URL(string: imageUrl!))
        
        switch condition! {
        case "6":
            headline = "Review: " + headline!
        case "7":
            headline = "Headline: " + headline!
        default:
            break;
        }
        
        if headline!.characters.last != "?" && headline!.characters.last != "!" && headline!.characters.last != "." {
            headline! += "."
        }
        
        if desc!.characters.last != "?" && desc!.characters.last != "!" && desc!.characters.last != "." {
            desc! += "."
        }
        
        titleView.text = headline!
        descriptionView.text = desc!
        
        previewTableView.estimatedRowHeight = 250
        previewTableView.rowHeight = UITableViewAutomaticDimension
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 250
        }
        return UITableViewAutomaticDimension
    }
}
