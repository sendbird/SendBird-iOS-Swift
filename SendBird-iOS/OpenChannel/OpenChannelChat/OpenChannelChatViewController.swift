//
//  OpenChannelChatViewController.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 10/18/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import RSKImageCropper
import Photos
import AVKit
import MobileCoreServices
import AlamofireImage
import FLAnimatedImage

class OpenChannelChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, OpenChannelMessageTableViewCellDelegate, SBDChannelDelegate, SBDNetworkDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, RSKImageCropViewControllerDelegate, OpenChannelSettingsDelegate, UIDocumentPickerDelegate, NotificationDelegate {
    
    @IBOutlet weak var inputMessageTextField: UITextField!
    @IBOutlet weak var messageTableView: UITableView!
    @IBOutlet weak var inputMessageInnerContainerViewBottomMargin: NSLayoutConstraint!
    @IBOutlet weak var loadingIndicatorView: CustomActivityIndicatorView!
    
    @IBOutlet weak var toastView: UIView!
    @IBOutlet weak var toastMessageLabel: UILabel!
    @IBOutlet weak var sendUserMessageButton: UIButton!
    @IBOutlet weak var sendFileMessageButton: UIButton!
    
    weak var delegate: OpenChanannelChatDelegate?
    weak var createChannelDelegate: CreateOpenChannelDelegate?
    
    var channel: SBDOpenChannel?
    
    var keyboardShown: Bool = false
    var keyboardHeight: CGFloat = 0
    var firstKeyboardShown: Bool = true
    
    var initialLoading: Bool = true
    var stopMeasuringVelocity: Bool = false
    var lastMessageHeight: CGFloat = 0
    var scrollLock: Bool = false
    var lastOffset: CGPoint = CGPoint(x: 0, y: 0)
    var lastOffsetCapture: TimeInterval = 0
    var isScrollingFast: Bool = false
    
    var hasPrevious: Bool?
    var minMessageTimestamp: Int64 = Int64.max
    var isLoading: Bool = false
    
    var messages: [SBDBaseMessage] = []
    
    var resendableMessages: [String:SBDBaseMessage] = [:]
    var preSendMessages: [String:SBDBaseMessage] = [:]
    var preSendFileData: [String:[String:AnyObject]] = [:]
    var resendableFileData: [String:[String:AnyObject]] = [:]
    var fileTransferProgress: [String:CGFloat] = [:]
    
    var selectedMessage: SBDBaseMessage?
    
    var channelUpdated: Bool = false
    
    var sendingImageVideoMessage: [String: Bool] = [:]
    var loadedImageHash: [String:Int] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        SBDMain.add(self, identifier: self.description)
        
        if let channel = self.channel {
            self.title = channel.name
        }
    
        self.navigationItem.largeTitleDisplayMode = .never
        if let navigationController = self.navigationController {
            navigationController.isNavigationBarHidden = false
        }
        
