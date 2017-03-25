//
//  Subscriptions.swift
//  Blink
//
//  Created by Matic Conradi on 24/03/2017.
//  Copyright © 2017 Conradi.si. All rights reserved.
//

import UIKit

class SubscriptionsViewController: UIViewController {
    @IBOutlet var backgroundView: UIView!
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad(){
        super.viewDidLoad()
        backgroundView.backgroundColor = UIColor.blue
        widthConstraint.constant = UIScreen.main.bounds.size.width
        heightConstraint.constant = UIScreen.main.bounds.size.height
        
        let color1 = UIColor(red: 222/255, green: 1, blue: 201/255, alpha: 1).cgColor
        let color2 = UIColor(red: 163/255, green: 248/255, blue: 1, alpha: 1).cgColor
        
        let gradient: CAGradientLayer = CAGradientLayer()
        
        gradient.colors = [color1, color2]
        gradient.locations = [0 , 0.9]
        gradient.startPoint = CGPoint(x: 0.0, y:0.0)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        backgroundView.layer.insertSublayer(gradient, at: 0)
    }
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        UIView.animate(withDuration: duration) { 
            
        }
    }
}
