//
//  SettingsCell.swift
//  Blink
//
//  Created by Matic Conradi on 17/08/2016.
//  Copyright © 2016 Conradi.si. All rights reserved.
//

import UIKit

class SettingsCell: UITableViewCell {
    
    @IBOutlet var myTitle: UILabel!
    
    var settings_title = String() {
        didSet {
            updateTitle()
        }
    }
    
    func updateTitle() {
        myTitle.text = settings_title
    }
}
