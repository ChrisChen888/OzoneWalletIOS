//
//  AppDelegate.swift
//  O3
//
//  Created by Andrei Terentiev on 9/6/17.
//  Copyright © 2017 drei. All rights reserved.
//

import UIKit
import Channel
import CoreData
import Reachability
import Fabric
import Crashlytics
import SwiftTheme
import Neoutils

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func setupChannel() {
        //O3 Development on Channel app_gUHDmimXT8oXRSpJvCxrz5DZvUisko_mliB61uda9iY
        Channel.setup(withApplicationId: "app_gUHDmimXT8oXRSpJvCxrz5DZvUisko_mliB61uda9iY")
    }

    static func setNavbarAppearance() {
        UINavigationBar.appearance().theme_largeTitleTextAttributes = O3Theme.largeTitleAttributesPicker
        UINavigationBar.appearance().theme_titleTextAttributes =
            O3Theme.regularTitleAttributesPicker
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().theme_barTintColor = O3Theme.navBarColorPicker
        UINavigationBar.appearance().theme_backgroundColor = O3Theme.navBarColorPicker
        UIApplication.shared.theme_setStatusBarStyle(O3Theme.statusBarStylePicker, animated: true)
    }

    func registerDefaults() {
        let userDefaultsDefaults: [String: Any] = [
            "networkKey": "main",
            "usedDefaultSeedKey": false,
            "selectedThemeKey": Theme.light.rawValue,
            "referenceCurrencyKey": Currency.usd.rawValue,
            "numClaimsKey": 0
        ]
        UserDefaults.standard.register(defaults: userDefaultsDefaults)
    }

    let alertController = UIAlertController(title: OzoneAlert.noInternetError, message: nil, preferredStyle: .alert)
    @objc func reachabilityChanged(_ note: Notification) {
        switch reachability.connection {
        case .wifi:
            print("Reachable via WiFi")
            alertController.dismiss(animated: true, completion: nil)

        case .cellular:
            print("Reachable via cellular")
            alertController.dismiss(animated: true, completion: nil)
        case .none:
            print("Network not reachable")
            UIApplication.shared.keyWindow?.rootViewController?.presentFromEmbedded(alertController, animated: true, completion: nil)
        }
    }
    let reachability = Reachability()!
    func setupReachability() {
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(_:)), name: .reachabilityChanged, object: nil)
        do {
            try reachability.startNotifier()
        } catch {
            print("could not start reachability notifier")
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        #if DEBUG
        print("DEBUG BUILD")
        #else
        Fabric.with([Crashlytics.self])
        #endif

        self.registerDefaults()
        self.setupChannel()
        self.setupReachability()
        AppDelegate.setNavbarAppearance()
        print(NSHomeDirectory())

        //check if there is an existing wallet in keychain
        //if so, present LoginToCurrentWalletViewController
        let walletExists =  UserDefaultsManager.o3WalletAddress != nil
        if walletExists {
            guard let login = UIStoryboard(name: "Onboarding", bundle: nil)
                .instantiateViewController(withIdentifier: "LoginToCurrentWalletViewController") as? LoginToCurrentWalletViewController else {
                    return false
            }
            if let window = self.window {
                login.delegate = self
                //pass the launchOptions to the login screen
                login.launchOptions = launchOptions
                window.rootViewController = login
                return false
            }
        }
        //Onboarding Theme
        return true
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "O3")
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    // MARK: - deeplink
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any] = [:]) -> Bool {
       if app.applicationState == .inactive {
            parseNEP9URL(url: url)
        }
        return false
    }

    func parseNEP9URL(url: URL) {
        if Authenticated.account == nil {
            return
        }
        var updatedURL: URL = url
        if !url.absoluteString.contains("neo://") {
            let fullURL = updatedURL.absoluteString.replacingOccurrences(of: "neo:", with: "neo://")
            updatedURL = URL(string: fullURL)!
        }
        let address = updatedURL.host?.removingPercentEncoding
        let asset = updatedURL.valueOf("asset")
        let amount = updatedURL.valueOf("amount")
        //Get account state
        O3APIClient(network: AppState.network).getAccountState(address: Authenticated.account!.address) { result in
            DispatchQueue.main.async {
                switch result {
                case .failure:
                    return
                case .success(let accountState):

                    var neoBalance: Int = Int(O3Cache.neo().value)
                    var gasBalance: Double = O3Cache.gas().value

                    for asset in accountState.assets {
                        if asset.id.contains(AssetId.neoAssetId.rawValue) {
                            neoBalance = Int(asset.value)
                        } else {
                            gasBalance = asset.value
                        }
                    }

                    var tokenAssets = O3Cache.tokenAssets()
                    var selectedAsset: TransferableAsset?
                    for token in accountState.nep5Tokens {
                        tokenAssets.append(token)
                        if token.id == asset {
                            selectedAsset = token
                        }
                    }
                    O3Cache.setGASForSession(gasBalance: gasBalance)
                    O3Cache.setNEOForSession(neoBalance: neoBalance)
                    O3Cache.setTokenAssetsForSession(tokens: tokenAssets)

                    if asset?.lowercased() == "neo" {
                        Controller().openSend(to: address!, selectedAsset: TransferableAsset.NEO(), amount: amount)
                    } else if asset?.lowercased() == "gas" {
                        Controller().openSend(to: address!, selectedAsset: TransferableAsset.GAS(), amount: amount)
                    } else if selectedAsset != nil {
                        Controller().openSend(to: address!, selectedAsset: selectedAsset!, amount: amount)
                    }
                }
            }
        }
    }
}

extension AppDelegate: LoginToCurrentWalletViewControllerDelegate {
    func authorized(launchOptions: [UIApplicationLaunchOptionsKey: Any]?) {
        if let url = launchOptions?[UIApplicationLaunchOptionsKey.url] as? URL {
            self.parseNEP9URL(url: url)
        }
    }
}
