//
//  WalletSelectorTableViewCell.swift
//  O3
//
//  Created by Andrei Terentiev on 4/30/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit

class WalletSelectorTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    
    struct Data {
        var title = ""
        var subtitle = ""
        var value: AccountValue?
    }
    
    var data: Data? {
        didSet {
            titleLabel.text = data!.title
            subtitleLabel.text = data!.subtitle
            
            if let accountValue = data?.value {
                let formatter = NumberFormatter()
                formatter.currencySymbol = accountValue.currency
                formatter.locale = Locale(identifier: "en_US_POSIX")
                let number = formatter.number(from: accountValue.total)
                let fiat = Fiat(amount: number?.floatValue ?? 0.0)
                valueLabel.text = fiat.formattedString()
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = UIColor.clear
        setThemedElements()
    }
    
    func setThemedElements() {
        titleLabel.theme_textColor = O3Theme.titleColorPicker
        subtitleLabel.theme_textColor = O3Theme.lightTextColorPicker
        valueLabel.theme_textColor = O3Theme.titleColorPicker
    }
}
