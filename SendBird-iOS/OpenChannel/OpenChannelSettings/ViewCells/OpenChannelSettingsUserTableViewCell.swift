//
//  OpenChannelSettingsMeTableViewCell.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 11/1/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK

class OpenChannelSettingsUserTableViewCell: UITableViewCell {
    var user: SBDUser?
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var profileCoverView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if SBDMain.getCurrentUser()?.userId == user?.userId {
            profileCoverView.isHidden = false
        } else {
            profileCoverView.isHidden = true
        }
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
