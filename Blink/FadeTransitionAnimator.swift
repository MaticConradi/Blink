//
//  FadeTransitionAnimator.swift
//  Blink
//
//  Created by Matic Conradi on 16/08/2016.
//  Copyright © 2016 Conradi.si. All rights reserved.
//

import UIKit

class FadeTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    weak var transitionContext: UIViewControllerContextTransitioning?
    let maskLayer = CAShapeLayer()
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3;
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        _ = transitionContext.viewController(
            forKey: UITransitionContextViewControllerKey.from)
        let toVC = transitionContext.viewController(
            forKey: UITransitionContextViewControllerKey.to)
        
        containerView.addSubview(toVC!.view)
        toVC!.view.alpha = 0.0
        
        let duration = transitionDuration(using: transitionContext)
        UIView.animate(withDuration: duration, animations: {
            toVC!.view.alpha = 1.0
            }, completion: { finished in
                let cancelled = transitionContext.transitionWasCancelled
                transitionContext.completeTransition(!cancelled)
        })
    }
    
    func animationEnded(_ transitionCompleted: Bool) {
        self.transitionContext?.completeTransition(!self.transitionContext!.transitionWasCancelled)
        self.transitionContext?.viewController(forKey: UITransitionContextViewControllerKey.from)?.view.layer.mask = nil
        self.maskLayer.removeFromSuperlayer()
    }
    
}

class ReplaceTopSegue: UIStoryboardSegue {
    override func perform() {
        let fromVC = source
        let toVC = destination
        
        var vcs = fromVC.navigationController?.viewControllers
        
        vcs?.removeLast()
        vcs?.append(toVC)
        
        fromVC.navigationController?.setViewControllers(vcs!,
                                                        animated: true)
    }
}
