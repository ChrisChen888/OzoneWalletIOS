//
//  HalfModalPresentationController.swift
//  HalfModalPresentationController
//
//  Created by Martin Normark on 17/01/16.
//  Copyright © 2016 martinnormark. All rights reserved.
//

import UIKit

class HalfModalPresentationController: UIPresentationController {
    var isMaximized: Bool = false

    var dimmingViewOptional: UIView?
    var dimmingView: UIView {
        if let dimmedView = dimmingViewOptional {
            return dimmedView
        }
        let view = UIView(frame: CGRect(x: 0, y: 0, width: containerView!.bounds.width, height: containerView!.bounds.height))
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        dimmingViewOptional = view
        return view
    }

    func adjustToFullScreen(allowReverse: Bool = true) {
        if let presentedView = presentedView, let containerView = self.containerView {
            UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: { () -> Void in
                if self.isMaximized {
                    if allowReverse {
                        presentedView.frame = self.frameOfPresentedViewInContainerView
                    } else {
                        return
                    }
                } else {
                    presentedView.frame = containerView.frame
                }
                self.isMaximized = !self.isMaximized

                if let navController = self.presentedViewController as? UINavigationController {

                    navController.setNeedsStatusBarAppearanceUpdate()

                    // Force the navigation bar to update its size
                    navController.isNavigationBarHidden = true
                    navController.isNavigationBarHidden = false
                }
            }, completion: nil)
        }
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        
        //TODO make the height adjustable
        return CGRect(x: 0, y: containerView!.bounds.height * 0.25, width: containerView!.bounds.width, height: containerView!.bounds.height * 0.75)
    }

    override func presentationTransitionWillBegin() {
        let dimmedView = dimmingView

        if let containerView = self.containerView, let coordinator = presentingViewController.transitionCoordinator {

            dimmedView.alpha = 0
            containerView.addSubview(dimmedView)
            dimmedView.addSubview(presentedViewController.view)

            coordinator.animate(alongsideTransition: { (_) -> Void in
                dimmedView.alpha = 1
                self.presentingViewController.view.transform = CGAffineTransform(scaleX: 1, y: 1)
            }, completion: nil)
        }
    }

    override func dismissalTransitionWillBegin() {
        if let coordinator = presentingViewController.transitionCoordinator {

            coordinator.animate(alongsideTransition: { (_) -> Void in
                self.dimmingView.alpha = 0
                self.presentingViewController.view.transform = CGAffineTransform.identity
            }, completion: { (_) -> Void in
                print("done dismiss animation")
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "halfModalDismissed"), object: nil)
            })

        }
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        print("dismissal did end: \(completed)")

        if completed {
            dimmingView.removeFromSuperview()
            dimmingViewOptional = nil

            isMaximized = false
        }
    }
}

protocol HalfModalPresentable { }

extension HalfModalPresentable where Self: UIViewController {
    func maximizeToFullScreen(allowReverse: Bool = true) {
        if let presetation = navigationController?.presentationController as? HalfModalPresentationController {
            presetation.adjustToFullScreen(allowReverse: allowReverse)
        }
    }
}

extension HalfModalPresentable where Self: UINavigationController {
    func isHalfModalMaximized() -> Bool {
        if let presentationController = presentationController as? HalfModalPresentationController {
            return presentationController.isMaximized
        }

        return false
    }
}
