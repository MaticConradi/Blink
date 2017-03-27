//
//  Subscriptions.swift
//  Blink
//
//  Created by Matic Conradi on 24/03/2017.
//  Copyright © 2017 Conradi.si. All rights reserved.
//

import UIKit

class SubscriptionsViewController: UIViewController {
    @IBOutlet var landscapeBackgroundView: UIView!
    @IBOutlet var portraitBackgroundView: UIView!
    @IBOutlet weak var landscapeHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var landscapeWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var portraitHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var portraitWidthConstraint: NSLayoutConstraint!
    
    override func viewDidLoad(){
        super.viewDidLoad()
        var w: CGFloat = 0
        var h: CGFloat = 0
        if UIScreen.main.bounds.size.height > UIScreen.main.bounds.size.width {
            landscapeBackgroundView.layer.opacity = 0
            w = UIScreen.main.bounds.size.width
            h = UIScreen.main.bounds.size.height
        }else{
            portraitBackgroundView.layer.opacity = 0
            w = UIScreen.main.bounds.size.height
            h = UIScreen.main.bounds.size.width
        }
        
        landscapeHeightConstraint.constant = w
        landscapeWidthConstraint.constant = h
        portraitHeightConstraint.constant = h
        portraitWidthConstraint.constant = w
        
        let color1 = UIColor(red: 222/255, green: 1, blue: 201/255, alpha: 1).cgColor
        let color2 = UIColor(red: 163/255, green: 248/255, blue: 1, alpha: 1).cgColor
        
        let portraitGradient: CAGradientLayer = CAGradientLayer()
        let landscapeGradient: CAGradientLayer = CAGradientLayer()
        
        portraitGradient.colors = [color1, color2]
        portraitGradient.locations = [0 , 0.9]
        portraitGradient.startPoint = CGPoint(x: 0.0, y:0.0)
        portraitGradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        portraitGradient.frame = CGRect(x: 0.0, y: 0.0, width: w, height: h)
        
        landscapeGradient.colors = [color1, color2]
        landscapeGradient.locations = [0 , 0.9]
        landscapeGradient.startPoint = CGPoint(x: 0.0, y:0.0)
        landscapeGradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        landscapeGradient.frame = CGRect(x: 0.0, y: 0.0, width: h, height: w)
        
        portraitBackgroundView.layer.insertSublayer(portraitGradient, at: 0)
        landscapeBackgroundView.layer.insertSublayer(landscapeGradient, at: 0)
    }
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        if toInterfaceOrientation.isLandscape {
            landscapeBackgroundView.layer.opacity = 1
            UIView.animate(withDuration: duration, animations: {
                self.portraitBackgroundView.layer.opacity = 0
            })
        }else{
            UIView.animate(withDuration: duration, animations: {
                self.portraitBackgroundView.layer.opacity = 1
            })
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration) {
                self.landscapeBackgroundView.layer.opacity = 0
            }
        }
    }
}
