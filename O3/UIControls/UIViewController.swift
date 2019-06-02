//
//  UIViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 9/26/17.
//  Copyright © 2017 drei. All rights reserved.
//

import UIKit
import SwiftTheme

extension UIViewController {
    func presentFromEmbedded(_ toPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        if let navigationController = self as? UINavigationController {
            navigationController.topViewController?.presentFromEmbedded(toPresent, animated: flag, completion: completion)
        } else if let tabBarController = self as? UITabBarController {
            tabBarController.selectedViewController?.presentFromEmbedded(toPresent, animated: flag, completion: completion)
        } else if let presentedViewController = presentedViewController {
            presentedViewController.presentFromEmbedded(toPresent, animated: flag, completion: completion)
        } else {
            DispatchQueue.main.async { self.present(toPresent, animated: flag, completion: completion) }
        }
    }

    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    func applyNavBarTheme() {
        self.navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
        UIApplication.shared.theme_setStatusBarStyle(ThemeStatusBarStylePicker(styles: Theme.light.statusBarStyle, Theme.dark.statusBarStyle), animated: true)
        self.setNeedsStatusBarAppearanceUpdate()
        self.navigationController?.navigationItem.largeTitleDisplayMode = .never
    }
    
    @objc func dismissTapped() {
        dismiss(animated: true)
    }
    
    func applyBottomSheetNavBarTheme(title: String) {
        DispatchQueue.main.async {
            UIApplication.shared.theme_setStatusBarStyle(ThemeStatusBarStylePicker(styles: Theme.light.statusBarStyle, Theme.dark.statusBarStyle), animated: true)
            self.setNeedsStatusBarAppearanceUpdate()
            self.navigationController?.navigationItem.largeTitleDisplayMode = .automatic
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "close-x"), style: .plain, target: self, action: #selector(self.dismissTapped))
            self.navigationItem.rightBarButtonItem?.theme_tintColor = O3Theme.lightTextColorPicker
            
            let label = UILabel()
            label.theme_textColor = O3Theme.titleColorPicker
            label.text = title
            label.font = UIFont(name: "Avenir-Heavy", size: 16)
            self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: label)
        }
    }
}
