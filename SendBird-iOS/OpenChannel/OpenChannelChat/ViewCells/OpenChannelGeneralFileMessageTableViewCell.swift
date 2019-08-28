//
//  OpenChannelGeneralFileMessageTableViewCell.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 10/18/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK

class OpenChannelGeneralFileMessageTableViewCell: OpenChannelMessageTableViewCell {
    
    @IBOutlet weak var nicknameContainerView: UIView!

    @IBOutlet weak var filenameLabel: UILabel!
    
    @IBOutlet weak var fileTransferProgressViewContainerView: UIView!
    @IBOutlet weak var fileTransferProgressCircleView: CustomProgressCircle!
    @IBOutlet weak var fileTransferProgressLabel: UILabel!
    @IBOutlet weak var sendingFailureContainerView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setMessage(_ message: SBDFileMessage) {
        self.msg = message
        
        let clickMessageGesture = UITapGestureRecognizer(target: self, action: #selector(self.clickMessage))
        self.messageContainerView.addGestureRecognizer(clickMessageGesture)
        
        let longClickMessageGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.longClickMessage(_:)))
        self.messageContainerView.addGestureRecognizer(longClickMessageGesture)
        
        let filename = NSAttributedString(string: message.name, attributes: [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0, weight: .medium),
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue,
            NSAttributedString.Key.foregroundColor: UIColor(named: "color_open_channel_file_message_text") as Any
            ])
        self.filenameLabel.attributedText = filename
        
        super.setMessage(message)
    }
    
    func showProgress(_ progress: CGFloat) {
        self.fileTransferProgressViewContainerView.isHidden = false
        self.sendingFailureContainerView.isHidden = true
        self.fileTransferProgressCircleView.drawCircle(progress: progress)
        self.fileTransferProgressLabel.text = String(format: "%.2lf%%", progress * 100.0)
    }
    
    func hideProgress() {
        self.fileTransferProgressViewContainerView.isHidden = true
        self.sendingFailureContainerView.isHidden = true
    }
    
    func hideElementsForFailure() {
        self.fileTransferProgressViewContainerView.isHidden = true
        self.resendButtonContainerView.isHidden = true
        self.resendButton.isEnabled = false
        self.sendingFailureContainerView.isHidden = true
    }
    
    func showElementsForFailure() {
        self.fileTransferProgressViewContainerView.isHidden = true
        self.resendButtonContainerView.isHidden = false
        self.resendButton.isEnabled = true
        self.sendingFailureContainerView.isHidden = false
    }
    
    @objc func clickMessage() {
        if let delegate = self.delegate, let msg = (self.msg as? SBDFileMessage) {
            if delegate.responds(to: #selector(OpenChannelMessageTableViewCellDelegate.didClickGeneralFileMessage(_:))) {
                delegate.didClickGeneralFileMessage!(msg)
            }
        }
    }
    
    @objc func longClickMessage(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            if let delegate = self.delegate, let msg = (self.msg as? SBDFileMessage) {
                if delegate.responds(to: #selector(OpenChannelMessageTableViewCellDelegate.didLongClickFileMessage(_:))) {
                    delegate.didLongClickFileMessage!(msg)
                }
            }
        }
    }
}
