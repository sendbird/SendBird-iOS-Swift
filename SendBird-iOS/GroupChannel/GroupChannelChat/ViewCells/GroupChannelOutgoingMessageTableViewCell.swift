//
//  GroupChannelOutgoingMessageTableViewCell.swift
//  SendBird-iOS
//
//  Created by Minhyuk Kim on 23/07/2019.
//  Copyright © 2019 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK

class GroupChannelOutgoingMessageTableViewCell: GroupChannelMessageTableViewCell {
    
    @IBOutlet weak var dateSeperatorContainerView: UIView!
    @IBOutlet weak var dateSeperatorLabel: UILabel!
    @IBOutlet weak var messageDateLabel: UILabel!
    @IBOutlet weak var messageStatusContainerView: UIView!
    @IBOutlet weak var resendButtonContainerView: UIView!
    @IBOutlet weak var resendButton: UIButton!
    @IBOutlet weak var sendingFailureContainerView: UIView!
    @IBOutlet weak var readStatusContainerView: UIView!
    @IBOutlet weak var readStatusLabel: UILabel!
    @IBOutlet weak var sendingFlagImageView: UIImageView!
    @IBOutlet weak var messageContainerView: UIView!
    
    @IBOutlet var sendingFailureContainerViewConstraint: NSLayoutConstraint!

    @IBOutlet weak var dateSeperatorContainerViewTopMargin: NSLayoutConstraint!
    @IBOutlet weak var dateSeperatorContainerViewHeight: NSLayoutConstraint!
    @IBOutlet weak var messageStatusContainerViewHeight: NSLayoutConstraint!
    @IBOutlet weak var messageContainerViewTopMargin: NSLayoutConstraint!
    @IBOutlet weak var messageContainerViewBottomMargin: NSLayoutConstraint!

    
    static let kDateSeperatorContainerViewTopMargin: CGFloat = 0.0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

  
    override func setMessage(currMessage: SBDBaseMessage, prevMessage: SBDBaseMessage?, nextMessage: SBDBaseMessage?, failed: Bool?) {
        super.setMessage(currMessage: currMessage, prevMessage: prevMessage, nextMessage: nextMessage, failed: failed)

        guard let failed = failed else { return }
        self.resendButton.addTarget(self, action: #selector(GroupChannelOutgoingUserMessageTableViewCell.clickResendUserMessage(_:)), for: .touchUpInside)
        
        var hideDateSeperator = false
        var hideMessageStatus = false
        var decreaseTopMargin = false
        var hideReadCount = false
        
        self.msg = currMessage
        
        let prevMessageSender: SBDSender? = prevMessage?.getSender()
        let nextMessageSender: SBDSender? = nextMessage?.getSender()
        
        guard let sender = self.msg?.getSender() else { return }
        
        if let nextMessage = nextMessage {

            if nextMessageSender?.userId == sender.userId {
                let nextReadCount = self.channel?.getReadMembers(with: nextMessage, includeAllMembers: false).count
                let currReadCount = self.channel?.getReadMembers(with: self.msg!, includeAllMembers: false).count
                
                if nextReadCount == currReadCount {
                    hideReadCount = true
                }
            }
        }
        
        if let prevCreatedAt = prevMessage?.createdAt, let msgCreatedAt = self.msg?.createdAt, Utils.checkDayChangeDayBetweenOldTimestamp(oldTimestamp: prevCreatedAt, newTimestamp: msgCreatedAt) {
            hideDateSeperator = false
        }
        else {
            hideDateSeperator = true

            if prevMessageSender?.userId == sender.userId {
                decreaseTopMargin = true
            }
        }
        
        
        if nextMessageSender?.userId == sender.userId {
            if Utils.checkDayChangeDayBetweenOldTimestamp(oldTimestamp: (self.msg?.createdAt)!, newTimestamp: (nextMessage?.createdAt)!) {
                hideMessageStatus = false
            }
            else {
                hideMessageStatus = true
            }
        }
        else {
            hideMessageStatus = false
        }
        
        if hideDateSeperator {
            self.dateSeperatorContainerView.isHidden = true
            self.dateSeperatorContainerViewHeight.constant = 0
            self.dateSeperatorContainerViewTopMargin.constant = 0
        }
        else {
            self.dateSeperatorContainerView.isHidden = false
            self.dateSeperatorLabel.text = Utils.getDateStringForDateSeperatorFromTimestamp((self.msg?.createdAt)!)
            self.dateSeperatorContainerViewHeight.constant = GroupChannelOutgoingUserMessageTableViewCell.kDateSeperatorContainerViewHeight
            self.dateSeperatorContainerViewTopMargin.constant = GroupChannelOutgoingUserMessageTableViewCell.kDateSeperatorContainerViewTopMargin
        }
        
        if decreaseTopMargin {
            self.messageContainerViewTopMargin.constant = GroupChannelOutgoingUserMessageTableViewCell.kMessageContainerViewTopMarginReduced
        }
        else {
            self.messageContainerViewTopMargin.constant = GroupChannelOutgoingUserMessageTableViewCell.kMessageContainerViewTopMarginNormal
        }
        if hideMessageStatus, hideReadCount, !failed {
            self.messageDateLabel.text = ""
            self.messageStatusContainerView.isHidden = true
            self.readStatusContainerView.isHidden = true
            self.resendButtonContainerView.isHidden = true
            self.resendButton.isEnabled = false
            self.sendingFailureContainerView.isHidden = true
            self.sendingFailureContainerViewConstraint.isActive = false

            self.messageContainerViewBottomMargin.constant = 0
        } else{
            self.messageStatusContainerView.isHidden = false
            self.messageContainerViewBottomMargin.constant = GroupChannelOutgoingUserMessageTableViewCell.kMessageContainerViewBottomMarginNormal
            if failed {
                self.messageDateLabel.text = ""
                self.readStatusContainerView.isHidden = true
                self.resendButtonContainerView.isHidden = false
                self.resendButton.isEnabled = true
                self.sendingFailureContainerViewConstraint.isActive = true

                self.sendingFailureContainerView.isHidden = false
                self.sendingFlagImageView.isHidden = true
            } else {
                self.messageDateLabel.text = Utils.getMessageDateStringFromTimestamp((self.msg?.createdAt)!)
                self.readStatusContainerView.isHidden = false
                self.showReadStatus(readCount: (self.channel?.getReadMembers(with: self.msg!, includeAllMembers: false).count)!)
                self.resendButtonContainerView.isHidden = true
                self.resendButton.isEnabled = false
                self.sendingFailureContainerViewConstraint.isActive = false

                self.sendingFailureContainerView.isHidden = true
                self.sendingFlagImageView.isHidden = true
            }
        }
    }
    
    func showReadStatus(readCount: Int) {
        self.sendingFlagImageView.isHidden = true
        self.readStatusContainerView.isHidden = false
        self.readStatusLabel.text = String(format: "Read %lu ∙", readCount)
    }
    
    func hideReadStatus() {
        self.sendingFlagImageView.isHidden = true
        self.readStatusContainerView.isHidden = true
    }

    func hideFailureElement(){
        self.resendButtonContainerView.isHidden = true
        self.resendButton.isEnabled = false
        self.sendingFailureContainerView.isHidden = true
    }
    
    func showFailureElement(){
        self.resendButtonContainerView.isHidden = false
        self.resendButton.isEnabled = true
        self.sendingFailureContainerView.isHidden = false
    }
}
