//
//  O3KeychainManager.swift
//  O3
//
//  Created by Andrei Terentiev on 4/11/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import PKHUD
import KeychainAccess
import Neoutils

class O3KeychainManager {
    public enum O3KeychainResult<T> {
        case success(T)
        case failure(String) //could be error type
    }
    
    private static let keychainService = "network.o3.neo.wallet"
    
    //not used anymore maintain for backwards compatibilit if nep6 style key is not in keychain user is prompted to upgrade
    private static let legacySigningKeyPasswordKey = "ozoneActiveNep6Password"
    
    //legacy not used any more, maintain for backwards compatibility, if active in keychain, user will be prompted to upgrade
    private static let wifKey = "ozonePrivateKey"
    
    static func getSigningKeyPassword(with prompt: String, completion: @escaping(O3KeychainResult<String>) -> ()) {
        DispatchQueue.global(qos: .userInitiated).async {
            let keychain = Keychain(service: self.keychainService)
            do {
                let signingKeyPass = try keychain
                        .accessibility(.whenPasscodeSetThisDeviceOnly, authenticationPolicy: .userPresence)
                        .authenticationPrompt(prompt)
                        .get(self.legacySigningKeyPasswordKey)
            
                guard signingKeyPass != nil else {
                    completion(.failure("The Key does not exist"))
                    return
                }
                completion(.success(signingKeyPass!))
            } catch let error {
                completion(.failure(error.localizedDescription))
            }
        }
    }
    
    static func setSigningKeyPassword(with prompt: String, pass: String,
                                      completion: @escaping(O3KeychainResult<Bool>) -> ()) {
        DispatchQueue.global(qos: .userInitiated).async {
            let keychain = Keychain(service: "network.o3.neo.wallet")
            do {
                //save pirivate key to keychain
                try keychain
                    .accessibility(.whenPasscodeSetThisDeviceOnly, authenticationPolicy: .userPresence)
                    .authenticationPrompt(prompt)
                    .set(pass, key: self.legacySigningKeyPasswordKey)
                completion(.success(true))
            } catch let error {
                completion(.failure(error.localizedDescription))
            }
        }
    }
    
    static func getWifKey(completion: @escaping(O3KeychainResult<String>) -> ()) {
        DispatchQueue.global(qos: .userInitiated).async {
            let keychain = Keychain(service: self.keychainService)
            let authString = String(format: OnboardingStrings.nep6AuthenticationPrompt, "My O3 Wallet")
            do {
                let wif = try keychain
                    .accessibility(.whenPasscodeSetThisDeviceOnly, authenticationPolicy: .userPresence)
                    .authenticationPrompt(authString)
                    .get(self.wifKey)
                
                guard wif != nil else {
                    completion(.failure("The Key does not exist"))
                    return
                }
                completion(.success(wif!))
            } catch let error {
                completion(.failure(error.localizedDescription))
            }
        }
    }
    
    static func removeLegacyWifKey(completion: @escaping(O3KeychainResult<String>) -> ()) {
        do {
            let keychain = Keychain(service: self.keychainService)
            try keychain
                .accessibility(.whenPasscodeSetThisDeviceOnly, authenticationPolicy: .userPresence)
                .remove(self.wifKey)
        } catch _ {
            return
        }
    }
    
    static func removeSigningKeyPassword(completion: @escaping(O3KeychainResult<String>) -> ()) {
        do {
            let keychain = Keychain(service: self.keychainService)
            try keychain
                .accessibility(.whenPasscodeSetThisDeviceOnly, authenticationPolicy: .userPresence)
                .remove(self.legacySigningKeyPasswordKey)
        } catch _ {
            return
        }
    }
    
