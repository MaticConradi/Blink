//
//  NavigationControllerDelegate.swift
//  Blink
//
//  Created by Matic Conradi on 16/08/2016.
//  Copyright © 2016 Conradi.si. All rights reserved.
//

import UIKit

class NavigationControllerDelegate: NSObject, UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationControllerOperation,
                                                              from fromVC: UIViewController,
                                                                                 to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransitionAnimator()
    }
}
