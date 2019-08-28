//
//  GroupChannelIncomingGeneralFileMessageTableViewCell.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 11/6/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import AlamofireImage
import FLAnimatedImage

class GroupChannelIncomingGeneralFileMessageTableViewCell: GroupChannelIncomingMessageTableViewCell {
    
    @IBOutlet weak var fileNameLabel: UILabel!
    
    override func awakeFromNib() {
        self.messageCellType = .file
        
        let clickMessageContainteGesture = UITapGestureRecognizer(target: self, action: #selector(GroupChannelIncomingGeneralFileMessageTableViewCell.longClickGeneralFileMessage(_:)))
        self.messageContainerView.addGestureRecognizer(clickMessageContainteGesture)
        super.awakeFromNib()
        
        let longClickMessageContainteGesture = UITapGestureRecognizer(target: self, action: #selector(GroupChannelIncomingGeneralFileMessageTableViewCell.clickGeneralFileMessage(_:)))
        self.messageContainerView.addGestureRecognizer(longClickMessageContainteGesture)
        super.awakeFromNib()
    }
    
    override func setMessage(currMessage: SBDBaseMessage, prevMessage: SBDBaseMessage?, nextMessage: SBDBaseMessage?) {
        self.fileNameLabel.text = (currMessage as? SBDFileMessage)?.name
        super.setMessage(currMessage: currMessage, prevMessage: prevMessage, nextMessage: nextMessage)
    }
    
    @objc func longClickGeneralFileMessage(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            guard let delegate = self.delegate, let msg = (self.msg as? SBDFileMessage) else { return }
                if delegate.responds(to: #selector(GroupChannelMessageTableViewCellDelegate.didLongClickGeneralFileMessage(_:))) {
                    delegate.didLongClickGeneralFileMessage!(msg)
                }

        }
    }
    
    @objc func clickGeneralFileMessage(_ recognizer: UITapGestureRecognizer) {
        if let delegate = self.delegate {
            guard let msg = (self.msg as? SBDFileMessage) else { return }
            if delegate.responds(to: #selector(GroupChannelMessageTableViewCellDelegate.didClickVideoFileMessage(_:))) {
                delegate.didClickVideoFileMessage!(msg)
            }
        }
    }
}