    static func inputPassword(account: NEP6.Account, completion: @escaping(O3KeychainResult<String>) -> ()) {
        let alertController = UIAlertController(title: String(format: "Login to %@", account.label), message: "Enter the password you used to secure this wallet", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: OzoneAlert.okPositiveConfirmString, style: .default) { (_) in
            let inputPass = alertController.textFields?[0].text
            var error: NSError?
            if let wif = NeoutilsNEP2Decrypt(account.key!, inputPass, &error) {
                completion(.success(wif))
            } else {
                OzoneAlert.alertDialog("Incorrect passphrase", message: "Please check your passphrase and try again", dismissTitle: "Ok") {
                    completion(.failure("Failed Decryption"))
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: OzoneAlert.cancelNegativeConfirmString, style: .cancel) { (_) in
            completion(.failure("Failed Decryption"))
        }
        
        alertController.addTextField { (textField) in
            textField.isSecureTextEntry = true
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        UIApplication.shared.keyWindow?.rootViewController?.presentFromEmbedded(alertController, animated: true, completion: nil)
    }
    
    
    static func getWifFromNep6(for address: String, completion: @escaping(O3KeychainResult<String>) -> ()) {
        let account = (NEP6.getFromFileSystem()?.accounts.first{ $0.address == address})!
       // DispatchQueue.global(qos: .userInteractive).async {
            let keychain = Keychain(service: self.keychainService)
            let hashed = (address.data(using: .utf8)?.sha256.sha256.fullHexString)!
            let keychainKey = "NEP6." + hashed
            let accountLabel = account.label
            let authString = String(format: OnboardingStrings.nep6AuthenticationPrompt, accountLabel)
            do {
                let keyPass = try keychain
                    .accessibility(.whenUnlockedThisDeviceOnly, authenticationPolicy: .userPresence)
                    .authenticationPrompt(authString)
                    .get(keychainKey)
                
                if keyPass != nil {
                    var error: NSError? = nil
                    let currtime = Date().timeIntervalSince1970
                
                    let wif = NeoutilsNEP2Decrypt(account.key, keyPass, &error)
                    guard error == nil else {
                        completion(.failure(error!.localizedDescription))
                        return
                    }
                    print (Date().timeIntervalSince1970 - currtime)
                    completion(.success(wif!))
                    return
                }
                
                O3KeychainManager.inputPassword(account: account) { result in
                    completion(result)
                }
            } catch let error {
                completion(.failure(error.localizedDescription))
            }
        //}
    }
    
    static func setNep6DecryptionPassword(for address: String, pass: String, completion: @escaping(O3KeychainResult<String>) -> ()) {
        let keychain = Keychain(service: self.keychainService)
        let hashed = (address.data(using: .utf8)?.sha256.sha256.fullHexString)!
        let keychainKey = "NEP6." + hashed
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                //save pirivate key to keychain
                try keychain
                    .accessibility(.whenUnlockedThisDeviceOnly, authenticationPolicy: .userPresence)
                    .set(pass, key: keychainKey)
                completion(.success(""))
            } catch let error {
                completion(.failure(error.localizedDescription))
            }
        }
    }
    
    static func removeNep6DecryptionPassword(for address: String, completion: @escaping(O3KeychainResult<Bool>) -> ()) {
        let keychain = Keychain(service: self.keychainService)
        let hashed = (address.data(using: .utf8)?.sha256.sha256.fullHexString)!
        let keychainKey = "NEP6." + hashed
        do {
            try keychain
                .accessibility(.whenPasscodeSetThisDeviceOnly, authenticationPolicy: .userPresence)
                .remove(keychainKey)
            completion(.success(true))
        } catch let error {
            completion(.failure(error.localizedDescription))
        }
    }
    
    static func checkNep6PasswordExists(for address: String, completion: @escaping(O3KeychainResult<Bool>) -> ()) {
        let keychain = Keychain(service: self.keychainService)
        let hashed = (address.data(using: .utf8)?.sha256.sha256.fullHexString)!
        let keychainKey = "NEP6." + hashed
        do {
            //save pirivate key to keychain
            let containsKey = try keychain.contains(keychainKey)
            completion(.success(containsKey))
        } catch let error {
            completion(.failure(error.localizedDescription))
        }
    }
}
