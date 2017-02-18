//
//  NavigationController.swift
//  Blink
//
//  Created by Matic Conradi on 08/08/2016.
//  Copyright © 2016 Conradi.si. All rights reserved.
//

import UIKit

class PostNavigationController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let backButton = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.plain, target: navigationController, action: nil)
        navigationItem.leftBarButtonItem = backButton
        if let font = UIFont(name: "CenturyCity", size: 20) {
            self.navigationBar.titleTextAttributes = [NSFontAttributeName: font]
        }
    }
}
