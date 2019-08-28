//
//  OpenChannelMessageTableViewCellDelegate.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 10/18/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import Foundation
import SendBirdSDK

@objc protocol OpenChannelMessageTableViewCellDelegate: NSObjectProtocol {
    @objc optional func didClickUserProfile(_ user: SBDUser)
    @objc optional func didLongClickUserProfile(_ user: SBDUser)
    
    @objc optional func didClickResendUserMessageButton(_ message: SBDUserMessage)
    @objc optional func didClickResendImageFileMessageButton(_ message: SBDFileMessage)
    @objc optional func didClickResendGeneralFileMessageButton(_ message: SBDFileMessage)
    
    @objc optional func didClickImageVideoFileMessage(_ message: SBDFileMessage)
    @objc optional func didClickGeneralFileMessage(_ message: SBDFileMessage)
    
    @objc optional func didLongClickMessage(_ message: SBDBaseMessage)
    @objc optional func didLongClickFileMessage(_ message: SBDFileMessage)
}
