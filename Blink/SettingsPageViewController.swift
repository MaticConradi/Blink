//
//  SettingsPageViewController.swift
//  Blink
//
//  Created by Matic Conradi on 09/02/2017.
//  Copyright © 2017 Conradi.si. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    @IBOutlet weak var dismissToolbar: UIToolbar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dismissToolbar.layer.borderWidth = 0.5
        dismissToolbar.layer.borderColor = UIColor.clear.cgColor
        dismissToolbar.clipsToBounds = true
    }
    
    @IBAction func dismiss(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

class SettingsPageViewController: UIPageViewController, UIPageViewControllerDataSource {
    private(set) lazy var orderedViewControllers: [UIViewController] = {
        return [self.newViewController(name: "SubscriptionsViewController"),
                self.newViewController(name: "AboutTableViewController")]
    }()
    
    private func newViewController(name: String) -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewController(withIdentifier: "\(name)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        
        dataSource = self
        
        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController],
                               direction: .forward,
                               animated: true,
                               completion: nil)
        }
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
