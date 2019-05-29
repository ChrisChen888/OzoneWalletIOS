//
//  InboxTableViewCell.swift
//  O3
//
//  Created by Andrei Terentiev on 4/22/19.
//  Copyright © 2019 O3 Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher

class InboxTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    
    var data: Message? {
        didSet {
            guard let dataUnwrapped = data else {
                return
            }
            titleLabel.text = dataUnwrapped.sender.name
            subtitleLabel.text = dataUnwrapped.data.text
            
            let dateformatter = DateFormatter()
            dateformatter.dateStyle = .short
            dateformatter.timeStyle = .none
            dateLabel.text = dateformatter.string(from: Date(timeIntervalSince1970: Double(dataUnwrapped.timestamp)))
            
            logoImageView.kf.setImage(with: URL(string: dataUnwrapped.sender.imageURL))
            
            DispatchQueue.main.async {
                if dataUnwrapped.action == nil {
                    
                    self.actionButton.isHidden = true
                    
                   // self.buttonToSubtitleVerticalConstraint.isActive = false
                    self.setNeedsLayout()
                    self.layoutIfNeeded()
                } else {
                    self.actionButton.isHidden = false
                    self.actionButton.setTitle(dataUnwrapped.action!.title, for: UIControl.State())

                    self.setNeedsLayout()
                    self.layoutIfNeeded()
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setThemedElements()
    }
    
    
    func setThemedElements() {
        theme_backgroundColor = O3Theme.backgroundColorPicker
        titleLabel.theme_textColor = O3Theme.titleColorPicker
        subtitleLabel.theme_textColor = O3Theme.titleColorPicker
        dateLabel.theme_textColor = O3Theme.lightTextColorPicker
    }
}
