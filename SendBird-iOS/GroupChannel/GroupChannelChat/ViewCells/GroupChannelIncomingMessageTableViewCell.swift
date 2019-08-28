//
//  GroupChannelIncomingMessageTableViewCell.swift
//  SendBird-iOS
//
//  Created by Minhyuk Kim on 23/07/2019.
//  Copyright © 2019 SendBird. All rights reserved.
//

import UIKit

import UIKit
import SendBirdSDK
import AlamofireImage
import FLAnimatedImage



class GroupChannelIncomingMessageTableViewCell: GroupChannelMessageTableViewCell {

    @IBOutlet weak var dateSeperatorContainerView: UIView!
    @IBOutlet weak var dateSeperatorLabel: UILabel!
    @IBOutlet weak var profileContainerView: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var messageDateLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var messageStatusContainerView: UIView!
    @IBOutlet weak var messageContainerView: UIView!
    
    @IBOutlet weak var dateSeperatorContainerViewTopMargin: NSLayoutConstraint!
    @IBOutlet weak var dateSeperatorContainerViewHeight: NSLayoutConstraint!
    @IBOutlet weak var nicknameContainerViewTopMargin: NSLayoutConstraint!
    @IBOutlet weak var messageStatusContainerViewHeight: NSLayoutConstraint!
    @IBOutlet weak var messageContainerViewTopMargin: NSLayoutConstraint!
    @IBOutlet weak var messageContainerViewBottomMargin: NSLayoutConstraint!
    
    static let kDateSeperatorContainerViewTopMargin: CGFloat = 3.0

    override func awakeFromNib() {
        super.awakeFromNib()

        let longClickProfileGesture = UILongPressGestureRecognizer(target: self, action: #selector(GroupChannelIncomingMessageTableViewCell.longClickProfile(_:)))
        self.profileContainerView.addGestureRecognizer(longClickProfileGesture)

        let clickProfileGesture = UITapGestureRecognizer(target: self, action: #selector(GroupChannelIncomingMessageTableViewCell.clickProfile(_:)))
        self.profileContainerView.addGestureRecognizer(clickProfileGesture)
        // Initialization code
    }

    func setMessage(currMessage: SBDBaseMessage, prevMessage: SBDBaseMessage?, nextMessage: SBDBaseMessage?) {
        var hideDateSeperator = false
        var hideProfileImage = false
        
        self.msg = currMessage
        
        let prevMessageSender = prevMessage?.getSender()
        let nextMessageSender = nextMessage?.getSender()
        guard let sender = currMessage.getSender() else { return }
        
        if let prevCreatedAt = prevMessage?.createdAt, let msgCreatedAt = self.msg?.createdAt, Utils.checkDayChangeDayBetweenOldTimestamp(oldTimestamp: prevCreatedAt, newTimestamp: msgCreatedAt) {
            self.dateSeperatorContainerView.isHidden = false
            self.dateSeperatorLabel.text = Utils.getDateStringForDateSeperatorFromTimestamp((self.msg?.createdAt)!)
            self.dateSeperatorContainerViewHeight.constant = GroupChannelIncomingAudioFileMessageTableViewCell.kDateSeperatorContainerViewHeight
            self.dateSeperatorContainerViewTopMargin.constant = GroupChannelIncomingAudioFileMessageTableViewCell.kDateSeperatorContainerViewTopMargin
            self.nicknameContainerViewTopMargin.constant = GroupChannelIncomingAudioFileMessageTableViewCell.kNicknameContainerViewTopMargin
            hideDateSeperator = false
        }
        else {
            self.dateSeperatorContainerView.isHidden = true
            self.dateSeperatorLabel.text = ""
            self.dateSeperatorContainerViewHeight.constant = 0
            self.dateSeperatorContainerViewTopMargin.constant = 0
            self.nicknameContainerViewTopMargin.constant = 0
            hideDateSeperator = true
        }
        
        if prevMessageSender?.userId == sender.userId, hideDateSeperator{
            self.nicknameLabel.text = ""
            self.nicknameContainerViewTopMargin.constant = 0
            self.messageContainerViewTopMargin.constant = GroupChannelIncomingAudioFileMessageTableViewCell.kMessageContainerViewTopMarginNoNickname
        }
        else {
            if sender.nickname?.count == 0 {
                self.nicknameLabel.text = " "
            }
            else {
                self.nicknameLabel.text = sender.nickname
            }
            
            self.nicknameContainerViewTopMargin.constant = GroupChannelIncomingAudioFileMessageTableViewCell.kNicknameContainerViewTopMargin
            self.messageContainerViewTopMargin.constant = GroupChannelIncomingAudioFileMessageTableViewCell.kMessageContainerViewTopMarginNormal
        }
        
        if nextMessageSender?.userId == sender.userId {
            if Utils.checkDayChangeDayBetweenOldTimestamp(oldTimestamp: self.msg!.createdAt, newTimestamp: nextMessage!.createdAt) {
                hideProfileImage = false
            }
            else {
                hideProfileImage = true
            }
        }
        else {
            hideProfileImage = false
        }
        
        if hideProfileImage {
            self.messageDateLabel.text = ""
            self.profileContainerView.isHidden = true
            self.messageStatusContainerView.isHidden = true
            self.messageContainerViewBottomMargin.constant = 0
        }
        else {
            self.messageDateLabel.text = Utils.getMessageDateStringFromTimestamp((self.msg?.createdAt)!)
            self.profileContainerView.isHidden = false
            self.messageStatusContainerView.isHidden = false
            self.messageContainerViewBottomMargin.constant = GroupChannelIncomingAudioFileMessageTableViewCell.kMessageContainerViewBottomMarginNormal
        }

    }
        
    override func setMessage(currMessage: SBDBaseMessage, prevMessage: SBDBaseMessage?, nextMessage: SBDBaseMessage?, failed: Bool?) {
        self.setMessage(currMessage: currMessage, prevMessage: prevMessage, nextMessage: nextMessage)
    }
   
    @objc func longClickProfile(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            if let delegate = self.delegate {
                if delegate.responds(to: #selector(GroupChannelMessageTableViewCellDelegate.didLongClickUserProfile(_:))) {
                    if let sender = self.msg?.getSender() {
                        delegate.didLongClickUserProfile!(sender)
                    }
                }
            }
        }
    }

    @objc func clickProfile(_ recognizer: UILongPressGestureRecognizer) {
        if let delegate = self.delegate {
            if delegate.responds(to: #selector(GroupChannelMessageTableViewCellDelegate.didClickUserProfile(_:))) {
                if let sender = self.msg?.getSender(){
                    delegate.didClickUserProfile!(sender)
                }
            }
        }
    }
    
    func configureCell(message: SBDBaseMessage, prevMessage: SBDBaseMessage?, nextMessage: SBDBaseMessage?, sender: GroupChannelMessageTableViewCellDelegate){
        self.delegate = sender
        self.setMessage(currMessage: message, prevMessage: prevMessage, nextMessage: nextMessage)
    }
}
