//
//  GroupChannelSettingsNotificationsTableViewCell.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 11/16/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit

class GroupChannelSettingsNotificationsTableViewCell: UITableViewCell {
    @IBOutlet weak var notificationSwitch: UISwitch!
    
    weak var delegate: GroupChannelSettingsTableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func clickSwitch(_ sender: Any) {
        guard let sw = self.notificationSwitch else { return }
        if let delegate = self.delegate {
            delegate.didChangeNotificationSwitchButton(isOn: sw.isOn)
        }
    }
}
