//
//  Events.swift
//  O3
//
//  Created by Apisit Toompakdee on 10/4/18.
//  Copyright © 2018 O3 Labs Inc. All rights reserved.
//

import UIKit
import Amplitude

enum TradingActionSource: String {
    case tradingAccount = "trading_account"
    case asset = "trading_account_menu_item"
    case o3Account = "wallet_account_menu_item"
    case tokenDetail = "token_details"
    case marketplace = "marketplace_card"
}

enum tradingEventName: String {
    case withdrawInitiated = "Withdraw_Initiated"
    case depositInitiated = "Deposit_Initiated"
    case buyInitiated = "Buy_Initiated"
    case sellInitiated = "Sell_Initiated"
    case tokenDetailSelected = "Token_Details_Selected"
    case notEnoughTradingBalance = "Not_enough_trading_balance_error"
    case depositSuccessfully = "Deposit"
    case withdrawSuccessfully = "Withdraw"
    case canceledOrder = "Order Cancelled"
    case viewClosedOrder = "Show Closed Orders"
    case placedOrder = "Native_Order_Placed"
}

enum tradingEventField: String {
    case asset = "asset"
    case source = "source"
    case amount = "amount"
    case orderID = "order_id"
    case datetime = "datetime"
    case side = "side"
    case pair = "pair"
    case baseCurrency = "base_currency"
    case quantity = "quantity"
    case priceSelection = "price_selection"
}

enum multiwalletEventName: String {
    case walletAdded = "wallet_added"
    case watchAddressAdded = "watch_address_added"
    case multiwalletActivated = "multiwallet_activated"
    case walletUnlocked = "wallet_unlocked"
}

enum multiWalletEventField: String {
    case numWallets = "total_num_wallets"
    case numWatchAddresses = "total_num_watch_addresses"
}

class MultiwalletEvent: NSObject {
    private var amplitude: Amplitude! = Amplitude.instance()
    static let shared: MultiwalletEvent! = MultiwalletEvent()
    
    func log(event: String, data: [String: Any]) {
        amplitude.logEvent(event, withEventProperties: data)
    }
    
    func walletAdded(numWallets: Int) {
        log(event: multiwalletEventName.walletAdded.rawValue,
            data: [multiWalletEventField.numWallets.rawValue: numWallets])
    }
    
    func watchAddressAdded(numWatchAddresses: Int) {
        log(event: multiwalletEventName.watchAddressAdded.rawValue,
            data: [multiWalletEventField.numWatchAddresses.rawValue: numWatchAddresses])
    }
    
    func multiwalletActivated() {
        log(event: multiwalletEventName.multiwalletActivated.rawValue,
            data: [:])
    }
    
    func walletUnlocked() {
        log(event: multiwalletEventName.walletUnlocked.rawValue,
            data: [:])
    }
}

class tradingEvent: NSObject {
    
    private var amplitude: Amplitude! = Amplitude.instance()
    static let shared: tradingEvent! = tradingEvent()
    
    func log(event: String, data: [String: Any]) {
         amplitude.logEvent(event, withEventProperties: data)
    }
    
    func startWithdraw(asset: String, source: TradingActionSource){
        let properties: [String: Any] = [tradingEventField.asset.rawValue: asset,
                                         tradingEventField.source.rawValue: source.rawValue]
        log(event: tradingEventName.withdrawInitiated.rawValue, data: properties)
    }
    
    func successfullyWithdraw(asset: String, amount: Double){
        let properties: [String: Any] = [tradingEventField.asset.rawValue: asset,
                                         tradingEventField.amount.rawValue: amount]
         log(event: tradingEventName.withdrawSuccessfully.rawValue, data: properties)
    }
    
    func startDeposit(asset: String, source: TradingActionSource){
        let properties: [String: Any] = [tradingEventField.asset.rawValue: asset,
                                         tradingEventField.source.rawValue: source.rawValue]
         log(event: tradingEventName.depositInitiated.rawValue, data: properties)
    }
    
    func successfullyDeposit(asset: String, amount: Double){
        let properties: [String: Any] = [tradingEventField.asset.rawValue: asset,
                                         tradingEventField.amount.rawValue: amount]
         log(event: tradingEventName.depositSuccessfully.rawValue, data: properties)
    }
    
    func startBuy(asset: String, source: TradingActionSource){
        let properties: [String: Any] = [tradingEventField.asset.rawValue: asset,
                                         tradingEventField.source.rawValue: source.rawValue]
         log(event: tradingEventName.buyInitiated.rawValue, data: properties)
    }
    
    func startSell(asset: String, source: TradingActionSource){
        let properties: [String: Any] = [tradingEventField.asset.rawValue: asset,
                                         tradingEventField.source.rawValue: source.rawValue]
        log(event: tradingEventName.sellInitiated.rawValue, data: properties)
    }
    
    func viewTokenDetail(asset: String, source: TradingActionSource){
        let properties: [String: Any] = [tradingEventField.asset.rawValue: asset,
                                         tradingEventField.source.rawValue: source.rawValue]
        log(event: tradingEventName.tokenDetailSelected.rawValue, data: properties)
    }
    
    func notEnoughTradingBalance() {
        log(event: tradingEventName.notEnoughTradingBalance.rawValue, data: [:])
    }
    
    func canceledOrder(orderID: String) {
        let properties: [String: Any] = [tradingEventField.orderID.rawValue: orderID]
        log(event: tradingEventName.canceledOrder.rawValue, data: properties)
    }
    
    func viewClosedOrder() {
        log(event: tradingEventName.viewClosedOrder.rawValue, data: [:])
    }
    
    func placedOrder(orderID: String, datetime: String, side: String, pair: String, baseCurrency: String, quantity: Double, priceSelection: String) {
        let properties: [String: Any] = [tradingEventField.orderID.rawValue: orderID,
                                         tradingEventField.datetime.rawValue: datetime,
                                         tradingEventField.side.rawValue: side,
                                         tradingEventField.pair.rawValue: pair,
                                         tradingEventField.baseCurrency.rawValue: baseCurrency,
                                         tradingEventField.quantity.rawValue: quantity,
                                         tradingEventField.priceSelection.rawValue: priceSelection]
        log(event: tradingEventName.placedOrder.rawValue, data: properties)
    }
    
}



