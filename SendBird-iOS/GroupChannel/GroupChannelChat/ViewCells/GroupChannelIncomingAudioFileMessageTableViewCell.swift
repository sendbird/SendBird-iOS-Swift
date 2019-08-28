//
//  GroupChannelIncomingAudioFileMessageTableViewCell.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 11/7/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import AlamofireImage
import FLAnimatedImage

class GroupChannelIncomingAudioFileMessageTableViewCell: GroupChannelIncomingMessageTableViewCell {

    @IBOutlet weak var fileNameLabel: UILabel!
    
    override func awakeFromNib() {
        self.messageCellType = .audio
        
        let clickMessageContainteGesture = UITapGestureRecognizer(target: self, action: #selector(GroupChannelIncomingAudioFileMessageTableViewCell.clickAudioFileMessage(_:)))
        self.messageContainerView.addGestureRecognizer(clickMessageContainteGesture)
        
        let longClickMessageContainerGesture = UILongPressGestureRecognizer(target: self, action: #selector(GroupChannelIncomingAudioFileMessageTableViewCell.longClickAudioFileMessage(_:)))
        self.messageContainerView.addGestureRecognizer(longClickMessageContainerGesture)
        
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    override func setMessage(currMessage: SBDBaseMessage, prevMessage: SBDBaseMessage?, nextMessage: SBDBaseMessage?) {
        
        self.msg = currMessage
        
        self.fileNameLabel.text = (self.msg as? SBDFileMessage)?.name
        super.setMessage(currMessage: currMessage, prevMessage: prevMessage, nextMessage: nextMessage)
    }
    
    @objc func clickAudioFileMessage(_ recognizer: UITapGestureRecognizer) {
        if let delegate = self.delegate, let msg = self.msg as? SBDFileMessage {
            if delegate.responds(to: #selector(GroupChannelMessageTableViewCellDelegate.didClickAudioFileMessage(_:))) {
                delegate.didClickAudioFileMessage!(msg)
            }
        }
    }
    
    @objc func longClickAudioFileMessage(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            if let delegate = self.delegate, let msg = self.msg as? SBDFileMessage {
                if delegate.responds(to: #selector(GroupChannelMessageTableViewCellDelegate.didLongClickGeneralFileMessage(_:))) {
                    delegate.didLongClickGeneralFileMessage!(msg)
                }
            }
        }
    }
}
