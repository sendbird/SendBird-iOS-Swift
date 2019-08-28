//
//  UIViewController+Utils.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 10/12/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit

extension UIViewController {
    public static func findBestViewController(_ vc: UIViewController) -> UIViewController {
        if let presentedViewController = vc.presentedViewController {
            // Return presented view controller
            return UIViewController.findBestViewController(presentedViewController)
        }
        else if let svc = vc as? UISplitViewController {
            // Return right hand side
            if svc.viewControllers.count > 0 {
                return UIViewController.findBestViewController(svc.viewControllers.last!)
            }
            else {
                return vc
            }
        }
        else if let svc = vc as? UINavigationController {
            // Return top view
            // TODO: Need to compare with ObjC ver.
            if let topViewController = svc.topViewController {
                return UIViewController.findBestViewController(topViewController)
            }
            else {
                return vc
            }
        }
        else if let svc = vc as? UITabBarController {
            // Return visible view
            if (svc.viewControllers?.count ?? 0) > 0 {
                return UIViewController.findBestViewController(svc.selectedViewController!)
            }
            else {
                return vc
            }
        }
        else {
            // Unknown view controller type, return last child view controller
            return vc
        }
    }
    
    public static func currentViewController() -> UIViewController? {
        guard let viewController = UIApplication.shared.keyWindow?.rootViewController else { return nil }
        return UIViewController.findBestViewController(viewController)
    }
}
