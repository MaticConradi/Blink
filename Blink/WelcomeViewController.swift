//
//  WelcomeViewController.swift
//  Blink
//
//  Created by Matic Conradi on 02/04/2017.
//  Copyright © 2017 Conradi.si. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController {
    @IBOutlet weak var dismissButton: UIView!
    @IBOutlet weak var cardView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        let color1 = UIColor(red: 222/255, green: 1, blue: 201/255, alpha: 1).cgColor
        let color2 = UIColor(red: 163/255, green: 248/255, blue: 1, alpha: 1).cgColor
        
        let gradient: CAGradientLayer = CAGradientLayer()
        
        gradient.colors = [color1, color2]
        gradient.locations = [0 , 0.9]
        gradient.startPoint = CGPoint(x: 0.0, y: 1.0)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradient.frame = CGRect(x: 0, y: 0, width: dismissButton.frame.size.width, height: dismissButton.frame.size.height)
        
        dismissButton.layer.insertSublayer(gradient, at: 0)
        dismissButton.layer.shadowColor = color1
        dismissButton.layer.shadowRadius = 9
        dismissButton.layer.shadowOpacity = 0.4
        dismissButton.layer.shadowOffset = CGSize(width: 0, height: 10)
        
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowRadius = 25
        cardView.layer.shadowOpacity = 0.15
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func dismissAction(_ sender: Any) {
        dismiss(animated: true) {}
    }
}