        let settingBarButtonItem = UIBarButtonItem(image: UIImage(named: "img_btn_channel_settings"), style: .plain, target: self, action: #selector(self.clickOpenChannelSettingsButton(_:)))
        self.navigationItem.rightBarButtonItem = settingBarButtonItem
        
        if self.splitViewController?.displayMode != UISplitViewController.DisplayMode.allVisible {
            let backButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.clickBackButton(_:)))
            self.navigationItem.leftBarButtonItem = backButton
        }
        
        self.messageTableView.rowHeight = UITableView.automaticDimension
        self.messageTableView.estimatedRowHeight = 140
        self.messageTableView.delegate = self
        self.messageTableView.dataSource = self
        self.messageTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 14, right: 0)
        
        self.messageTableView.register(OpenChannelAdminMessageTableViewCell.nib(), forCellReuseIdentifier: "OpenChannelAdminMessageTableViewCell")
        self.messageTableView.register(OpenChannelUserMessageTableViewCell.nib(), forCellReuseIdentifier: "OpenChannelUserMessageTableViewCell")
        self.messageTableView.register(OpenChannelImageVideoFileMessageTableViewCell.nib(), forCellReuseIdentifier: "OpenChannelImageVideoFileMessageTableViewCell")
        self.messageTableView.register(OpenChannelGeneralFileMessageTableViewCell.nib(), forCellReuseIdentifier: "OpenChannelGeneralFileMessageTableViewCell")
        self.messageTableView.register(OpenChannelAudioFileMessageTableViewCell.nib(), forCellReuseIdentifier: "OpenChannelAudioFileMessageTableViewCell")
        
        // Input Text Field
        let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 0))
        let rightPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 0))
        self.inputMessageTextField.leftView = leftPaddingView
        self.inputMessageTextField.rightView = rightPaddingView
        self.inputMessageTextField.leftViewMode = .always
        self.inputMessageTextField.rightViewMode = .always
        self.inputMessageTextField.addTarget(self, action: #selector(self.inputMessageTextFieldChanged(_:)), for: .editingChanged)
        self.sendUserMessageButton.isEnabled = false
        
        let messageViewTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard(recognizer:)))
        self.messageTableView.addGestureRecognizer(messageViewTapGestureRecognizer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: UIWindow.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: UIWindow.keyboardWillHideNotification, object: nil)
        
        self.view.bringSubviewToFront(self.loadingIndicatorView)
        self.loadingIndicatorView.isHidden = true
        
        channel?.getMyMutedInfo(completionHandler: { (isMuted, description, startAt, endAt, duration, error) in
            if isMuted {
                self.sendUserMessageButton.isEnabled = false
                self.inputMessageTextField.isEnabled = false
                self.inputMessageTextField.placeholder = "You are muted"
                self.sendFileMessageButton.isEnabled = false
            } else {
                self.sendUserMessageButton.isEnabled = true
                self.inputMessageTextField.isEnabled = true
                self.inputMessageTextField.placeholder = "Type a message.."
                self.sendFileMessageButton.isEnabled = true
            }
        })
        
        self.loadPreviousMessages(initial: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) { 
        if let navigationController = self.navigationController, let topViewController = navigationController.topViewController {
            if navigationController.viewControllers.firstIndex(of: self) == nil {
                if navigationController is CreateOpenChannelNavigationController && !(topViewController is OpenChannelSettingsViewController) {
                    navigationController.dismiss(animated: false, completion: nil)
                    if let delegate = self.createChannelDelegate {
                        if delegate.responds(to: #selector(CreateOpenChannelDelegate.didCreate(_:))) {
                            if let channel = self.channel {
                                delegate.didCreate!(channel)
                            }
                        }
                    }
                }
                else {
                    super.viewWillDisappear(animated)
                }
                
                if let channel = self.channel, let delegate = self.delegate {
                    channel.exitChannel { (error) in
                        if self.channelUpdated {
                            if delegate.responds(to: #selector(OpenChanannelChatDelegate.didUpdateOpenChannel)) {
                                delegate.didUpdateOpenChannel!()
                            }
                        }
                    }
                }
            }
            else {
                super.viewWillDisappear(animated)
            }
        }
        else {
            super.viewWillDisappear(animated)
        }
    }
    
    func showToast(_ message: String) {
        self.toastView.alpha = 1
        self.toastMessageLabel.text = message
        self.toastView.isHidden = false
        
        UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseIn, animations: {
            self.toastView.alpha = 0
        }) { (finished) in
            self.toastView.isHidden = true
        }
    }
    
    func loadPreviousMessages(initial: Bool) {
        guard let channel = self.channel else { return }
        
        if self.isLoading {
            return
        }
        
        self.isLoading = true
        
        var timestamp: Int64 = 0
        
        if initial {
            self.hasPrevious = true
            timestamp = Int64.max
        }
        else {
            timestamp = self.minMessageTimestamp
        }
        
        if self.hasPrevious == false {
            return
        }
        
        channel.getPreviousMessages(byTimestamp: timestamp, limit: 30, reverse: !initial, messageType: .all, customType: nil, completionHandler: { (msgs, error) in
            if error != nil {
                self.isLoading = false
                
                return
            }
            
            guard let messages = msgs else { return }
            
            if messages.count == 0 {
                self.hasPrevious = false
            }
            
            if initial {
                if messages.count > 0 {
                    DispatchQueue.main.async {
                        self.messages.removeAll()
                        
                        for message in messages {
                            self.messages.append(message)
                            
                            if self.minMessageTimestamp > message.createdAt {
                                self.minMessageTimestamp = message.createdAt
                            }
                        }
                        
                        self.initialLoading = true
                        
                        self.messageTableView.reloadData()
                        self.messageTableView.layoutIfNeeded()
                        
                        self.scrollToBottom(force: true)
                        self.initialLoading = false
                        self.isLoading = false
                    }
                }
            }
            else {
                if messages.count > 0 {
                    DispatchQueue.main.async {
                        var messageIndexPaths: [IndexPath] = []
                        var row: Int = 0
                        for message in messages {
                            self.messages.insert(message, at: 0)
                            
                            if self.minMessageTimestamp > message.createdAt {
                                self.minMessageTimestamp = message.createdAt
                            }
                            
                            messageIndexPaths.append(IndexPath(row: row, section: 0))
                            row += 1
                        }
                        
                        self.messageTableView.reloadData()
                        self.messageTableView.layoutIfNeeded()
                        
                        self.messageTableView.scrollToRow(at: IndexPath(row: messages.count-1, section: 0), at: .top, animated: false)
                        self.isLoading = false
                    }
                }
            }
        })
    }
    
    // MARK: - NotificationDelegate
    func openChat(_ channelUrl: String) {
        guard let channel = self.channel  else { return }
        guard let navigationController = self.navigationController else { return }
        
        if channelUrl == channel.channelUrl {
            return
        }
        
        navigationController.popViewController(animated: false)
        if let cvc = UIViewController.currentViewController() {
            if cvc is OpenChannelsViewController {
                (cvc as! OpenChannelsViewController).openChat(channelUrl)
            }
            else if cvc is CreateOpenChannelViewControllerB {
                (cvc as! CreateOpenChannelViewControllerB).openChat(channelUrl)
            }
        }
    }
    
    // MARK: - Keyboard
    func determineScrollLock() {
        if self.messages.count > 0 {
            if let indexPaths = self.messageTableView.indexPathsForVisibleRows {
                if let lastVisibleCellIndexPath = indexPaths.last {
                    let lastVisibleRow = lastVisibleCellIndexPath.row
                    if lastVisibleRow != self.messages.count - 1 {
                        self.scrollLock = true
                    }
                    else {
                        self.scrollLock = false
                    }
                }
            }
        }
    }
    
    @objc func hideKeyboard(recognizer: UITapGestureRecognizer) {
        if recognizer.state == .ended {
            self.firstKeyboardShown = false
            self.view.endEditing(false)
        }
    }
    @objc func keyboardWillShow(_ notification: Notification) {
        self.determineScrollLock()
        
        if self.firstKeyboardShown == false {
            self.keyboardShown = true
        }
        self.firstKeyboardShown = false
        
        let (height, duration, _) = Utils.getKeyboardAnimationOptions(notification: notification)
        
        self.keyboardHeight = height ?? 0
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: duration ?? 0, delay: 0, options: .curveEaseOut, animations: {
                self.inputMessageInnerContainerViewBottomMargin.constant = self.keyboardHeight - self.view.safeAreaInsets.bottom
                self.view.layoutIfNeeded()
            }, completion: nil)
            
            self.stopMeasuringVelocity = true
            self.scrollToBottom(force: false)
            self.keyboardShown = true
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        self.keyboardShown = false
        self.keyboardHeight = 0
        
        let (_, duration, _) = Utils.getKeyboardAnimationOptions(notification: notification)

        DispatchQueue.main.async {
            UIView.animate(withDuration: duration ?? 0, delay: 0, options: .curveEaseOut, animations: {
                self.inputMessageInnerContainerViewBottomMargin.constant = 0
                self.view.layoutIfNeeded()
            }, completion: nil)
            self.scrollToBottom(force: false)
        }
    }
    
    func hideKeyboardWhenFastScrolling() {
        if self.keyboardShown == false {
            return
        }

//        DispatchQueue.main.async {
//            UIView.animate(withDuration: 0.1, animations: {
//                self.inputMessageInnerContainerViewBottomMargin.constant = 0
//                self.view.layoutIfNeeded()
//            })
//            self.scrollToBottom(force: false)
//        }
        self.view.endEditing(true)
        self.firstKeyboardShown = false
    }

    @IBAction func clickSendUserMessageButton(_ sender: Any) {
        guard let messageText = self.inputMessageTextField.text else { return }
        guard let channel = self.channel else { return }
        
        self.inputMessageTextField.text = ""
        self.sendUserMessageButton.isEnabled = false
        
        if messageText.count == 0 {
            return
        }
        
        var preSendMessage: SBDUserMessage?
        preSendMessage = channel.sendUserMessage(messageText) { (userMessage, error) in
            
            if error != nil {
                DispatchQueue.main.async {
                    guard let preSendMsg = preSendMessage else { return }
                    let requestId = preSendMsg.requestId
                    
                    self.preSendMessages.removeValue(forKey: requestId)
                    self.resendableMessages[requestId] = preSendMsg
                    self.messageTableView.reloadData()
                    self.scrollToBottom(force: false)
                }
                
                return
            }
            
            guard let message = userMessage else { return }
            let requestId = message.requestId
            guard requestId != "" else { return }

            DispatchQueue.main.async {
                self.determineScrollLock()
                
                if let preSendMessage = self.preSendMessages[requestId] {
                    if let index = self.messages.firstIndex(of: preSendMessage) {
                        self.messages[index] = message
                        self.preSendMessages.removeValue(forKey: requestId)
                        self.messageTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                        self.scrollToBottom(force: false)
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            self.determineScrollLock()
            if let preSendMsg = preSendMessage, let requestId = preSendMessage?.requestId {
                self.preSendMessages[requestId] = preSendMsg
                self.messages.append(preSendMsg)
                self.messageTableView.reloadData()
                self.scrollToBottom(force: false)
            }
        }
    }
    
    @IBAction func clickSendFileMessageButton(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.modalPresentationStyle = .popover
        let actionPhoto = UIAlertAction(title: "Take Photo...", style: .default) { (action) in
            DispatchQueue.main.async {
                let mediaUI = UIImagePickerController()
                mediaUI.sourceType = UIImagePickerController.SourceType.camera
                let mediaTypes = [String(kUTTypeImage)]
                mediaUI.mediaTypes = mediaTypes
                mediaUI.delegate = self
                self.present(mediaUI, animated: true, completion: nil)
            }
        }
        
        let actionVideo = UIAlertAction(title: "Take Video...", style: .default) { (action) in
            DispatchQueue.main.async {
                let mediaUI = UIImagePickerController()
                mediaUI.sourceType = UIImagePickerController.SourceType.camera
                let mediaTypes = [String(kUTTypeMovie)]
                mediaUI.mediaTypes = mediaTypes
                mediaUI.delegate = self
                self.present(mediaUI, animated: true, completion: nil)
            }
        }
        
        let actionFile = UIAlertAction(title: "Browse Files...", style: .default) { (action) in
            DispatchQueue.main.async {
                let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.data"], in: UIDocumentPickerMode.import)
                documentPicker.allowsMultipleSelection = false
                documentPicker.delegate = self
                self.present(documentPicker, animated: true, completion: nil)
            }
        }
        
        let actionLibrary = UIAlertAction(title: "Choose from Library...", style: .default) { (action) in
            DispatchQueue.main.async {
                let mediaUI = UIImagePickerController()
                mediaUI.sourceType = UIImagePickerController.SourceType.photoLibrary
                let mediaTypes = [String(kUTTypeImage), String(kUTTypeMovie)]
                mediaUI.mediaTypes = mediaTypes
                mediaUI.delegate = self
                self.present(mediaUI, animated: true, completion: nil)
            }
        }
        
        let actionCancel = UIAlertAction(title: "Close", style: .cancel, handler: nil)
        
        alert.addAction(actionPhoto)
        alert.addAction(actionVideo)
        alert.addAction(actionFile)
        alert.addAction(actionLibrary)
        alert.addAction(actionCancel)
        
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = self.view
            presenter.sourceRect = CGRect(x: self.view.bounds.minX, y: self.view.bounds.maxY, width: 0, height: 0)
            presenter.permittedArrowDirections = []
        }
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Scroll
    func scrollToBottom(force: Bool) {
        if self.messages.count == 0 {
            return
        }
        
        if self.scrollLock && force == false {
            return
        }
        
        let currentRowNumber = self.messageTableView.numberOfRows(inSection: 0)
        
        self.messageTableView.scrollToRow(at: IndexPath(row: currentRowNumber - 1, section: 0), at: .bottom, animated: false)
    }
    
    func scrollToPosition(_ position: Int) {
        if self.messages.count == 0 {
            return
        }
        
        self.messageTableView.scrollToRow(at: IndexPath(row: position, section: 0), at: .top, animated: false)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowOpenChannelSettings", let destination = segue.destination as? OpenChannelSettingsViewController{
            destination.channel = self.channel
            destination.delegate = self
        }
    }
    
    @objc func clickOpenChannelSettingsButton(_ sender: AnyObject) {
        performSegue(withIdentifier: "ShowOpenChannelSettings", sender: self)
    }
    
    @objc func clickBackButton(_ sender: AnyObject) {
        if self.splitViewController?.displayMode == UISplitViewController.DisplayMode.allVisible {
            return
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell = UITableViewCell()
        
        if self.messages[indexPath.row] is SBDAdminMessage {
            if let adminMessage = self.messages[indexPath.row] as? SBDAdminMessage,
                let adminMessageCell = tableView.dequeueReusableCell(withIdentifier: "OpenChannelAdminMessageTableViewCell") as? OpenChannelAdminMessageTableViewCell {
                adminMessageCell.setMessage(adminMessage)
                adminMessageCell.delegate = self
                if indexPath.row > 0 {
                    adminMessageCell.setPreviousMessage(self.messages[indexPath.row - 1])
                }
                
                cell = adminMessageCell
            }
        }
        else if self.messages[indexPath.row] is SBDUserMessage {
            let userMessage = self.messages[indexPath.row] as! SBDUserMessage
            if let userMessageCell = tableView.dequeueReusableCell(withIdentifier: "OpenChannelUserMessageTableViewCell") as? OpenChannelUserMessageTableViewCell,
                let sender = userMessage.sender {
                userMessageCell.setMessage(userMessage)
                userMessageCell.delegate = self
                
                if sender.userId == SBDMain.getCurrentUser()!.userId {
                    // Outgoing message
                    if userMessage.requestId != "" {
                        if self.resendableMessages[userMessage.requestId] != nil {
                            userMessageCell.showElementsForFailure()
                        }
                        else {
                            userMessageCell.hideElementsForFailure()
                        }
                    }
                }
                else {
                    // Incoming message
                    userMessageCell.hideElementsForFailure()
                }
                
                DispatchQueue.main.async {
                    guard let updateCell = tableView.cellForRow(at: indexPath) else { return }
                    guard let updateUserMessageCell = updateCell as? OpenChannelUserMessageTableViewCell else { return }

                    updateUserMessageCell.profileImageView.setProfileImageView(for: sender)
                }
                
                cell = userMessageCell
            }
        }
        else if let fileMessage = self.messages[indexPath.row] as? SBDFileMessage {
            guard let sender = fileMessage.sender else { return cell }
            guard let currentUser = SBDMain.getCurrentUser() else { return cell }
            let fileMessageRequestId = fileMessage.requestId
            guard fileMessageRequestId != "" else { return cell }
            
            if sender.userId == currentUser.userId, self.preSendMessages[fileMessageRequestId] != nil {
                guard let fileDataDict = self.preSendFileData[fileMessageRequestId] else { return cell }
                // Outgoing & Pre send file message
                if (fileDataDict["type"] as! String).hasPrefix("image") {
                    guard let imageFileMessageCell = tableView.dequeueReusableCell(withIdentifier: "OpenChannelImageVideoFileMessageTableViewCell", for: indexPath) as? OpenChannelImageVideoFileMessageTableViewCell else { return cell }
                    imageFileMessageCell.setMessage(fileMessage)
                    imageFileMessageCell.delegate = nil
                    imageFileMessageCell.hideElementsForFailure()
                    imageFileMessageCell.showBottomMargin()
                    imageFileMessageCell.hideAllPlaceholders()
                    
                    if let progress = self.fileTransferProgress[fileMessageRequestId] {
                        imageFileMessageCell.showProgress(progress)
                    }
                    
                    if (fileDataDict["type"] as! String).hasPrefix("image/gif") {
                        DispatchQueue.main.async {
                            guard let updateCell = tableView.cellForRow(at: indexPath) else { return }
                            guard let updateImageFileMessageCell = updateCell as? OpenChannelImageVideoFileMessageTableViewCell else { return }
                            guard let imageData = fileDataDict["data"] as? Data else { return }
                            
                            updateImageFileMessageCell.profileImageView.setProfileImageView(for: sender)
                            updateImageFileMessageCell.fileImageView.animatedImage = FLAnimatedImage(animatedGIFData: imageData)
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            guard let updateCell = tableView.cellForRow(at: indexPath) else { return }
                            guard let updateImageFileMessageCell = updateCell as? OpenChannelImageVideoFileMessageTableViewCell else { return }
                            guard let imageData = fileDataDict["data"] as? Data else { return }
                            
                            updateImageFileMessageCell.profileImageView.setProfileImageView(for: sender)
                            updateImageFileMessageCell.fileImageView.image = UIImage(data: imageData)
                        }
                    }
                    
                    cell = imageFileMessageCell
                }
                else if (fileDataDict["type"] as! String).hasPrefix("video") {
                    let videoFileMessageCell = tableView.dequeueReusableCell(withIdentifier: "OpenChannelImageVideoFileMessageTableViewCell", for: indexPath) as! OpenChannelImageVideoFileMessageTableViewCell
                    videoFileMessageCell.setMessage(fileMessage)
                    videoFileMessageCell.delegate = nil
                    videoFileMessageCell.hideElementsForFailure()
                    videoFileMessageCell.showBottomMargin()
                    videoFileMessageCell.hideAllPlaceholders()
                    videoFileMessageCell.videoMessagePlaceholderImageView.isHidden = false
                    
                    videoFileMessageCell.fileImageView.image = nil
                    videoFileMessageCell.fileImageView.animatedImage = nil
                    
                    if let progress = self.fileTransferProgress[fileMessageRequestId]  {
                        videoFileMessageCell.showProgress(progress)
                    }
                    
                    DispatchQueue.main.async {
                        guard let updateCell = tableView.cellForRow(at: indexPath) else { return }
                        guard let updateVideoFileMessageCell = updateCell as? OpenChannelImageVideoFileMessageTableViewCell else { return }
                        
                        updateVideoFileMessageCell.profileImageView.setProfileImageView(for: sender)
                    }
                    
                    cell = videoFileMessageCell
                }
                else if (fileDataDict["type"] as! String).hasPrefix("audio") {
                    let audioFileMessageCell = tableView.dequeueReusableCell(withIdentifier: "OpenChannelAudioFileMessageTableViewCell", for: indexPath) as! OpenChannelAudioFileMessageTableViewCell
                    audioFileMessageCell.setMessage(fileMessage)
                    audioFileMessageCell.delegate = nil
                    audioFileMessageCell.hideElementsForFailure()
                    audioFileMessageCell.showBottomMargin()
                    
                    if let progress = self.fileTransferProgress[fileMessageRequestId]  {
                        audioFileMessageCell.showProgress(progress)
                    }
                    
                    DispatchQueue.main.async {
                        guard let updateCell = tableView.cellForRow(at: indexPath) else { return }
                        guard let updateAudioFileMessageCell = updateCell as? OpenChannelAudioFileMessageTableViewCell else { return }
                        
                        updateAudioFileMessageCell.profileImageView.setProfileImageView(for: sender)
                    }
                    
                    cell = audioFileMessageCell
                }
                else {
                    let generalFileMessageCell = tableView.dequeueReusableCell(withIdentifier: "OpenChannelGeneralFileMessageTableViewCell", for: indexPath) as! OpenChannelGeneralFileMessageTableViewCell
                    generalFileMessageCell.setMessage(fileMessage)
                    generalFileMessageCell.delegate = nil
                    generalFileMessageCell.hideElementsForFailure()
                    generalFileMessageCell.showBottomMargin()
                    
                    if let progress = self.fileTransferProgress[fileMessageRequestId]  {
                        generalFileMessageCell.showProgress(progress)
                    }
                    
                    DispatchQueue.main.async {
                        guard let updateCell = tableView.cellForRow(at: indexPath) else { return }
                        guard let updateGeneralFileMessageCell = updateCell as? OpenChannelGeneralFileMessageTableViewCell else { return }
                        updateGeneralFileMessageCell.profileImageView.setProfileImageView(for: sender)
                    }
                    
                    cell = generalFileMessageCell
                }
            }
            else {
                // Sent outgoing & incoming message
                if fileMessage.type.hasPrefix("image") {
                    let imageFileMessageCell = tableView.dequeueReusableCell(withIdentifier: "OpenChannelImageVideoFileMessageTableViewCell", for: indexPath) as! OpenChannelImageVideoFileMessageTableViewCell
                    imageFileMessageCell.delegate = self
                    
                    imageFileMessageCell.hideElementsForFailure()
                    imageFileMessageCell.hideAllPlaceholders()
                    imageFileMessageCell.setMessage(fileMessage)
                    imageFileMessageCell.channel = self.channel
                    imageFileMessageCell.hideProgress()
                    imageFileMessageCell.hideBottomMargin()
                    
                    if let imageHash = self.loadedImageHash[String(fileMessage.messageId)] {
                        if imageHash != imageFileMessageCell.imageHash {
                            imageFileMessageCell.imageMessagePlaceholderImageView.isHidden = false
                            imageFileMessageCell.setImage(nil)
                            imageFileMessageCell.setAnimated(image: nil, hash: 0)
                        }
                    }
                    
                    cell = imageFileMessageCell
                    
                    if fileMessage.type.hasPrefix("image/gif") {
                        if let url = URL(string: fileMessage.url) {
                            imageFileMessageCell.fileImageView.setAnimatedImage(url: url, success: { (image, hash) in
                                DispatchQueue.main.async {
                                    guard let updateCell = tableView.cellForRow(at: indexPath) else { return }
                                    guard let updateImageFileMessageCell = updateCell as? OpenChannelImageVideoFileMessageTableViewCell else { return }
                                    
                                    updateImageFileMessageCell.hideAllPlaceholders()
                                    updateImageFileMessageCell.setAnimated(image: image, hash: hash)
                                    updateImageFileMessageCell.profileImageView.setProfileImageView(for: sender)
                                    self.loadedImageHash[String(fileMessage.messageId)] = hash
                                }
                            }) { (error) in
                                DispatchQueue.main.async {
                                    guard let updateCell = tableView.cellForRow(at: indexPath) else { return }
                                    guard let updateImageFileMessageCell = updateCell as? OpenChannelImageVideoFileMessageTableViewCell else { return }
                                    
                                    updateImageFileMessageCell.hideAllPlaceholders()
                                    updateImageFileMessageCell.imageMessagePlaceholderImageView.isHidden = false
                                    updateImageFileMessageCell.profileImageView.setProfileImageView(for: sender)
                                    updateImageFileMessageCell.setImage(nil)
                                    self.loadedImageHash.removeValue(forKey: String(fileMessage.messageId))
                                }
                            }
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            guard let updateCell = tableView.cellForRow(at: indexPath) else { return }
                            guard let updateImageFileMessageCell = updateCell as? OpenChannelImageVideoFileMessageTableViewCell else { return }
                            
                            if let thumbnails = fileMessage.thumbnails,thumbnails.count > 0 {
                                if let url = URL(string: thumbnails[0].url) {
                                    updateImageFileMessageCell.fileImageView.af_setImage(withURL: url, placeholderImage: nil, filter: nil, progress: nil, progressQueue: DispatchQueue.main, imageTransition: UIImageView.ImageTransition.noTransition, runImageTransitionIfCached: false, completion: { (response) in
                                        updateImageFileMessageCell.hideAllPlaceholders()
                                        updateImageFileMessageCell.profileImageView.setProfileImageView(for: sender)
                                        if response.error != nil {
                                            updateImageFileMessageCell.imageMessagePlaceholderImageView.isHidden = false
                                            updateImageFileMessageCell.setImage(nil)
                                            updateImageFileMessageCell.setAnimated(image: nil, hash: 0)
                                            self.loadedImageHash.removeValue(forKey: String(format: "%lld", fileMessage.messageId))
                                        }
                                    })
                                }
                            } else if let url = URL(string: fileMessage.url) {
                                updateImageFileMessageCell.fileImageView.af_setImage(withURL: url, placeholderImage: nil, filter: nil, progress: nil, progressQueue: DispatchQueue.main, imageTransition: UIImageView.ImageTransition.noTransition, runImageTransitionIfCached: false) { (response) in
                                    if response.error != nil {
                                        updateImageFileMessageCell.imageMessagePlaceholderImageView.isHidden = false
                                        updateImageFileMessageCell.setImage(nil)
                                        updateImageFileMessageCell.setAnimated(image: nil, hash: 0)
                                        self.loadedImageHash.removeValue(forKey: String(format: "%lld", fileMessage.messageId))
                                    } else {
                                        updateImageFileMessageCell.hideAllPlaceholders()
                                        updateImageFileMessageCell.profileImageView.setProfileImageView(for: sender)
                                    }
                                }
                            }
                        }
                    }
                }
                else if fileMessage.type.hasPrefix("video") {
                    let videoFileMessageCell = tableView.dequeueReusableCell(withIdentifier: "OpenChannelImageVideoFileMessageTableViewCell") as! OpenChannelImageVideoFileMessageTableViewCell
                    videoFileMessageCell.delegate = self
                    videoFileMessageCell.hideAllPlaceholders()
                    
                    if videoFileMessageCell.imageHash == 0 || videoFileMessageCell.fileImageView.image == nil {
                        videoFileMessageCell.setAnimated(image: nil, hash: 0)
                        videoFileMessageCell.setImage(nil)
                    }
                    
                    videoFileMessageCell.channel = self.channel
                    videoFileMessageCell.setMessage(fileMessage)
                    videoFileMessageCell.hideProgress()
                    
                    if let imageHash = self.loadedImageHash[String(format: "%lld", fileMessage.messageId)] {
                        let imageHashInt = Int(imageHash)
                        if imageHashInt != videoFileMessageCell.imageHash {
                            videoFileMessageCell.videoMessagePlaceholderImageView.isHidden = false
                            videoFileMessageCell.setImage(nil)
                            videoFileMessageCell.setAnimated(image: nil, hash: 0)
                        }
                    }
                    else {
                        videoFileMessageCell.videoMessagePlaceholderImageView.isHidden = false
                        videoFileMessageCell.setImage(nil)
                        videoFileMessageCell.setAnimated(image: nil, hash: 0)
                    }
                    
                    cell = videoFileMessageCell
                    
                    DispatchQueue.main.async {
                        guard let updateCell = tableView.cellForRow(at: indexPath) else { return }
                        guard let updateVideoFileMessageCell = updateCell as? OpenChannelImageVideoFileMessageTableViewCell else { return }

                        if let thumbnails = fileMessage.thumbnails, thumbnails.count > 0 {
                            if let url = URL(string: thumbnails[0].url) {
                                updateVideoFileMessageCell.fileImageView.af_setImage(withURL: url, placeholderImage: nil, filter: nil, progress: nil, progressQueue: DispatchQueue.main, imageTransition: UIImageView.ImageTransition.noTransition, runImageTransitionIfCached: false, completion: { (response) in
                                    updateVideoFileMessageCell.hideAllPlaceholders()
                                    updateVideoFileMessageCell.videoPlayIconImageView.isHidden = false
                                    
                                    updateVideoFileMessageCell.profileImageView.setProfileImageView(for: sender)
                                    
                                    if response.error != nil {
                                        updateVideoFileMessageCell.imageMessagePlaceholderImageView.isHidden = false
                                        updateVideoFileMessageCell.setImage(nil)
                                        updateVideoFileMessageCell.setAnimated(image: nil, hash: 0)
                                        self.loadedImageHash.removeValue(forKey: String(format: "%lld", fileMessage.messageId))
                                    }
                                })
                            }
                            else {
                                updateVideoFileMessageCell.hideAllPlaceholders()
                                updateVideoFileMessageCell.videoMessagePlaceholderImageView.isHidden = false
                                updateVideoFileMessageCell.setAnimated(image: nil, hash: 0)
                                updateVideoFileMessageCell.setImage(nil)
                                updateVideoFileMessageCell.profileImageView.setProfileImageView(for: sender)
                            }
                        }
                    }
                }
                else if fileMessage.type.hasPrefix("audio") {
                    let audioFileMessageCell = tableView.dequeueReusableCell(withIdentifier: "OpenChannelAudioFileMessageTableViewCell") as! OpenChannelAudioFileMessageTableViewCell
                    audioFileMessageCell.delegate = self
                    audioFileMessageCell.setMessage(fileMessage)
                    audioFileMessageCell.hideElementsForFailure()
                    audioFileMessageCell.hideProgress()
                    audioFileMessageCell.hideBottomMargin()
                    
                    cell = audioFileMessageCell
                    
                    DispatchQueue.main.async {
                        guard let updateCell = tableView.cellForRow(at: indexPath) else { return }
                        guard let updateAudioFileMessageCell = updateCell as? OpenChannelAudioFileMessageTableViewCell else { return }
                        
                        updateAudioFileMessageCell.profileImageView.setProfileImageView(for: sender)
                    }
                }
                else {
                    let generalFileMessageCell = tableView.dequeueReusableCell(withIdentifier: "OpenChannelGeneralFileMessageTableViewCell") as! OpenChannelGeneralFileMessageTableViewCell
                    generalFileMessageCell.delegate = self
                    generalFileMessageCell.setMessage(fileMessage)
                    generalFileMessageCell.hideElementsForFailure()
                    generalFileMessageCell.hideProgress()
                    generalFileMessageCell.hideBottomMargin()
                    
                    cell = generalFileMessageCell
                    
                    DispatchQueue.main.async {
                        guard let updateCell = tableView.cellForRow(at: indexPath) else { return }
                        guard let updateGeneralFileMessageCell = updateCell as? OpenChannelGeneralFileMessageTableViewCell else { return }
                        
                        updateGeneralFileMessageCell.profileImageView.setProfileImageView(for: sender)
                    }
                }
            }
        }
        
        if indexPath.row == 0 && self.messages.count > 0 && self.initialLoading == false && self.isLoading == false {
            self.loadPreviousMessages(initial: false)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    // MARK: - UITableViewDelegate
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.stopMeasuringVelocity = false
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.messageTableView {
            if self.stopMeasuringVelocity == false {
                let currentOffset = scrollView.contentOffset
                let currentTime = Date.timeIntervalSinceReferenceDate
                let timeDiff = currentTime - self.lastOffsetCapture
                if timeDiff > 0.1 {
                    let distance = currentOffset.y - self.lastOffset.y
                    //The multiply by 10, / 1000 isn't really necessary.......
                    let scrollSpeedNotAbs = distance / 100
                    let scrollSpeed = abs(scrollSpeedNotAbs)
                    if scrollSpeed > 1.0 {
                        self.isScrollingFast = true
                    }
                    else {
                        self.isScrollingFast = false
                    }
                    
                    self.lastOffset = currentOffset
                    self.lastOffsetCapture = currentTime
                }
                
                if self.isScrollingFast {
                    self.hideKeyboardWhenFastScrolling()
                }
            }
        }
    }
    
    // MARK: - OpenChannelMessageTableViewCellDelegate
    func didClickResendUserMessageButton(_ message: SBDUserMessage) {
        let messageText = message.message
        if messageText != "" {
            var preSendMessage: SBDUserMessage?
            if let channel = self.channel {
                preSendMessage = channel.sendUserMessage(messageText, completionHandler: { (userMessage, error) in
                    self.inputMessageTextField.text = ""
                    if error != nil {
                        DispatchQueue.main.async {
                            self.resendableMessages.removeValue(forKey: message.requestId)
                            self.preSendMessages.removeValue(forKey: (preSendMessage?.requestId)!)
                            self.resendableMessages[(preSendMessage?.requestId)!] = preSendMessage
                            self.messageTableView.reloadData()
                            self.scrollToBottom(force: false)
                        }
                        
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self.determineScrollLock()
                        self.messages[self.messages.firstIndex(of: self.preSendMessages[(userMessage?.requestId)!]!)!] = userMessage!
                        self.preSendMessages.removeValue(forKey: (preSendMessage?.requestId)!)
                        self.messageTableView.reloadData()
                        self.scrollToBottom(force: false)
                    }
                })
                
                DispatchQueue.main.async {
                    self.messages[self.messages.firstIndex(of: message)!] = preSendMessage!
                    self.resendableMessages.removeValue(forKey: message.requestId)
                    self.determineScrollLock()
                    self.preSendMessages[(preSendMessage?.requestId)!] = preSendMessage!
                    self.messageTableView.reloadData()
                    self.scrollToBottom(force: false)
                }
            }
        }
    }
    
    func didClickResendImageFileMessageButton(_ message: SBDFileMessage) {
        let requestId = message.requestId
        guard requestId != "" else { return }
        guard let fileDataDict = self.resendableFileData[requestId] else { return }
        guard let imageData: Data = fileDataDict["data"] as? Data else { return }
        guard let filename: String = fileDataDict["filename"] as? String else { return }
        guard let mimeType: String = fileDataDict["type"] as? String else { return }
        /***********************************/
        /* Thumbnail is a premium feature. */
        /***********************************/
        let thumbnailSize = SBDThumbnailSize.make(withMaxWidth: 320.0, maxHeight: 320.0)
        
        var preSendMessage: SBDFileMessage?
        if let channel = self.channel {
            let fileMessageParams: SBDFileMessageParams = SBDFileMessageParams.init(file: imageData)!
            fileMessageParams.fileName = filename
            fileMessageParams.mimeType = mimeType
            fileMessageParams.fileSize = UInt(imageData.count)
            fileMessageParams.thumbnailSizes = [thumbnailSize]
            fileMessageParams.data = nil
            fileMessageParams.customType = nil
            preSendMessage = channel.sendFileMessage(with: fileMessageParams, progressHandler: { (bytesSent, totalBytesSent, totalBytesExpectedToSend) in
                DispatchQueue.main.async {
                    guard let requestId = preSendMessage?.requestId else { return }
                    self.fileTransferProgress[requestId] = CGFloat(totalBytesSent) / CGFloat(totalBytesExpectedToSend)
                    for index in stride(from: self.messages.count - 1, to: -1, by: -1) {
                        let baseMessage: SBDBaseMessage = self.messages[index]
                        
                        if baseMessage is SBDFileMessage {
                            guard let fileMessage = baseMessage as? SBDFileMessage else {
                                continue
                            }
                            
                            if fileMessage.requestId == preSendMessage!.requestId {
                                let indexPath = IndexPath(row: index, section: 0)
                                guard let cell = self.messageTableView.cellForRow(at: indexPath) as? OpenChannelImageVideoFileMessageTableViewCell else {
                                    continue
                                }
                                cell.showProgress(self.fileTransferProgress[(preSendMessage?.requestId)!]!)
                            }
                        }
                    }
                }
            }, completionHandler: { (fileMessage, error) in
                DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: 150 * NSEC_PER_MSEC), execute: {
                    DispatchQueue.main.async {
                        if error != nil {
                            if let requestId = preSendMessage?.requestId {
                                self.resendableFileData[requestId] = [
                                    "data": imageData,
                                    "filename": filename,
                                    "type": mimeType,
                                    ] as [String : AnyObject]
                                self.resendableMessages[requestId] = preSendMessage!
                            }
                            
                            let alert = UIAlertController(title: "Error", message: error!.domain, preferredStyle: .alert)
                            let actionCancel = UIAlertAction(title: "Close", style: .cancel, handler: { (action) in
                                self.messages.remove(at: self.messages.firstIndex(of: preSendMessage!)!)
                                self.preSendMessages.removeValue(forKey: (preSendMessage?.requestId)!)
                                self.preSendFileData.removeValue(forKey: (preSendMessage?.requestId)!)
                                self.fileTransferProgress.removeValue(forKey: (preSendMessage?.requestId)!)
                                self.messageTableView.reloadData()
                                self.scrollToBottom(force: false)
                            })
                            alert.modalPresentationStyle = .popover
                            alert.addAction(actionCancel)
                            
                            if let presenter = alert.popoverPresentationController {
                                presenter.sourceView = self.view
                                presenter.sourceRect = CGRect(x: self.view.bounds.minX, y: self.view.bounds.midY, width: 0, height: 0)
                                presenter.permittedArrowDirections = []
                            }
                            
                            DispatchQueue.main.async {
                                self.present(alert, animated: true, completion: nil)
                            }
                            
                            return
                        }
                        
                        DispatchQueue.main.async {
                            if let requestId = preSendMessage?.requestId {
                                self.preSendMessages.removeValue(forKey: requestId)
                                self.preSendFileData.removeValue(forKey: requestId)
                                self.fileTransferProgress.removeValue(forKey: requestId)
                                
                                if let firstIndex = self.messages.firstIndex(of: preSendMessage!) {
                                    self.messages[firstIndex] = fileMessage!
                                }
                                
                                self.determineScrollLock()
                                self.messageTableView.reloadData()
                                self.scrollToBottom(force: false)
                            }
                        }
                    }
                })
            })
            
            DispatchQueue.main.async {
                let requestId = message.requestId
                if requestId != "" {
                    self.resendableFileData.removeValue(forKey: requestId)
                    self.resendableMessages.removeValue(forKey: requestId)
                    
                    self.determineScrollLock()
                    
                    self.preSendFileData[requestId] = [
                        "data": imageData,
                        "type": mimeType,
                        "filename": filename
                        ] as [String : AnyObject]
                    self.messages.append(preSendMessage!)
                    self.messageTableView.reloadData()
                    self.scrollToBottom(force: false)
                }
            }
        }
    }
    
    func didLongClickUserProfile(_ user: SBDUser) {
        guard let currentUser = SBDMain.getCurrentUser() else { return }
        guard let channel = self.channel else { return }
        
        if user.userId == currentUser.userId {
            return
        }
        
        if !channel.isOperator(with: currentUser) {
            return
        }
        
        let alert = UIAlertController(title: user.nickname!, message: nil, preferredStyle: .actionSheet)
        alert.modalPresentationStyle = .popover
        
        let actionBanUser = UIAlertAction(title: "Ban user for 10 minutes", style: .default) { (action) in
            channel.banUser(withUserId: user.userId, seconds: 600, completionHandler: { (error) in
                if error != nil {
                    print(error!)
                    return
                }
            })
        }
        
        let actionMuteUser = UIAlertAction(title: "Mute user", style: .default) { (action) in
            channel.muteUser(withUserId: user.userId, completionHandler: { (error) in
                if error != nil {
                    print(error!)
                    return
                }
            })
        }
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(actionBanUser)
        alert.addAction(actionMuteUser)
        alert.addAction(actionCancel)
        
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = self.view
            presenter.sourceRect = CGRect(x: self.view.bounds.minX, y: self.view.bounds.maxY, width: 0, height: 0)
            presenter.permittedArrowDirections = []
        }
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func didClickUserProfile(_ user: SBDUser) {
        DispatchQueue.main.async {
            let vc = UserProfileViewController.init(nibName: "UserProfileViewController", bundle: nil)
            vc.user = user
            if let navigationController = self.navigationController {
                navigationController.pushViewController(vc, animated: true)
            }
        }
    }
    
    func didLongClickFileMessage(_ message: SBDFileMessage) {
        var alert : UIAlertController?
        var deleteMessageActionTitle = ""
        var saveActionTitle = ""
        
        if message.type.hasPrefix("image") {
            alert = UIAlertController(title: "Image", message: nil, preferredStyle: .actionSheet)
            deleteMessageActionTitle = "Delete image"
            saveActionTitle = "Save image to media library"
        }
        else if message.type.hasPrefix("video") {
            alert = UIAlertController(title: "Video", message: nil, preferredStyle: .actionSheet)
            deleteMessageActionTitle = "Delete video"
            saveActionTitle = "Save video to media library"
        }
        else if message.type.hasPrefix("audio"){
            alert = UIAlertController(title: "Audio", message: nil, preferredStyle: .actionSheet)
            deleteMessageActionTitle = "Delete audio"
            saveActionTitle = "Save File"
        } else {
            alert = UIAlertController(title: "General File", message: nil, preferredStyle: .actionSheet)
            deleteMessageActionTitle = "Delete file"
            saveActionTitle = "Save File"
        }
        
        guard let currentUser = SBDMain.getCurrentUser() else { return }
        guard let sender = message.sender else { return }
        guard let channel = self.channel else { return }
        
        var actionDelete: UIAlertAction?
        if sender.userId == currentUser.userId || channel.isOperator(with: currentUser) {
            actionDelete = UIAlertAction(title: deleteMessageActionTitle, style: .destructive, handler: { (action) in
                channel.delete(message, completionHandler: { (error) in
                    if error != nil {
                        let alert = UIAlertController(title: "Error", message: error!.domain, preferredStyle: .alert)
                        let actionCancel = UIAlertAction(title: "Close", style: .cancel, handler: nil)
                        alert.addAction(actionCancel)
                        DispatchQueue.main.async {
                            self.present(alert, animated: true, completion: nil)
                        }
                        
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self.deleteMessageFromTableView(message.messageId)
                    }
                })
            })
        }
        if let action = actionDelete {
            alert!.addAction(action)
        }
        
        let actionSaveFile = UIAlertAction(title: saveActionTitle, style: .default) { (action) in
            guard let url = URL(string: message.url) else { return }
            if message.type.hasPrefix("image") || message.type.hasPrefix("video") {
                DownloadManager.download(url: url, filename: message.name, mimeType: message.type, addToMediaLibrary: true)
            } else {
                DownloadManager.download(url: url, filename: message.name, mimeType: message.type, addToMediaLibrary: false)
            }
        }
        alert!.addAction(actionSaveFile)
        
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert!.addAction(actionCancel)
        
        DispatchQueue.main.async {
            self.present(alert!, animated: true, completion: nil)
        }
    }

    func didLongClickMessage(_ message: SBDBaseMessage) {
        var alert : UIAlertController?
        var sender: SBDSender?
        var messageText: String?
        
        if let message = message as? SBDAdminMessage {
            alert = UIAlertController(title: message.message, message: nil, preferredStyle: .actionSheet)
            messageText = message.message
        } else if let message = message as? SBDUserMessage {
            alert = UIAlertController(title: message.message, message: nil, preferredStyle: .actionSheet)
            sender = message.sender
            messageText = message.message
        } else {
            return
        }
        
        guard let channel = self.channel else { return }
        guard let currentUser = SBDMain.getCurrentUser() else { return }
        guard messageText != nil else { return }
        
        var actionDelete: UIAlertAction?
        if channel.isOperator(with: currentUser) || sender?.userId == currentUser.userId{
            actionDelete = UIAlertAction(title: "Delete message", style: .destructive, handler: { (action) in
                channel.delete(message, completionHandler: { (error) in
                    if error != nil {
                        let alert = UIAlertController(title: "Error", message: error!.domain, preferredStyle: .alert)
                        let actionCancel = UIAlertAction(title: "Close", style: .cancel, handler: nil)
                        alert.addAction(actionCancel)
                        DispatchQueue.main.async {
                            self.present(alert, animated: true, completion: nil)
                        }
                        
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self.deleteMessageFromTableView(message.messageId)
                    }
                })
            })
            
            
        }
        
        let actionCopy = UIAlertAction(title: "Copy message", style: .default) { (action) in
            let pasteboard = UIPasteboard.general
            pasteboard.string = messageText
            
            self.showToast("Copied")
        }
        alert?.addAction(actionCopy)
        
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert?.addAction(actionCancel)
        
        if let action = actionDelete {
            alert?.addAction(action)
        }
        
        DispatchQueue.main.async {
            self.present(alert!, animated: true, completion: nil)
        }
    }
    
    func didClickImageVideoFileMessage(_ message: SBDFileMessage) {
        if message.type.hasPrefix("image") {
            self.loadingIndicatorView.isHidden = false
            self.loadingIndicatorView.startAnimating()
            let session = URLSession.shared
            let request = URLRequest(url: URL(string: message.url)!)
            
            let task = session.dataTask(with: request) { (data, response, error) in
                if let resp = response as? HTTPURLResponse {
                    if resp.statusCode >= 200 && resp.statusCode < 300 {
                        let photo = PhotoViewer()
                        photo.imageData = data
                        
                        DispatchQueue.main.async {
                            let photosViewController = CustomPhotosViewController(photos: [photo])

                            self.loadingIndicatorView.isHidden = true
                            self.loadingIndicatorView.stopAnimating()
                            
                            self.present(photosViewController, animated: true, completion: nil)
                        }
                    }
                    else {
                        self.loadingIndicatorView.isHidden = true
                        self.loadingIndicatorView.stopAnimating()
                    }
                }
            }
            task.resume()
        }
        else if message.type.hasPrefix("video") {
            if let videoUrl = URL(string: message.url) {
                self.playMedia(videoUrl)
            }
            
            return
        }
    }
    
    func didClickGeneralFileMessage(_ message: SBDFileMessage) {
        if message.type.hasPrefix("audio") {
            if let audioUrl = URL(string: message.url) {
                self.playMedia(audioUrl)
            }
        }
    }
    
    // MARK: - SBDChannelDelegate
    func channel(_ sender: SBDBaseChannel, didReceive message: SBDBaseMessage) {
        if let channel = self.channel {
            if sender == channel {
                DispatchQueue.main.async {
                    self.determineScrollLock()
                    UIView.setAnimationsEnabled(false)
                    self.messages.append(message)
                    self.messageTableView.insertRows(at: [IndexPath(row: self.messages.count - 1, section: 0)], with: .none)
                    self.scrollToBottom(force: false)
                    UIView.setAnimationsEnabled(true)
                }
            }
        }
    }
    
    func channel(_ sender: SBDBaseChannel, userWasMuted user: SBDUser) {
        guard let currentUser = SBDMain.getCurrentUser() else { return }
        guard let channel = self.channel else { return }
        
        if user.userId == currentUser.userId, sender.channelUrl == channel.channelUrl {
            let alert = UIAlertController(title: "You are muted.", message: "You are muted. You won't be able to send messages.", preferredStyle: .alert)
            let actionConfirm = UIAlertAction(title: "Okay", style: .cancel) { (action) in
                self.sendUserMessageButton.isEnabled = false
                self.inputMessageTextField.isEnabled = false
                self.inputMessageTextField.placeholder = "You are muted"
                self.sendFileMessageButton.isEnabled = false
            }
            alert.addAction(actionConfirm)
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func channel(_ sender: SBDBaseChannel, userWasUnmuted user: SBDUser) {
        guard let currentUser = SBDMain.getCurrentUser() else { return }
        guard let channel = self.channel else { return }
        
        if user.userId == currentUser.userId, sender.channelUrl == channel.channelUrl {
            self.sendUserMessageButton.isEnabled = true
            self.inputMessageTextField.isEnabled = true
            self.inputMessageTextField.placeholder = "Type a message.."
            self.sendFileMessageButton.isEnabled = false
        }
    }
    
    func channel(_ sender: SBDBaseChannel, userWasBanned user: SBDUser) {
        guard let currentUser = SBDMain.getCurrentUser() else { return }
        guard let channel = self.channel else { return }
        
        if user.userId == currentUser.userId && sender.channelUrl == channel.channelUrl {
            let alert = UIAlertController(title: "You are banned.", message: "You are banned for 10 minutes. This channel will be closed.", preferredStyle: .alert)
            let actionCancel = UIAlertAction(title: "Close", style: .cancel) { (action) in
                self.navigationController?.popViewController(animated: true)
            }
            alert.addAction(actionCancel)
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func channelWasDeleted(_ channelUrl: String, channelType: SBDChannelType) {
        let alert = UIAlertController(title: "Channel has been deleted.", message: "This channel has been deleted. It will be closed.", preferredStyle: .alert)
        let actionCancel = UIAlertAction(title: "Close", style: .cancel) { (action) in
            self.navigationController?.popViewController(animated: true)
        }
        alert.addAction(actionCancel)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func channel(_ sender: SBDBaseChannel, messageWasDeleted messageId: Int64) {
        DispatchQueue.main.async {
            guard let channel = self.channel else { return }
            
            if sender == channel {
                self.deleteMessageFromTableView(messageId)
            }
        }
    }
    
    func channel(_ sender: SBDBaseChannel, didUpdate message: SBDBaseMessage) {
        for (i, prevMessage) in messages.enumerated() {
            if prevMessage.messageId == message.messageId {
                messages.remove(at: i)
                messages.insert(message, at: i)
                DispatchQueue.main.async {
                    self.messageTableView.reloadRows(at: [IndexPath(row: i, section: 0)], with: .none)
                }
                break
            }
        }
    }
    
    func channelWasChanged(_ sender: SBDBaseChannel) {
        DispatchQueue.main.async {
            guard let channel = self.channel else { return }
            
            if sender == channel {
                self.title = channel.name
            }
        }
    }
    
    // MARK: - Crop Image
    func cropImage(_ imageData: Data) {
        if let image = UIImage(data: imageData) {
            let imageCropVC = RSKImageCropViewController(image: image)
            imageCropVC.delegate = self
            imageCropVC.cropMode = .square
            self.present(imageCropVC, animated: false, completion: nil)
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let mediaType = info[UIImagePickerController.InfoKey.mediaType] as! CFString

        picker.dismiss(animated: true, completion: { [unowned self] () in
            if CFStringCompare(mediaType, kUTTypeImage, []) == .compareEqualTo {
                if let imagePath = info[UIImagePickerController.InfoKey.imageURL] as? URL {
                    let imageName = imagePath.lastPathComponent
                    let ext = imageName.pathExtension()
                    guard let UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ext as CFString, nil)?.takeRetainedValue() else { return }
                    guard let retainedValueMimeType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType)?.takeRetainedValue() else { return }
                    let mimeType = retainedValueMimeType as String
                    
                    guard let imageAsset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset else { return }
                    let options = PHImageRequestOptions()
                    options.isSynchronous = true
                    options.isNetworkAccessAllowed = true
                    options.deliveryMode = .highQualityFormat
                    
                    if mimeType == "image/gif" {
                        PHImageManager.default().requestImageData(for: imageAsset, options: options, resultHandler: { (imageData, dataUTI, orientation, info) in
                            if let originalImageData = imageData {
                                self.sendImageFileMessage(imageData: originalImageData, imageName: imageName, mimeType: mimeType)
                            }
                        })
                    }
                    else {
                        PHImageManager.default().requestImage(for: imageAsset, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.default, options: nil, resultHandler: { (result, info) in
                            if result != nil {
                                guard let imageData = result?.jpegData(compressionQuality: 1.0) else { return }
                                self.sendImageFileMessage(imageData: imageData, imageName: imageName, mimeType: mimeType)
                            }
                        })
                    }
                }
                else {
                    guard let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
                    guard let imageData = originalImage.jpegData(compressionQuality: 1.0) else { return }
                    self.sendImageFileMessage(imageData: imageData, imageName: "image.jpg", mimeType: "image/jpeg")
                }
            } else if CFStringCompare(mediaType, kUTTypeMovie, []) == .compareEqualTo {
                self.sendVideoFileMessage(info: info)
            }
        })
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - RSKImageCropViewControllerDelegate
    // Crop image has been canceled.
    func imageCropViewControllerDidCancelCrop(_ controller: RSKImageCropViewController) {
        controller.dismiss(animated: false, completion: nil)
    }
    
    // The original image has been cropped.
    func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect, rotationAngle: CGFloat) {
        controller.dismiss(animated: false, completion: nil)
    }
    
    // The original image will be cropped.
    func imageCropViewController(_ controller: RSKImageCropViewController, willCropImage originalImage: UIImage) {
        // Use when `applyMaskToCroppedImage` set to YES.
    }
    
    // MARK: - SBDNetworkDelegate
    func didReconnect() {
        self.loadPreviousMessages(initial: true)
        guard let channel = self.channel else { return }
        channel.refresh(completionHandler: nil)
    }
    
    // MARK: - OpenChannelSettingsDelegate
    func didUpdateOpenChannel() {
        guard let channel = self.channel else { return }
        self.title = channel.name
        self.channelUpdated = true
    }
    
    @objc func inputMessageTextFieldChanged(_ sender: AnyObject) {
        if sender is UITextField {
            let textField = sender as! UITextField
            guard let text = textField.text else { return }
            if text.count > 0 {
                self.sendUserMessageButton.isEnabled = true
            }
            else {
                self.sendUserMessageButton.isEnabled = false
            }
        }
    }
    
    // MARK: - UIDocumentPickerDelegate
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if urls.count > 0 {
            let fileURL = urls[0]
            do {
                let fileData = try Data(contentsOf: fileURL)
                let filename = fileURL.lastPathComponent
                let ext = filename.pathExtension()
                guard let UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ext as CFString, nil)?.takeRetainedValue() else { return }
                guard let retainedValueMimeType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType)?.takeRetainedValue() else { return }
                let mimeType = retainedValueMimeType as String
                guard let channel = self.channel else { return }
                var preSendMessage: SBDFileMessage?

                guard let params = SBDFileMessageParams(file: fileData) else { return }
                params.fileName = filename
                params.mimeType = mimeType
                params.fileSize = UInt(fileData.count)
                preSendMessage = channel.sendFileMessage(with: params, progressHandler: { (bytesSent, totalBytesSent, totalBytesExpectedToSend) in
                    DispatchQueue.main.async {
                        guard let preSendMessageRequestId = preSendMessage?.requestId else { return }
                        self.fileTransferProgress[preSendMessageRequestId] = CGFloat(totalBytesSent) / CGFloat(totalBytesExpectedToSend)
                        for index in stride(from: self.messages.count - 1, to: -1, by: -1) {
                            let baseMessage = self.messages[index]
                            if baseMessage is SBDFileMessage {
                                guard let fileMessage = (baseMessage as? SBDFileMessage) else { continue }
                                let fileMessageRequestId = fileMessage.requestId
                                guard fileMessageRequestId != "" else { continue }
                                
                                if fileMessageRequestId == preSendMessageRequestId {
                                    self.determineScrollLock()
                                    let indexPath = IndexPath(row: index, section: 0)
                                    self.messageTableView.reloadRows(at: [indexPath], with: .none)
                                }
                            }
                        }
                    }
                }, completionHandler: { (fileMessage, error) in
                    guard let message = fileMessage else { return }
                    guard let fileMessageRequestId = fileMessage?.requestId else { return }
                    let preSendMessage = self.preSendMessages[fileMessageRequestId] as? SBDFileMessage
                    self.preSendMessages.removeValue(forKey: fileMessageRequestId)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(150), execute: {
                        if error != nil {
                            self.resendableMessages[fileMessageRequestId] = preSendMessage
                            guard let preSendMessageRequestId = preSendMessage?.requestId else { return }
                            self.resendableFileData[preSendMessageRequestId] = [
                                "data": fileData,
                                "type": mimeType,
                                "filename": filename
                                ] as [String:AnyObject]
                            
                            DispatchQueue.main.async {
                                self.determineScrollLock()
                                self.messageTableView.reloadData()
                                self.scrollToBottom(force: false)
                            }
                            
                            return
                        }
                        
                        guard let message = fileMessage, let fileMessageRequestId = fileMessage?.requestId else { return }
                        DispatchQueue.main.async {
                            self.resendableMessages.removeValue(forKey: fileMessageRequestId)
                            self.resendableFileData.removeValue(forKey: fileMessageRequestId)
                            
                            guard let preSendMessageIndex = self.messages.firstIndex(of: preSendMessage!) else { return }
                            
                            self.messages[preSendMessageIndex] = message
                            self.determineScrollLock()
                            self.messageTableView.reloadData()
                        }
                    })
                })
                
                DispatchQueue.main.async {
                    guard let preSendMsg = preSendMessage else { return }
                    guard let preSendMsgRequestId = preSendMessage?.requestId else { return }
                    
                    self.fileTransferProgress[preSendMsgRequestId] = 0
                    self.preSendFileData[preSendMsgRequestId] = [
                        "data": fileData,
                        "type": mimeType,
                        "filename": filename,
                        ] as [String:AnyObject]
                    self.determineScrollLock()
                    self.preSendMessages[preSendMsgRequestId] = preSendMsg
                    self.messages.append(preSendMsg)
                    self.messageTableView.reloadData()
                    self.scrollToBottom(force: false)
                }
            }
            catch {
            }
        }
    }
    
    private func deleteMessageFromTableView(_ messageId: Int64) {
        if self.messages.count == 0 {
            return
        }
        
        for i in 0...self.messages.count-1 {
            let msg = self.messages[i]
            if msg.messageId == messageId {
                self.determineScrollLock()
                self.messages.removeObject(msg)
                self.messageTableView.deleteRows(at: [IndexPath(row: i, section: 0)], with: .none)
                self.messageTableView.layoutIfNeeded()
                self.scrollToBottom(force: false)
                
                break
            }
        }
    }
    
    private func playMedia(_ url: URL) {
        let player = AVPlayer(url: url)
        let vc = AVPlayerViewController()
        vc.player = player
        self.present(vc, animated: true) {
            player.play()
        }
    }
    
    private func sendImageFileMessage(imageData: Data, imageName: String, mimeType: String) {
        // success, data is in imageData
        /***********************************/
        /* Thumbnail is a premium feature. */
        /***********************************/
        
        let thumbnailSize = SBDThumbnailSize.make(withMaxWidth: 320.0, maxHeight: 320.0)
        var preSendMessage: SBDFileMessage?
        let fileMessageParams = SBDFileMessageParams(file: imageData)!
        
        fileMessageParams.fileName = imageName
        fileMessageParams.mimeType = mimeType
        fileMessageParams.fileSize = UInt(imageData.count)
        fileMessageParams.thumbnailSizes = [thumbnailSize]
        fileMessageParams.data = nil
        fileMessageParams.customType = nil
        guard let channel = self.channel else { return }
        preSendMessage = channel.sendFileMessage(with: fileMessageParams, progressHandler: { [unowned self] (bytesSent, totalBytesSent, totalBytesExpectedToSend) in
            DispatchQueue.main.async {
                guard let preSendMessageRequestId = preSendMessage?.requestId else { return }
                
                if self.sendingImageVideoMessage[preSendMessageRequestId] == nil {
                    self.sendingImageVideoMessage[preSendMessageRequestId] = false
                }
                
                self.fileTransferProgress[preSendMessageRequestId] = CGFloat(totalBytesSent) / CGFloat(totalBytesExpectedToSend)
                for index in stride(from: self.messages.count - 1, to: -1, by: -1) {
                    let baseMessage = self.messages[index]
                    if baseMessage is SBDFileMessage {
                        let fileMessage = baseMessage as! SBDFileMessage
                        let fileMessageRequestId = fileMessage.requestId
                        guard fileMessageRequestId != "" else { return }
                        if fileMessageRequestId == preSendMessageRequestId {
                            self.determineScrollLock()
                            let indexPath = IndexPath(row: index, section: 0)
                            if self.sendingImageVideoMessage[preSendMessageRequestId] == false {
                                self.messageTableView.reloadRows(at: [indexPath], with: .none)
                                self.sendingImageVideoMessage[preSendMessageRequestId] = true
                                self.scrollToBottom(force: false)
                            }
                            else {
                                if let cell = self.messageTableView.cellForRow(at: indexPath) as? OpenChannelImageVideoFileMessageTableViewCell {
                                    cell.showProgress(CGFloat(totalBytesSent) / CGFloat(totalBytesExpectedToSend))
                                }
                            }
                            
                            break
                        }
                    }
                }
            }
        }, completionHandler: { [unowned self] (fileMessage, error) in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: 150 * NSEC_PER_MSEC), execute: {
                let preSendMessage = self.preSendMessages[fileMessage!.requestId] as! SBDFileMessage
                
                self.preSendMessages.removeValue(forKey: fileMessage!.requestId)
                self.sendingImageVideoMessage.removeValue(forKey: fileMessage!.requestId)
                
                if error != nil {
                    DispatchQueue.main.async {
                        self.resendableMessages[fileMessage!.requestId] = preSendMessage
                        self.resendableFileData[preSendMessage.requestId] = [
                            "data": imageData,
                            "type": mimeType,
                            "filename": imageName
                            ] as [String : AnyObject]
                        self.messageTableView.reloadData()
                        self.scrollToBottom(force: true)
                    }
                    
                    return
                }
                
                if fileMessage != nil {
                    DispatchQueue.main.async {
                        self.determineScrollLock()
                        self.resendableMessages.removeValue(forKey: fileMessage!.requestId)
                        self.resendableFileData.removeValue(forKey: fileMessage!.requestId)
                        self.messages[self.messages.firstIndex(of: preSendMessage)!] = fileMessage!
                        let indexPath = IndexPath(row: self.messages.firstIndex(of: fileMessage!)!, section: 0)
                        self.messageTableView.reloadRows(at: [indexPath], with: .none)
                        self.scrollToBottom(force: false)
                    }
                }
            })
        })
        
        DispatchQueue.main.async {
            self.determineScrollLock()
            self.fileTransferProgress[preSendMessage!.requestId] = 0
            self.preSendFileData[preSendMessage!.requestId] = [
                "data": imageData,
                "type": mimeType,
                "filename": imageName
                ] as [String : AnyObject]
            self.preSendMessages[preSendMessage!.requestId] = preSendMessage
            self.messages.append(preSendMessage!)
            self.messageTableView.reloadData()
            self.scrollToBottom(force: false)
        }
    }
    
    private func sendVideoFileMessage(info: [UIImagePickerController.InfoKey : Any]) {
        do {
            guard let videoUrl = info[UIImagePickerController.InfoKey.mediaURL] as? URL else { return }
            let videoFileData = try Data(contentsOf: videoUrl)
            let videoName = videoUrl.lastPathComponent
            let ext = videoName.pathExtension()
            guard let UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ext as CFString, nil)?.takeRetainedValue() else { return }
            guard let retainedValueMimeType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType)?.takeRetainedValue() else { return }
            let mimeType = retainedValueMimeType as String
            
            // success, data is in imageData
            /***********************************/
            /* Thumbnail is a premium feature. */
            /***********************************/
            
            let thumbnailSize = SBDThumbnailSize.make(withMaxWidth: 320.0, maxHeight: 320.0)
            
            var preSendMessage: SBDFileMessage?
            guard let channel = self.channel else { return }
            let fileMessageParams = SBDFileMessageParams(file: videoFileData)!
            fileMessageParams.fileName = videoName
            fileMessageParams.mimeType = mimeType
            fileMessageParams.fileSize = UInt(videoFileData.count)
            fileMessageParams.thumbnailSizes = [thumbnailSize] as? [SBDThumbnailSize]
            fileMessageParams.data = nil
            fileMessageParams.customType = nil
            preSendMessage = channel.sendFileMessage(with: fileMessageParams, progressHandler: { [unowned self] (bytesSent, totalBytesSent, totalBytesExpectedToSend) in
                DispatchQueue.main.async {
                    if self.sendingImageVideoMessage[preSendMessage!.requestId] == nil {
                        self.sendingImageVideoMessage[preSendMessage!.requestId] = false
                    }
                    
                    self.fileTransferProgress[preSendMessage!.requestId] = CGFloat(totalBytesSent) / CGFloat(totalBytesExpectedToSend)
                    for index in stride(from: self.messages.count - 1, to: -1, by: -1) {
                        let baseMessage = self.messages[index]
                        if baseMessage is SBDFileMessage {
                            let fileMessage = baseMessage as! SBDFileMessage
                            if fileMessage.requestId != nil && fileMessage.requestId == preSendMessage!.requestId {
                                self.determineScrollLock()
                                let indexPath = IndexPath(row: index, section: 0)
                                if self.sendingImageVideoMessage[preSendMessage!.requestId] == false {
                                    self.messageTableView.reloadRows(at: [indexPath], with: .none)
                                    self.sendingImageVideoMessage[preSendMessage!.requestId] = true
                                    self.scrollToBottom(force: false)
                                }
                                else {
                                    let cell = self.messageTableView.cellForRow(at: indexPath) as! OpenChannelImageVideoFileMessageTableViewCell
                                    cell.showProgress(CGFloat(totalBytesSent) / CGFloat(totalBytesExpectedToSend))
                                }
                                
                                break
                            }
                        }
                    }
                }
            }, completionHandler: { [unowned self] (fileMessage, error) in
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(150), execute: {
                    let preSendMessage = self.preSendMessages[fileMessage!.requestId] as! SBDFileMessage
                    
                    self.preSendMessages.removeValue(forKey: fileMessage!.requestId)
                    self.sendingImageVideoMessage.removeValue(forKey: fileMessage!.requestId)
                    
                    if error != nil {
                        DispatchQueue.main.async {
                            self.resendableMessages[fileMessage!.requestId] = preSendMessage
                            self.resendableFileData[preSendMessage.requestId] = [
                                "data": videoFileData,
                                "type": mimeType,
                                "filename": videoName
                                ] as [String : AnyObject]
                        }
                        
                        return
                    }
                
                    if let message = fileMessage, let requestId = fileMessage?.requestId {
                        DispatchQueue.main.async {
                            self.determineScrollLock()
                            self.resendableMessages.removeValue(forKey: requestId)
                            self.resendableFileData.removeValue(forKey: requestId)
                            let preSendMessageRow = self.messages.firstIndex(of: preSendMessage)!
                            self.messages[preSendMessageRow] = message
                            
                            let fileMessageIndexPath = IndexPath(row: self.messages.firstIndex(of: fileMessage!)!, section: 0)
                            self.messageTableView.reloadRows(at: [fileMessageIndexPath], with: .none)
                            self.scrollToBottom(force: false)
                        }
                    }
                })
            })
            
            DispatchQueue.main.async {
                self.fileTransferProgress[(preSendMessage?.requestId)!] = 0
                self.preSendFileData[(preSendMessage?.requestId)!] = [
                    "data": videoFileData,
                    "type": mimeType,
                    "filename": videoName
                    ] as [String:AnyObject]
                self.determineScrollLock()
                self.preSendMessages[(preSendMessage?.requestId)!] = preSendMessage
                self.messages.append(preSendMessage!)
                self.messageTableView.reloadData()
                self.scrollToBottom(force: false)
            }
        }
        catch {
        }
    }
}
