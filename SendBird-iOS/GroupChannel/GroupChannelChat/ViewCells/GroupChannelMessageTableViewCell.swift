//
//  GroupChannelMessageTableViewCell.swift
//  SendBird-iOS
//
//  Created by Minhyuk Kim on 25/07/2019.
//  Copyright © 2019 SendBird. All rights reserved.
//
import UIKit
import SendBirdSDK

enum MessageCellType {
    case file, audio, imageVideo, user
}

class GroupChannelMessageTableViewCell: UITableViewCell {
    
    weak var delegate: GroupChannelMessageTableViewCellDelegate?
    var msg: SBDBaseMessage?
    var channel: SBDGroupChannel?
    var messageCellType : MessageCellType = .file
    
    static let kDateSeperatorContainerViewHeight: CGFloat = 65.0
    static let kNicknameContainerViewTopMargin: CGFloat = 3.0
    static let kMessageContainerViewTopMarginNormal: CGFloat = 6.0
    static let kMessageContainerViewTopMarginNoNickname: CGFloat = 3.0
    static let kMessageContainerViewBottomMarginNormal: CGFloat = 14.0
    static let kMessageContainerViewTopMarginReduced: CGFloat = 3.0
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func setMessage(currMessage: SBDBaseMessage, prevMessage: SBDBaseMessage?, nextMessage: SBDBaseMessage?, failed: Bool?) {}
    
    static func nib() -> UINib {
        return UINib(nibName: String(describing: self), bundle: Bundle(for: self))
    }
}

extension SBDBaseMessage{
    func getSender() -> SBDSender?{
        if let message = self as? SBDFileMessage{
            return message.sender
        }else if let message = self as? SBDUserMessage{
            return message.sender
        }else{
            return nil
        }
    }
}
