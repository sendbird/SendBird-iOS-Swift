//
//  OpenChannelMessageTableViewCell.swift
//  SendBird-iOS
//
//  Created by Minhyuk Kim on 25/07/2019.
//  Copyright © 2019 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK

class OpenChannelMessageTableViewCell: UITableViewCell {
    
    @IBOutlet weak var profileContainerView: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nicknameLabel: UILabel!
    
    @IBOutlet weak var resendButtonContainerView: UIView!
    @IBOutlet weak var resendButton: UIButton!
    @IBOutlet weak var messageContainerView: UIView!
    @IBOutlet weak var messageContainerViewBottomMargin: NSLayoutConstraint!
    weak var delegate: OpenChannelMessageTableViewCellDelegate?
    var channel: SBDOpenChannel?
    var msg: SBDBaseMessage?
    
    static let kMessageContainerViewBottomMarginNormal: CGFloat = 14.0
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    static func nib() -> UINib {
        return UINib(nibName: String(describing: self), bundle: Bundle(for: self))
    }
    
    func setMessage(_ message: SBDBaseMessage) {
        self.msg = message
       
        let longClickProfileGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.longClickProfile(_:)))
        self.profileContainerView.addGestureRecognizer(longClickProfileGesture)
        
        let clickProfileGesture = UITapGestureRecognizer(target: self, action: #selector(self.clickProfile(_:)))
        self.profileContainerView.addGestureRecognizer(clickProfileGesture)
        
        if let sender = (self.msg as? SBDFileMessage)?.sender {
            if sender.nickname?.count == 0 {
                self.nicknameLabel.text = ""
            }
            else {
                self.nicknameLabel.text = sender.nickname
            }
        } else if let sender = (self.msg as? SBDUserMessage)?.sender {
            if sender.nickname?.count == 0 {
                self.nicknameLabel.text = ""
            }
            else {
                self.nicknameLabel.text = sender.nickname
            }
        }
    }
    
    func getMessage() -> SBDBaseMessage? {
        return self.msg
    }

    func showBottomMargin() {
        self.messageContainerViewBottomMargin.constant = OpenChannelImageVideoFileMessageTableViewCell.kMessageContainerViewBottomMarginNormal
    }
    
    func hideBottomMargin() {
        self.messageContainerViewBottomMargin.constant = 0
    }
    
    @objc func longClickProfile(_ recognizer: UILongPressGestureRecognizer) {
        if let delegate = self.delegate {
            if delegate.responds(to: #selector(OpenChannelMessageTableViewCellDelegate.didLongClickUserProfile(_:))) {
                if let sender = (self.msg as? SBDFileMessage)?.sender {
                    delegate.didLongClickUserProfile!(sender)
                } else if let sender = (self.msg as? SBDUserMessage)?.sender {
                    delegate.didLongClickUserProfile!(sender)
                }
            }
        }
    }
    
    @objc func clickProfile(_ recognizer: UITapGestureRecognizer) {
        if let delegate = self.delegate {
            if delegate.responds(to: #selector(OpenChannelMessageTableViewCellDelegate.didClickUserProfile(_:))) {
                if let sender = (self.msg as? SBDFileMessage)?.sender {
                    delegate.didClickUserProfile!(sender)
                } else if let sender = (self.msg as? SBDUserMessage)?.sender {
                    delegate.didClickUserProfile!(sender)
                }
            }
        }
    }
}
