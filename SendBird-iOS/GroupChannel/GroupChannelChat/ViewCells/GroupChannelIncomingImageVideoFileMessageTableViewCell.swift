//
//  GroupChannelIncomingImageVideoFileMessageTableViewCell.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 11/6/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import FLAnimatedImage

class GroupChannelIncomingImageVideoFileMessageTableViewCell: GroupChannelIncomingMessageTableViewCell {
    var imageHash: Int = 0
    
    @IBOutlet weak var imageFileMessageImageView: FLAnimatedImageView!
    @IBOutlet weak var videoPlayIconImageView: UIImageView!
    @IBOutlet weak var imageMessagePlaceholderImageView: UIImageView!
    @IBOutlet weak var videoMessagePlaceholderImageView: UIImageView!
    
    override func awakeFromNib() {
        self.messageCellType = .imageVideo
        
        super.awakeFromNib()
        
        let clickMessageContainteGesture = UITapGestureRecognizer(target: self, action: #selector(GroupChannelIncomingImageVideoFileMessageTableViewCell.clickImageVideoFileMessage(_:)))
        self.messageContainerView.addGestureRecognizer(clickMessageContainteGesture)
        
        let longClickMessageContainerGesture = UILongPressGestureRecognizer(target: self, action: #selector(GroupChannelIncomingImageVideoFileMessageTableViewCell.longClickImageVideoFileMessage(_:)))
        self.messageContainerView.addGestureRecognizer(longClickMessageContainerGesture)
        
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func hideAllPlaceholders() {
        self.videoPlayIconImageView.isHidden = true
        self.imageMessagePlaceholderImageView.isHidden = true
        self.videoMessagePlaceholderImageView.isHidden = true
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
        if image == nil {
            self.imageHash = 0
            self.imageFileMessageImageView.image = nil
        }
        else {
            let newImageHash = image?.jpegData(compressionQuality: 0.5).hashValue
            if self.imageHash == 0 || self.imageHash != newImageHash {
                self.imageFileMessageImageView.animatedImage = nil
                self.imageFileMessageImageView.image = image
                self.imageHash = newImageHash!
            }
        }
    }
    
    @objc func clickImageVideoFileMessage(_ recognizer: UITapGestureRecognizer) {
        if let delegate = self.delegate, let msg = (self.msg as? SBDFileMessage){
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
}
