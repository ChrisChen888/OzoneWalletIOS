//
//  AccountTabViewController.swift
//  O3
//
//  Created by Apisit Toompakdee on 1/21/18.
//  Copyright © 2018 drei. All rights reserved.
//

import UIKit
import Tabman
import Pageboy
import DeckTransition
import SwiftTheme

class AccountTabViewController: TabmanViewController, PageboyViewControllerDataSource, HalfModalPresentable {
    
    var viewControllers: [UIViewController] = []
    // swiftlint:disable weak_delegate
    var halfModalTransitioningDelegate: HalfModalTransitioningDelegate?
    // swiftlint:enable weak_delegate
    
    func addThemeObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.changedTheme), name: Notification.Name(rawValue: ThemeUpdateNotification), object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: ThemeUpdateNotification), object: nil)
    }

    @objc func changedTheme(_ sender: Any) {
        self.bar.appearance = TabmanBar.Appearance({ (appearance) in
            appearance.state.selectedColor = UserDefaultsManager.theme.primaryColor
            appearance.state.color = UserDefaultsManager.theme.lightTextColor
            appearance.layout.edgeInset = 16
            appearance.text.font = O3Theme.topTabbarItemFont
            appearance.style.background = .solid(color: UserDefaultsManager.theme.backgroundColor)
            appearance.indicator.useRoundedCorners = true
            appearance.interaction.isScrollEnabled = false
        })
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        addThemeObserver()

        let accountAssetViewController = UIStoryboard(name: "Account", bundle: nil).instantiateViewController(withIdentifier: "AccountAssetTableViewController")
        let transactionHistory = UIStoryboard(name: "Account", bundle: nil).instantiateViewController(withIdentifier: "TransactionHistoryTableViewController")
        
        self.viewControllers.append(accountAssetViewController)
        self.viewControllers.append(transactionHistory)

        self.dataSource = self

        self.bar.appearance = TabmanBar.Appearance({ (appearance) in
            appearance.state.selectedColor = UserDefaultsManager.theme.primaryColor
            appearance.state.color = UserDefaultsManager.theme.lightTextColor
            appearance.text.font = O3Theme.topTabbarItemFont
            appearance.layout.edgeInset = 16
            appearance.style.background = .solid(color: UserDefaultsManager.theme.backgroundColor)
        })
        self.bar.location = .top
        self.bar.style = .buttonBar
        self.view.theme_backgroundColor = O3Theme.backgroundColorPicker
        setNavigationItems()
    }
    
    func setNavigationItems() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "ic_scan"), style: .plain, target: self, action: #selector(rightBarButtonTapped(_:)))
        
        if let nep6 = NEP6.getFromFileSystem() {
            var numAccount = 0
            for account in nep6.accounts {
                if account.isDefault == false && account.key != nil {
                    numAccount += 1
                }
            }
            if numAccount > 0 {
                navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "support"), style: .plain, target: self, action: #selector(self.inboxTapped))
            }
        }
        
        
        #if TESTNET
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Browser", style: .plain, target: self, action: #selector(openDAppBrowser(_:)))
        #endif
        
        let activeWallet = NEP6.getFromFileSystem()!.accounts.first {$0.isDefault}!.label
        let titleViewButton = UIButton(type: .system)
        titleViewButton.theme_setTitleColor(O3Theme.titleColorPicker, forState: UIControl.State())
        titleViewButton.titleLabel?.font = UIFont(name: "Avenir-Heavy", size: 16)!
        titleViewButton.setTitle(activeWallet, for: .normal)
        titleViewButton.semanticContentAttribute = .forceRightToLeft
        titleViewButton.setImage(UIImage(named: "ic_chevron_down"), for: UIControl.State())
        
        titleViewButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        titleViewButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -20)
        // Create action listener
        titleViewButton.addTarget(self, action: #selector(showMultiWalletDisplay), for: .touchUpInside)
        navigationItem.titleView = titleViewButton
    }

    @objc func showMultiWalletDisplay() {
        Controller().openWalletSelector()
    }
    
    @objc func openDAppBrowser(_ sender: Any) {
        Controller().openSwitcheoDapp()
    }

    override func viewWillAppear(_ animated: Bool) {
        applyNavBarTheme()
        super.viewWillAppear(animated)
    }

    func numberOfViewControllers(in pageboyViewController: PageboyViewController) -> Int {
        return viewControllers.count
    }

    func viewController(for pageboyViewController: PageboyViewController, at index: PageboyViewController.PageIndex) -> UIViewController? {
        return viewControllers[index]
    }

    func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
        return nil
    }
    
    @objc func inboxTapped() {
        let inboxController = UIStoryboard(name: "Inbox", bundle: nil).instantiateInitialViewController()!
        self.present(inboxController, animated: true)
    }

    @objc func rightBarButtonTapped(_ sender: Any) {
    
        guard let modal = UIStoryboard(name: "QR", bundle: nil).instantiateInitialViewController() as? QRScannerController else {
            fatalError("Presenting improper modal controller")
        }
        modal.delegate = self
        let nav = WalletHomeNavigationController(rootViewController: modal)
        nav.navigationBar.prefersLargeTitles = false
        nav.setNavigationBarHidden(true, animated: false)
        let transitionDelegate = DeckTransitioningDelegate()
        nav.transitioningDelegate = transitionDelegate
        nav.modalPresentationStyle = .custom
        self.present(nav, animated: true, completion: nil)
    }
    
    func sendTapped(qrData: String? = nil) {
        DispatchQueue.main.async {
            guard let sendModal = UIStoryboard(name: "Send", bundle: nil).instantiateViewController(withIdentifier: "sendWhereTableViewController") as? SendWhereTableViewController else {
                fatalError("Presenting improper modal controller")
            }
            sendModal.incomingQRData = qrData
            let nav = WalletHomeNavigationController(rootViewController: sendModal)
            nav.navigationBar.prefersLargeTitles = false
            nav.navigationItem.largeTitleDisplayMode = .never
            sendModal.navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "close-x"), style: .plain, target: self, action: #selector(self.tappedLeftBarButtonItem(_:)))
            let transitionDelegate = DeckTransitioningDelegate()
            nav.transitioningDelegate = transitionDelegate
            nav.modalPresentationStyle = .custom
            self.present(nav, animated: true, completion: nil)
        }
    }
    
    @IBAction func tappedLeftBarButtonItem(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    func setLocalizedStrings() {
        self.bar.items = [Item(title: "Accounts".uppercased()), //TODO change this to localized string
                          Item(title: AccountStrings.transactions)
                        ]
    }
}

