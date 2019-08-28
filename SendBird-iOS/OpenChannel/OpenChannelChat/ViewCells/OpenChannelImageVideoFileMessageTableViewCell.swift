//
//  OpenChannelImageVideoFileMessageTableViewCell.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 10/18/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import FLAnimatedImage
import AlamofireImage

class OpenChannelImageVideoFileMessageTableViewCell: OpenChannelMessageTableViewCell {
    var imageHash: Int?
    
    @IBOutlet weak var fileImageView: FLAnimatedImageView!
    @IBOutlet weak var imageMessagePlaceholderImageView: UIImageView!
    
    @IBOutlet weak var fileTransferProgressViewContainerView: UIView!
    @IBOutlet weak var fileTransferProgressCircleView: CustomProgressCircle!
    @IBOutlet weak var fileTransferProgressLabel: UILabel!
    @IBOutlet weak var sendingFailureContainerView: UIView!
    
    
    @IBOutlet weak var fileImageViewHeight: NSLayoutConstraint!
    @IBOutlet weak var videoPlayIconImageView: UIImageView!
    @IBOutlet weak var videoMessagePlaceholderImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setMessage(_ message: SBDBaseMessage) {
        let clickMessageContainerGesture = UITapGestureRecognizer(target: self, action: #selector(self.clickImageVideoFileMessage(_:)))
        self.messageContainerView.addGestureRecognizer(clickMessageContainerGesture)
        
        let longClickMessageGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.longClickMessage(_:)))
        self.messageContainerView.addGestureRecognizer(longClickMessageGesture)
        
        
        self.resendButton.addTarget(self, action: #selector(self.clickResendImageFileMessage(_:)), for: .touchUpInside)
        
        super.setMessage(message)
    }
    
  
    
    func showProgress(_ progress: CGFloat) {
        self.fileTransferProgressViewContainerView.isHidden = false
        self.sendingFailureContainerView.isHidden = true
        
        self.fileTransferProgressCircleView.drawCircle(progress: progress)
        self.fileTransferProgressLabel.text = String(format: "%.2lf%%", (progress * 100.0))
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
    
    func hideAllPlaceholders() {
        self.videoPlayIconImageView.isHidden = true
        self.imageMessagePlaceholderImageView.isHidden = true
        self.videoMessagePlaceholderImageView.isHidden = true
    }
    
    @objc func clickResendImageFileMessage(_ sender: AnyObject) {
        if let delegate = self.delegate, let msg = (self.msg as? SBDFileMessage) {
            if delegate.responds(to: #selector(OpenChannelMessageTableViewCellDelegate.didClickResendImageFileMessageButton(_:))) {
                delegate.didClickResendImageFileMessageButton!(msg)
            }
        }
    }
    
    @objc func clickImageVideoFileMessage(_ recognizer: UITapGestureRecognizer) {
        if let delegate = self.delegate, let msg = (self.msg as? SBDFileMessage) {
            if delegate.responds(to: #selector(OpenChannelMessageTableViewCellDelegate.didClickImageVideoFileMessage(_:))) {
                delegate.didClickImageVideoFileMessage!(msg)
            }
        }
    }
    
    
    @objc func longClickMessage(_ recognizer: UILongPressGestureRecognizer) {
        if let delegate = self.delegate, let msg = (self.msg as? SBDFileMessage) {
            if delegate.responds(to: #selector(OpenChannelMessageTableViewCellDelegate.didLongClickFileMessage(_:))) {
                delegate.didLongClickFileMessage!(msg)
            }
        }
    }
    
    func setAnimated(image: FLAnimatedImage?, hash: Int) {
        if image == nil || hash == 0 {
            self.imageHash = 0
            self.fileImageView.animatedImage = nil
            self.fileImageView.image = nil
        }
        else {
            if self.imageHash == 0 || self.imageHash != hash {
                self.fileImageView.image = nil
                self.fileImageView.animatedImage = image
                self.imageHash = hash
            }
        }
    }
    
    func setImage(_ image: UIImage?) {
        if image == nil {
            self.imageHash = 0
            self.fileImageView.animatedImage = nil
            self.fileImageView.image = nil
        }
        else {
            let newImageHash = image!.jpegData(compressionQuality: 0.5).hashValue
            if self.imageHash == 0 || self.imageHash != newImageHash {
                self.fileImageView.animatedImage = nil
                self.fileImageView.image = image
                self.imageHash = newImageHash
            }
        }
    }
    
}
