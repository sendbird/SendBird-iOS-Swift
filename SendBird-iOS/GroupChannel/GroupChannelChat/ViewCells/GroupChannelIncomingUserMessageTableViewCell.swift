//
//  GroupChannelIncomingUserMessageTableViewCell.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 11/6/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK

class GroupChannelIncomingUserMessageTableViewCell: GroupChannelIncomingMessageTableViewCell {
 
    @IBOutlet weak var textMessageLabel: UILabel!
  
    override func awakeFromNib() {
        self.messageCellType = .user

        super.awakeFromNib()
        
        let longClickMessageContainerGesture = UILongPressGestureRecognizer(target: self, action: #selector(GroupChannelIncomingUserMessageTableViewCell.longClickUserMessage(_:)))
        self.messageContainerView.addGestureRecognizer(longClickMessageContainerGesture)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func setMessage(currMessage: SBDBaseMessage, prevMessage: SBDBaseMessage?, nextMessage: SBDBaseMessage?) {
        
        guard let message = (currMessage as? SBDUserMessage) else { return }
        self.textMessageLabel.text = message.message
        
        super.setMessage(currMessage: currMessage, prevMessage: prevMessage, nextMessage: nextMessage)
    }
    
    @objc func longClickUserMessage(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            guard let delegate = self.delegate, let msg = (self.msg as? SBDUserMessage) else { return }
            if delegate.responds(to: #selector(GroupChannelMessageTableViewCellDelegate.didLongClickUserMessage)) {
                delegate.didLongClickUserMessage!(msg)
            }
        }
    }
}
