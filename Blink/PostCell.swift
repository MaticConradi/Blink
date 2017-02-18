//
//  PostCell.swift
//  Blink
//
//  Created by Matic Conradi on 15/08/2016.
//  Copyright © 2016 Conradi.si. All rights reserved.
//

import UIKit

class PostCell: UITableViewCell {
    
    @IBOutlet var myTextLabel: UILabel!
    @IBOutlet var myTypeLabel: UILabel!
    @IBOutlet var seperator: UIImageView!
    @IBOutlet weak var cardView: UIView!
    
    var post_text = String() {
        didSet {
            updateText()
        }
    }
    
    var post_type = String() {
        didSet {
            updateType()
        }
    }
    
    func updateText() {
        myTextLabel.text = post_text
    }
    
    func updateType() {
        myTypeLabel.text = post_type
    }
}
