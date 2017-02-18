//
//  SettingsPageViewController.swift
//  Blink
//
//  Created by Matic Conradi on 09/02/2017.
//  Copyright © 2017 Conradi.si. All rights reserved.
//

import UIKit

class SettingsPageViewController: UIPageViewController, UIPageViewControllerDataSource {
    @IBOutlet weak var button: UIButton!
    
    private(set) lazy var orderedViewControllers: [UIViewController] = {
        return [self.newViewController(name: "SubscriptionsTableViewController"),
                self.newViewController(name: "AboutTableViewController")]
    }()
    
    private func newViewController(name: String) -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewController(withIdentifier: "\(name)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        let backButton = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.plain, target: navigationController, action: nil)
        navigationItem.leftBarButtonItem = backButton
        
        dataSource = self
        
        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController],
                               direction: .forward,
                               animated: true,
                               completion: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIView.transition(with: self.view,
                          duration: 0.3,
                          options: UIViewAnimationOptions.transitionCrossDissolve,
                          animations:{
                            UIApplication.shared.statusBarStyle = .lightContent
                            self.navigationController?.navigationBar.barTintColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
                            if let font = UIFont(name: "CenturyCity", size: 20) {
                                self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: font, NSForegroundColorAttributeName: UIColor.white]
                            }
        },
                          completion:{
                            (finished: Bool) -> () in
        })
    }
    
    @IBAction func iconTapped(_ sender:UIButton) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIView.transition(with: self.view,
                          duration: 0.3,
                          options: UIViewAnimationOptions.transitionCrossDissolve,
                          animations:{
                            UIApplication.shared.statusBarStyle = .default
                            self.navigationController?.navigationBar.barTintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1.0)
                            if let font = UIFont(name: "CenturyCity", size: 20) {
                                self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: font, NSForegroundColorAttributeName: UIColor.black]
                            }
        },
                          completion:{
                            (finished: Bool) -> () in
        })
    }
    
    func tapped() {
        //Generate haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else { return nil }
        let previousIndex = viewControllerIndex - 1
        guard previousIndex >= 0 else { return nil }
        guard orderedViewControllers.count > previousIndex else { return nil }
        
        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else { return nil }
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = orderedViewControllers.count
        guard orderedViewControllersCount != nextIndex else { return nil }
        guard orderedViewControllersCount > nextIndex else { return nil }
        
        return orderedViewControllers[nextIndex]
    }
}
