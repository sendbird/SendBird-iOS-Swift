//
//  GroupChannelOutgoingAudioFileMessageTableViewCell.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 11/6/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK


class GroupChannelOutgoingAudioFileMessageTableViewCell: GroupChannelOutgoingMessageTableViewCell {
 
    private var hideMessageStatus: Bool = false
    private var hideReadCount: Bool = false
    
    @IBOutlet weak var fileNameLabel: UILabel!

    @IBOutlet weak var fileTransferProgressViewContainerView: UIView!
    @IBOutlet weak var fileTransferProgressCircleView: CustomProgressCircle!
    @IBOutlet weak var fileTransferProgressLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.messageCellType = .audio
        
        let longClickMessageContainerGesture = UILongPressGestureRecognizer(target: self, action: #selector(GroupChannelOutgoingAudioFileMessageTableViewCell.longClickAudioFileMessage(_:)))
        self.messageContainerView.addGestureRecognizer(longClickMessageContainerGesture)
        
        let clickMessageContainteGesture = UITapGestureRecognizer(target: self, action: #selector(GroupChannelOutgoingAudioFileMessageTableViewCell.clickAudioFileMessage(_:)))
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
        
        self.resendButton.addTarget(self, action: #selector(GroupChannelOutgoingAudioFileMessageTableViewCell.clickResendAudioMessage(_:)), for: .touchUpInside)
        
        let filename = NSAttributedString(string: currMessage.name, attributes: [
            NSAttributedString.Key.foregroundColor: UIColor.white as Any,
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12.0, weight: .regular),
            ])
        self.fileNameLabel.attributedText = filename
        
        super.setMessage(currMessage: currMessage, prevMessage: prevMessage, nextMessage: nextMessage, failed: failed)
    }
    
    func showProgress(_ progress: CGFloat) {
        if progress < 1.0 {
            self.messageDateLabel.isHidden = true
            self.fileTransferProgressViewContainerView.isHidden = false
            self.sendingFailureContainerView.isHidden = true
            self.readStatusContainerView.isHidden = true
            
            self.fileTransferProgressCircleView.drawCircle(progress: progress)
            self.fileTransferProgressLabel.text = String(format: "%.2lf%%", progress * 100.0)
            self.messageContainerViewBottomMargin.constant = GroupChannelOutgoingAudioFileMessageTableViewCell.kMessageContainerViewBottomMarginNormal
        }
        else {
            self.messageDateLabel.isHidden = false
            self.fileTransferProgressViewContainerView.isHidden = true
            self.sendingFailureContainerView.isHidden = true
            self.readStatusContainerView.isHidden = false

            if self.hideMessageStatus && self.hideReadCount {
                self.messageContainerViewBottomMargin.constant = 0
            }
            else {
                self.messageContainerViewBottomMargin.constant = GroupChannelOutgoingAudioFileMessageTableViewCell.kMessageContainerViewBottomMarginNormal
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
    func hideProgress() {
        self.fileTransferProgressViewContainerView.isHidden = true
        self.sendingFailureContainerView.isHidden = true
    }
    
    func showBottomMargin() {
        self.messageContainerViewBottomMargin.constant = GroupChannelOutgoingAudioFileMessageTableViewCell.kMessageContainerViewBottomMarginNormal
    }
    
    @objc func longClickAudioFileMessage(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            if let delegate = self.delegate, let msg = (self.msg as? SBDFileMessage) {
                if delegate.responds(to: #selector(GroupChannelMessageTableViewCellDelegate.didLongClickGeneralFileMessage(_:))) {
                    delegate.didLongClickGeneralFileMessage!(msg)
                }
            }
        }
    }
    
    @objc func clickResendImageFileMessage(_ sender: AnyObject) {
        // TODO:
    }
    
    @objc func clickAudioFileMessage(_ recognizer: UITapGestureRecognizer) {
        if let msg = (self.msg as? SBDFileMessage), msg.type.hasPrefix("audio") {
            if let delegate = self.delegate {
                if delegate.responds(to: #selector(GroupChannelMessageTableViewCellDelegate.didClickAudioFileMessage(_:))) {
                    delegate.didClickAudioFileMessage!(msg)
                }
            }
        }
    }
    
    @objc func clickResendAudioMessage(_ sender: AnyObject) {
        if let delegate = self.delegate, let msg = (self.msg as? SBDFileMessage)  {
            if delegate.responds(to: #selector(GroupChannelMessageTableViewCellDelegate.didClickResendAudioGeneralFileMessage(_:))) {
                delegate.didClickResendAudioGeneralFileMessage!(msg)
            }
        }
    }
}
