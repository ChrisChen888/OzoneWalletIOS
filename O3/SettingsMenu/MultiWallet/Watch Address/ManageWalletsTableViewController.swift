//
//  ManageWalletsTableViewController.swift
//  O3
//
//  Created by Andrei Terentiev on 10/30/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

class ManageWalletsTableViewController: UITableViewController {
    let nep6 = NEP6.getFromFileSystem()
    var selectedAccount: NEP6.Account!
    
    @IBOutlet weak var headerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLocalizedStrings()
        setThemedElements()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1 + nep6!.getAccounts().count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == nep6!.getAccounts().count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "addWalletTableViewCell") as! AddWalletTableViewCell
            return cell
        } else {
            let account = nep6!.getAccounts()[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "manageWalletTableViewCell") as! ManageWalletTableViewCell
            cell.walletLabel.text = account.label
            cell.addressLabel.text = account.address
            if account.isDefault == false {
                if account.key == nil {
                    cell.walletIsDefaultView.image = UIImage(named: "ic_watch")
                } else {
                    cell.walletIsDefaultView.image = UIImage(named: "ic_locked")
                }
            } else {
                cell.walletIsDefaultView.image = UIImage(named: "ic_unlocked")

            }
            
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        DispatchQueue.main.async {
            if indexPath.row == self.nep6!.getAccounts().count {
                self.performSegue(withIdentifier: "segueToAddItemToMultiWallet", sender: nil)
            } else {
                self.selectedAccount = self.nep6!.getAccounts()[indexPath.row]
                self.performSegue(withIdentifier: "segueToManageWallet", sender: nil)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToManageWallet" {
            guard let nav = segue.destination as? UINavigationController,
                let child = nav.children[0] as? ManageWalletTableViewController else {
                    fatalError("Something went terribly wrong")
            }
            child.account = selectedAccount
        }
    }
    
    func setLocalizedStrings() {
        self.title = ""
    }
    
    func setThemedElements() {
        tableView.theme_backgroundColor = O3Theme.backgroundColorPicker
        headerView.theme_backgroundColor =
            O3Theme.backgroundColorPicker
        applyBottomSheetNavBarTheme(title: MultiWalletStrings.Wallets)
    }
}
