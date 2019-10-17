//
//  GroupChannelOutgoingGeneralFileMessageTableViewCell.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 11/6/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK

class GroupChannelOutgoingGeneralFileMessageTableViewCell: GroupChannelOutgoingMessageTableViewCell {
    
    var hideMessageStatus: Bool = false
    var hideReadCount: Bool = false
    
  
    @IBOutlet weak var fileNameLabel: UILabel!
  
    @IBOutlet weak var fileTransferProgressViewContainerView: UIView!
    @IBOutlet weak var fileTransferProgressCircleView: CustomProgressCircle!
    @IBOutlet weak var fileTransferProgressLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.messageCellType = .file
        
        let longClickMessageContainerGesture = UILongPressGestureRecognizer(target: self, action: #selector(GroupChannelOutgoingGeneralFileMessageTableViewCell.longClickGeneralFileMessage(_:)))
        self.messageContainerView.addGestureRecognizer(longClickMessageContainerGesture)
        
        let clickMessageContainteGesture = UITapGestureRecognizer(target: self, action: #selector(GroupChannelOutgoingGeneralFileMessageTableViewCell.clickGeneralFileMessage(_:)))
        self.messageContainerView.addGestureRecognizer(clickMessageContainteGesture)
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func setMessage(currMessage: SBDFileMessage, prevMessage: SBDBaseMessage?, nextMessage: SBDBaseMessage?, failed: Bool) {
        
        self.hideMessageStatus = false
        self.hideReadCount = false
        
        self.msg = currMessage
        
        self.resendButton.addTarget(self, action: #selector(GroupChannelOutgoingGeneralFileMessageTableViewCell.clickGeneralFileMessage(_:)), for: .touchUpInside)
        
        let filename = NSAttributedString(string: currMessage.name, attributes: [
            NSAttributedString.Key.foregroundColor: UIColor(named: "color_group_channel_message_text") as Any,
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0, weight: .medium),
            ])
        self.fileNameLabel.attributedText = filename

        super.setMessage(currMessage: currMessage, prevMessage: prevMessage, nextMessage: nextMessage, failed: failed)
    }
    
    func showProgress(_ progress: CGFloat) {
        if progress < 1.0 {
            self.fileTransferProgressViewContainerView.isHidden = false
            self.sendingFailureContainerView.isHidden = true
            self.readStatusContainerView.isHidden = true
            
            self.fileTransferProgressCircleView.drawCircle(progress: progress)
            self.fileTransferProgressLabel.text = String(format: "%.2lf%%", progress * 100.0)
            self.messageContainerViewBottomMargin.constant = GroupChannelOutgoingGeneralFileMessageTableViewCell.kMessageContainerViewBottomMarginNormal
        }
        else {
            self.fileTransferProgressViewContainerView.isHidden = true
            self.sendingFailureContainerView.isHidden = true
            self.readStatusContainerView.isHidden = false
            
            if self.hideMessageStatus && self.hideReadCount {
                self.messageContainerViewBottomMargin.constant = 0
            }
            else {
                self.messageContainerViewBottomMargin.constant = GroupChannelOutgoingGeneralFileMessageTableViewCell.kMessageContainerViewBottomMarginNormal
            }
        }
    }
    
    override func hideFailureElement() {
        self.fileTransferProgressViewContainerView.isHidden = true
        self.messageContainerViewBottomMargin.constant = 0
        super.hideFailureElement()
    }
    
    override func showFailureElement() {
        self.fileTransferProgressViewContainerView.isHidden = true
        self.messageContainerViewBottomMargin.constant = GroupChannelOutgoingGeneralFileMessageTableViewCell.kMessageContainerViewBottomMarginNormal
        super.showFailureElement()
    }
    
    func showBottomMargin() {
        self.messageContainerViewBottomMargin.constant = GroupChannelOutgoingGeneralFileMessageTableViewCell.kMessageContainerViewBottomMarginNormal
    }
    
    @objc func longClickGeneralFileMessage(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            if let delegate = self.delegate, let msg = (self.msg as? SBDFileMessage) {
                if delegate.responds(to: #selector(GroupChannelMessageTableViewCellDelegate.didLongClickGeneralFileMessage(_:))) {
                    delegate.didLongClickGeneralFileMessage!(msg)
                }
            }
        }
    }
    
    @objc func clickResendGeneralMessage(_ sender: AnyObject) {
        if let delegate = self.delegate, let msg = (self.msg as? SBDFileMessage) {
            if delegate.responds(to: #selector(GroupChannelMessageTableViewCellDelegate.didClickResendAudioGeneralFileMessage(_:))) {
                delegate.didClickResendAudioGeneralFileMessage!(msg)
            }
        }
    }
    
    @objc func clickGeneralFileMessage(_ recognizer: UITapGestureRecognizer) {
        if let msg = (self.msg as? SBDFileMessage), let delegate = self.delegate {
            if msg.type.hasPrefix("video") {
                if delegate.responds(to: #selector(GroupChannelMessageTableViewCellDelegate.didClickVideoFileMessage(_:))) {
                    delegate.didClickVideoFileMessage!(msg)
                }
            } else {
                if delegate.responds(to: #selector(GroupChannelMessageTableViewCellDelegate.didClickGeneralFileMessage(_:))) {
                    delegate.didClickGeneralFileMessage!(msg)
                }
            }
        }
    }
}
