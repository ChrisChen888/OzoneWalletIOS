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
        let contactsViewController = UIStoryboard(name: "Account", bundle: nil).instantiateViewController(withIdentifier: "ContactsTableViewController")

        self.viewControllers.append(accountAssetViewController)
        self.viewControllers.append(transactionHistory)
        self.viewControllers.append(contactsViewController)

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
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "ic_scan"), style: .plain, target: self, action: #selector(rightBarButtonTapped(_:)))
        
        if let nep6 = NEP6.getFromFileSystem() {
            var numAccount = 0
            for account in nep6.accounts {
                if account.isDefault == false && account.key != nil {
                    numAccount += 1
                }
            }
            if numAccount > 0 {
                navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_wallet_swap.png"), style: .plain, target: self, action: #selector(self.swapWalletTapped))
            }
        }
        
        
        #if TESTNET
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Browser", style: .plain, target: self, action: #selector(openDAppBrowser(_:)))
        #endif
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
    
    @objc func swapWalletTapped() {
        guard let modal = UIStoryboard(name: "AddNewMultiWallet", bundle: nil).instantiateViewController(withIdentifier: "UnlockMultiWalletTableViewController") as? UnlockMultiWalletTableViewController else {
            fatalError("Presenting improper modal controller")
        }
        let modalWithNav = UINavigationController(rootViewController: modal)
        self.halfModalTransitioningDelegate = HalfModalTransitioningDelegate(viewController: self, presentingViewController: modalWithNav)
        modalWithNav.modalPresentationStyle = .custom
        modalWithNav.transitioningDelegate = self.halfModalTransitioningDelegate
        self.present(modalWithNav, animated: true)
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
            sendModal.navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "times"), style: .plain, target: self, action: #selector(self.tappedLeftBarButtonItem(_:)))
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
                          Item(title: AccountStrings.transactions),
                          Item(title: AccountStrings.contacts)]
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
        }
        DispatchQueue.main.async {
            self.sendTapped(qrData: data)
        }
    }
    
}
