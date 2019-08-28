//
//  GroupChannelOutgoingImageVideoFileMessageTableViewCell.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 11/6/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import AlamofireImage
import FLAnimatedImage

class GroupChannelOutgoingImageVideoFileMessageTableViewCell: GroupChannelOutgoingMessageTableViewCell {
    var imageHash: Int = 0
    
    private var hideReadCount = false

    @IBOutlet weak var imageFileMessageImageView: FLAnimatedImageView!
  
    @IBOutlet weak var fileTransferProgressViewContainerView: UIView!
    @IBOutlet weak var fileTransferProgressCircleView: CustomProgressCircle!
    @IBOutlet weak var fileTransferProgressLabel: UILabel!
  
    @IBOutlet weak var videoPlayIconImageView: UIImageView!
    @IBOutlet weak var imageMessagePlaceholderImageView: UIImageView!
    @IBOutlet weak var videoMessagePlaceholderImageView: UIImageView!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.messageCellType = .imageVideo
        
        let clickMessageContainteGesture = UITapGestureRecognizer(target: self, action: #selector(GroupChannelOutgoingImageVideoFileMessageTableViewCell.clickImageVideoFileMessage(_:)))
        self.messageContainerView.addGestureRecognizer(clickMessageContainteGesture)
        
        let longClickMessageContainerGesture = UILongPressGestureRecognizer(target: self, action: #selector(GroupChannelOutgoingImageVideoFileMessageTableViewCell.longClickImageVideoFileMessage(_:)))
        self.messageContainerView.addGestureRecognizer(longClickMessageContainerGesture)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    func setMessage(currMessage: SBDFileMessage, prevMessage: SBDBaseMessage?, nextMessage: SBDBaseMessage?, failed: Bool) {

        self.msg = currMessage
        
        self.resendButton.addTarget(self, action: #selector(GroupChannelOutgoingImageVideoFileMessageTableViewCell.clickResendImageVideoFileMessage(_:)), for: .touchUpInside)
        
        super.setMessage(currMessage: currMessage, prevMessage: prevMessage, nextMessage: nextMessage, failed: failed)
    }
    
    func showProgress(_ progress: CGFloat) {
        self.fileTransferProgressViewContainerView.isHidden = false
        self.sendingFailureContainerView.isHidden = true
        self.readStatusContainerView.isHidden = true
        self.fileTransferProgressCircleView.drawCircle(progress: progress)
        self.fileTransferProgressLabel.text = String(format: "%.2lf%%", progress * 100.0)
    }
    
    func hideProgress() {
        self.fileTransferProgressViewContainerView.isHidden = true
        self.sendingFailureContainerView.isHidden = true
    }

    override func hideFailureElement() {
        self.fileTransferProgressViewContainerView.isHidden = true
        super.hideFailureElement()
    }
    
    override func showFailureElement(){
        self.fileTransferProgressViewContainerView.isHidden = false
        self.bringSubviewToFront(self.sendingFailureContainerView)
        self.messageDateLabel.isHidden = true
        super.showFailureElement()
    }
    
    override func showReadStatus(readCount: Int) {
        self.messageDateLabel.isHidden = false
        super.showReadStatus(readCount: readCount)
    }
    
    func showBottomMargin() {
        self.messageContainerViewBottomMargin.constant = GroupChannelOutgoingImageVideoFileMessageTableViewCell.kMessageContainerViewBottomMarginNormal
    }
    
    func hideBottomMargin() {
        self.messageContainerViewBottomMargin.constant = 0
    }
    
    func hideAllPlaceholders() {
        self.videoPlayIconImageView.isHidden = true
        self.imageMessagePlaceholderImageView.isHidden = true
        self.videoMessagePlaceholderImageView.isHidden = true
    }
    
    @objc func clickImageVideoFileMessage(_ recognizer: UITapGestureRecognizer) {
        if let delegate = self.delegate, let msg = (self.msg as? SBDFileMessage) {
            if delegate.responds(to: #selector(GroupChannelMessageTableViewCellDelegate.didClickImageVideoFileMessage(_:))) {
                delegate.didClickImageVideoFileMessage!(msg)
            }
        }
    }
    
    @objc func longClickImageVideoFileMessage(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            if let delegate = self.delegate, let msg = (self.msg as? SBDFileMessage) {
                if delegate.responds(to: #selector(GroupChannelMessageTableViewCellDelegate.didLongClickImageVideoFileMessage(_:))) {
                    delegate.didLongClickImageVideoFileMessage!(msg)
                }
            }
        }
    }
    
    @objc func clickResendImageVideoFileMessage(_ sender: AnyObject) {
        if let delegate = self.delegate, let msg = (self.msg as? SBDFileMessage) {
            if delegate.responds(to: #selector(GroupChannelMessageTableViewCellDelegate.didClickResendImageVideoFileMessage(_:))) {
                delegate.didClickResendImageVideoFileMessage!(msg)
            }
        }
    }
    
    func setAnimatedImage(_ image: FLAnimatedImage?, hash: Int) {
        if image == nil || hash == 0 {
            self.imageHash = 0
            self.imageFileMessageImageView.animatedImage = nil
        }
        else {
            if self.imageHash == 0 || self.imageHash != hash {
                self.imageFileMessageImageView.image = nil
                self.imageFileMessageImageView.animatedImage = image
                self.imageHash = hash
            }
        }
    }
    
    func setImage(_ image: UIImage?) {
        if image == nil || hash == 0 {
            self.imageHash = 0
            self.imageFileMessageImageView.image = nil
        }
        else {
            let newImageHash = image!.jpegData(compressionQuality: 0.5).hashValue
            if self.imageHash == 0 || self.imageHash != hash {
                self.imageFileMessageImageView.animatedImage = nil
                self.imageFileMessageImageView.image = image
                self.imageHash = newImageHash
            }
        }
    }
}