extension AccountTabViewController: QRScanDelegate {
    
    func postToChannel(channel: String) {
        let headers = ["content-type": "application/json"]
        let parameters = ["address": Authenticated.wallet!.address,
                          "device": "iOS" ] as [String: Any]
        
        let postData = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        
        let request = NSMutableURLRequest(url: NSURL(string: "https://platform.o3.network/api/v1/channel/" + channel)! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = postData
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (_, response, error) -> Void in
            if error != nil {
                return
            } else {
                _ = response as? HTTPURLResponse
            }
        })
        
        dataTask.resume()
    }
    
    func qrScanned(data: String) {
        //if there is more type of string we have to check it here
        if data.hasPrefix("o3://channel") {
            //post to utility communication channel
            let channel = URL(string: data)?.lastPathComponent
            postToChannel(channel: channel!)
            return
        } else if data.hasPrefix("neo") {
            DispatchQueue.main.async {
                self.sendTapped(qrData: data)
            }
        } else if (URL(string: data) != nil) {
            //dont present from top
            let nav = UIStoryboard(name: "dAppBrowser", bundle: nil).instantiateInitialViewController() as? UINavigationController
            if let vc = nav!.viewControllers.first as?
                dAppBrowserV2ViewController {
                let viewModel = dAppBrowserViewModel()
                viewModel.url = URL(string: data)
                vc.viewModel = viewModel
                DispatchQueue.main.async {
                    self.present(nav!, animated: true)
                }
            }
        } else {
            DispatchQueue.main.async {
                self.sendTapped(qrData: data)
            }
        }
    }
    
}
