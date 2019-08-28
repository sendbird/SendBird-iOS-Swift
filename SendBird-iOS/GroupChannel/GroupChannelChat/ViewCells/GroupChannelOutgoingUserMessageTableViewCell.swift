//
//  GroupChannelOutgoingUserMessageTableViewCell.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 11/6/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK

class GroupChannelOutgoingUserMessageTableViewCell: GroupChannelOutgoingMessageTableViewCell {
    
   
    @IBOutlet weak var textMessageLabel: UILabel!
   
    
    override func awakeFromNib() {
        super.awakeFromNib()

        self.messageCellType = .user
        
        let longClickMessageContainerGesture = UILongPressGestureRecognizer(target: self, action: #selector(GroupChannelOutgoingUserMessageTableViewCell.longClickUserMessage(_:)))
        self.messageContainerView.addGestureRecognizer(longClickMessageContainerGesture)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    override func setMessage(currMessage: SBDBaseMessage, prevMessage: SBDBaseMessage?, nextMessage: SBDBaseMessage?, failed: Bool?) {
        
        self.resendButton.addTarget(self, action: #selector(GroupChannelOutgoingUserMessageTableViewCell.clickResendUserMessage(_:)), for: .touchUpInside)
        
        self.textMessageLabel.text = (currMessage as? SBDUserMessage)?.message
        
        super.setMessage(currMessage: currMessage, prevMessage: prevMessage, nextMessage: nextMessage, failed: failed)
    }

    
    @objc func clickResendUserMessage(_ sender: AnyObject) {
        if let delegate = self.delegate, let msg = (self.msg as? SBDUserMessage){
            if delegate.responds(to: #selector(GroupChannelMessageTableViewCellDelegate.didClickResendUserMessage(_:))) {
                delegate.didClickResendUserMessage!(msg)
            }
        }
    }
    
    @objc func longClickUserMessage(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            if let delegate = self.delegate, let msg = (self.msg as? SBDUserMessage) {
                if delegate.responds(to: #selector(GroupChannelMessageTableViewCellDelegate.didLongClickUserMessage(_:))) {
                    delegate.didLongClickUserMessage!(msg)
                }
            }
        }
    }
}

