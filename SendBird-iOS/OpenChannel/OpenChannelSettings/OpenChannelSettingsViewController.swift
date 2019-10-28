//
//  OpenChannelSettingsViewController.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 10/23/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import RSKImageCropper
import Photos
import AlamofireImage
import MobileCoreServices

class OpenChannelSettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, OpenChannelSettingsChannelNameTableViewCellDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, RSKImageCropViewControllerDelegate, SelectOperatorsDelegate, OpenChannelCoverImageNameSettingDelegate, NotificationDelegate, SBDChannelDelegate {

    @IBOutlet weak var settingsTableView: UITableView!
    @IBOutlet weak var loadingIndicatorView: CustomActivityIndicatorView!
    
    static let OPERATOR_MENU_COUNT = 7
    static let REGULAR_PARTICIPANT_MENU_COUNT = 4
    
    var operators: [SBDUser] = []
    var selectedUsers: [String:SBDUser] = [:]
    
    weak var delegate: OpenChannelSettingsDelegate?
    
    var channel: SBDOpenChannel?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Open Channel Settings"
        self.navigationItem.largeTitleDisplayMode = .automatic

        SBDMain.add(self as SBDChannelDelegate, identifier: self.description)
        
        self.settingsTableView.delegate = self
        self.settingsTableView.dataSource = self

        self.hideLoadingIndicatorView()
        self.view.bringSubviewToFront(self.loadingIndicatorView)
        
        self.refreshOperators()
    }

    override func viewWillDisappear(_ animated: Bool) {
        guard let navigationController = self.navigationController else { return }
        if navigationController.viewControllers.firstIndex(of: self) == nil {
            guard let delegate = self.delegate else { return }
            if delegate.responds(to: #selector(OpenChannelSettingsDelegate.didUpdateOpenChannel)) {
                delegate.didUpdateOpenChannel!()
            }
        }
        
        super.viewWillDisappear(animated)
    }
    
    // MARK: - NotificationDelegate
    func openChat(_ channelUrl: String) {
        guard let navigationController = self.navigationController else { return }
        navigationController.popViewController(animated: false)
        if let cvc = UIViewController.currentViewController() as? NotificationDelegate {
            cvc.openChat(channelUrl)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SelectOperators", let destination = segue.destination as? SelectOperatorsViewController{
            destination.title = "Add an operator"
            destination.delegate = self
            
            guard let channel = self.channel, let operators = channel.operators as? [SBDUser] else { return }
            
            for user in operators {
                destination.selectedUsers[user.userId] = user
            }
        } else if segue.identifier == "ShowUserProfile", let destination = segue.destination as? UserProfileViewController, let index = sender as? Int {
            destination.user = self.operators[index]
        } else if segue.identifier == "ShowUserList", let destination = segue.destination as? OpenChannelUserListViewController, let listType = sender as? UserListType {
            destination.channel = self.channel
            destination.userListType = listType
        } else if segue.identifier == "CoverImageNameSetting", let destination = segue.destination as? OpenChannelCoverImageNameSettingViewController {
            destination.delegate = self
            destination.channel = self.channel
        }
    }
    
    func clickSettingsMenuTableView() {
        guard let cell = self.settingsTableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? OpenChannelSettingsChannelNameTableViewCell else { return }
        cell.channelNameTextField.resignFirstResponder()
        cell.channelNameTextField.isEnabled = false
        guard let channel = self.channel else { return }
        cell.channelNameTextField.text = channel.name
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let channel = self.channel else { return 0 }
        
        let isOperator = channel.isOperator(with: SBDMain.getCurrentUser()!)
        
        switch section{
        case 0:
            return 1
        case 1:
            return isOperator ? 3 : 1
        case 2:
            return isOperator ? self.operators.count + 1 : self.operators.count
        default:
            return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return (section == 2) ? "Operator" : nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        guard let channel = self.channel else { return cell }
        guard let currentUser = SBDMain.getCurrentUser() else { return cell }
        
        switch indexPath.section {
        case 0:
            if let channelNameCell = tableView.dequeueReusableCell(withIdentifier: "OpenChannelSettingsChannelNameTableViewCell", for: indexPath) as? OpenChannelSettingsChannelNameTableViewCell {
                channelNameCell.delegate = self
                channelNameCell.channelNameTextField.text = channel.name
                channelNameCell.setEnableEditing(channel.isOperator(with: currentUser))
                if let url = URL(string: channel.coverUrl!) {
                    channelNameCell.channelCoverImageView.af_setImage(withURL: url, placeholderImage: UIImage(named: "img_cover_image_placeholder_1"))
                }
                else {
                    channelNameCell.channelCoverImageView.image = UIImage(named: "img_cover_image_placeholder_1")
                }
                
                cell = channelNameCell
            }
        case 1:
            if indexPath.row == 0 {
                if let participantCell = tableView.dequeueReusableCell(withIdentifier: "OpenChannelSettingsMenuTableViewCell", for: indexPath) as? OpenChannelSettingsMenuTableViewCell {
                    participantCell.settingMenuLabel.text = "Participants"
                    participantCell.settingMenuIconImageView.image = UIImage(named: "img_icon_participant")
                    participantCell.countLabel.text = String(format: "%ld", channel.participantCount)
                    
                    cell = participantCell
                }
            } else if channel.isOperator(with: currentUser) {
                if indexPath.row == 1{
                    if let muteCell = tableView.dequeueReusableCell(withIdentifier: "OpenChannelSettingsMenuTableViewCell", for: indexPath) as? OpenChannelSettingsMenuTableViewCell {
                        muteCell.settingMenuLabel.text = "Muted Users"
                        muteCell.settingMenuIconImageView.image = UIImage(named: "img_icon_mute")
                        muteCell.countLabel.isHidden = true
                        
                        cell = muteCell
                    }
                } else if indexPath.row == 2{
                    if let banCell = tableView.dequeueReusableCell(withIdentifier: "OpenChannelSettingsMenuTableViewCell", for: indexPath) as? OpenChannelSettingsMenuTableViewCell {
                        banCell.settingMenuLabel.text = "Banned Users"
                        banCell.settingMenuIconImageView.image = UIImage(named: "bannedUsers")
                        banCell.countLabel.isHidden = true
                        
                        cell = banCell
                    }
                }
            }
        case 2:
            if channel.isOperator(with: currentUser){
                if indexPath.row == 0{
                    if let addOperatorCell = tableView.dequeueReusableCell(withIdentifier: "OpenChannelSettingsMenuTableViewCell", for: indexPath) as? OpenChannelSettingsMenuTableViewCell {
                        addOperatorCell.settingMenuLabel.text = "Add an operator"
                        addOperatorCell.settingMenuLabel.textColor = UIColor(named: "color_settings_menu_add_operator")
                        addOperatorCell.settingMenuIconImageView.image = UIImage(named: "img_icon_add_operator")
                        addOperatorCell.accessoryType = .none
                        addOperatorCell.countLabel.isHidden = true
                        
                        cell = addOperatorCell
                    }
                } else {
                    let opIndex = indexPath.row - 1
                    if self.operators[opIndex].userId == currentUser.userId {
                        if let operatorCell = tableView.dequeueReusableCell(withIdentifier: "OpenChannelSettingsUserTableViewCell", for: indexPath) as? OpenChannelSettingsUserTableViewCell {
                            if let nickname = self.operators[opIndex].nickname {
                                operatorCell.nicknameLabel.text = nickname
                            }
                            
                            operatorCell.profileImageView.setProfileImageView(for: self.operators[opIndex])
                            
                            cell = operatorCell
                        }
                    } else {
                        if let operatorCell = tableView.dequeueReusableCell(withIdentifier: "OpenChannelSettingsUserTableViewCell", for: indexPath) as? OpenChannelSettingsUserTableViewCell {
                            operatorCell.user = self.operators[opIndex]
                            if let nickname = self.operators[opIndex].nickname {
                                operatorCell.nicknameLabel.text = nickname
                            }
                            
                            operatorCell.profileImageView.setProfileImageView(for: self.operators[opIndex])
                            
                            operatorCell.accessoryType = .disclosureIndicator
                            
                            operatorCell.profileCoverView.isHidden = true
                            
                            cell = operatorCell
                            
                            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(OpenChannelSettingsViewController.longPress(_:)))
                            cell.addGestureRecognizer(longPressGesture)
                        }
                    }
                }
            } else{
                let opIndex = indexPath.row
                if self.operators[opIndex].userId == currentUser.userId {
                    if let operatorCell = tableView.dequeueReusableCell(withIdentifier: "OpenChannelSettingsUserTableViewCell", for: indexPath) as? OpenChannelSettingsUserTableViewCell {
                        if let nickname = self.operators[opIndex].nickname {
                            operatorCell.nicknameLabel.text = nickname
                        }
                        
                        operatorCell.profileImageView.setProfileImageView(for: self.operators[opIndex])
                        
                        cell = operatorCell
                    }
                }
                else {
                    if let operatorCell = tableView.dequeueReusableCell(withIdentifier: "OpenChannelSettingsUserTableViewCell", for: indexPath) as? OpenChannelSettingsUserTableViewCell {
                        operatorCell.user = self.operators[opIndex]
                        if let nickname = self.operators[opIndex].nickname {
                            operatorCell.nicknameLabel.text = nickname
                        }
                       
                       operatorCell.profileImageView.setProfileImageView(for: self.operators[opIndex])
                        
                        operatorCell.accessoryType = .disclosureIndicator
                        
                        operatorCell.profileCoverView.isHidden = true
                        
                        cell = operatorCell

                        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(OpenChannelSettingsViewController.longPress(_:)))
                        cell.addGestureRecognizer(longPressGesture)
                    }
                }
            }
        default:
            break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {     
        return (indexPath.section == 0) ? 121 : 48
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let currentUser = SBDMain.getCurrentUser() else { return }
        guard let channel = self.channel else { return }
        self.clickSettingsMenuTableView()
        
        tableView.deselectRow(at: indexPath, animated: false)
        
        switch indexPath.section {
        case 1:
            if indexPath.row == 0{
                performSegue(withIdentifier: "ShowUserList", sender: UserListType.participant)
            } else if indexPath.row == 1 {
                // Mute
                performSegue(withIdentifier: "ShowUserList", sender: UserListType.muted)
            } else if indexPath.row == 2 {
                // Ban
                performSegue(withIdentifier: "ShowUserList", sender: UserListType.banned)
            }
        case 2:
            if channel.isOperator(with: currentUser) {
                if indexPath.row == 0 {
                    // Add Operators
                    performSegue(withIdentifier: "SelectOperators", sender: nil)
                } else if indexPath.row != 1 {
                    performSegue(withIdentifier: "ShowUserProfile", sender: (indexPath.row - 1))
                }
            } else {
                performSegue(withIdentifier: "ShowUserProfile", sender: indexPath.row)
            }
        default:
            break
        }
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        guard let channel = self.channel else { return false }
        self.showLoadingIndicatorView()
        channel.update(withName: textField.text, coverImage: nil, coverImageName: nil, data: nil, operatorUserIds: nil, customType: nil, progressHandler: nil) { (channel, error) in
            self.hideLoadingIndicatorView()
            
            guard error == nil else { return }

            DispatchQueue.main.async {
                self.settingsTableView.reloadData()
            }
        }
        
        return true
    }
    
    // MARK: - OpenChannelSettingsChannelNameTableViewCellDelegate
    func didClickChannelCoverImageNameEdit() {
        performSegue(withIdentifier: "CoverImageNameSetting", sender: nil)
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
//                if let imagePath = info[UIImagePickerController.InfoKey.imageURL] as? URL {
//                    let imageName = imagePath.lastPathComponent
//                    let ext = imageName.pathExtension()
//                    guard let UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ext as CFString, nil)?.takeRetainedValue() else { return }
//                    guard let retainedValueMimeType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType)?.takeRetainedValue() else { return }
//                    let mimeType = retainedValueMimeType as String
//
//
//                }
                
                guard let imageAsset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset else { return }
                let options = PHImageRequestOptions()
                options.isSynchronous = true
                options.isNetworkAccessAllowed = true
                options.deliveryMode = .highQualityFormat
                
                PHImageManager.default().requestImageData(for: imageAsset, options: options, resultHandler: { (imageData, dataUTI, orientation, info) in
                    guard let data = imageData else { return }
                    guard let image = UIImage(data: data) else { return }
                    guard let originalImage = image.jpegData(compressionQuality: 1.0) else { return }
                    
                    self.cropImage(originalImage)
                })
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
        self.updateChannelCoverImage(croppedImage: croppedImage, controller: controller)
    }
    
    // The original image will be cropped.
    func imageCropViewController(_ controller: RSKImageCropViewController, willCropImage originalImage: UIImage) {
        // Use when `applyMaskToCroppedImage` set to YES.
    }
    
    func updateChannelCoverImage(croppedImage: UIImage, controller: RSKImageCropViewController) {
        let coverImageData = croppedImage.jpegData(compressionQuality: 0.5)
        
        self.showLoadingIndicatorView()
        guard let channel = self.channel else { return }
        channel.update(withName: nil, coverImage: coverImageData, coverImageName: "image.jpg", data: nil, operatorUserIds: nil, customType: nil, progressHandler: nil) { (channel, error) in
            self.hideLoadingIndicatorView()
            
            if error != nil {
                return
            }
            
            DispatchQueue.main.async {
                self.settingsTableView.reloadData()
            }
        }
        
        controller.dismiss(animated: false, completion: nil)
    }
    
    // MARK: - SelectOperatorsDelegate
    func didSelectUsers(_ users: [String : SBDUser]) {
        self.showLoadingIndicatorView()
        
        guard let currentUser = SBDMain.getCurrentUser() else { return }
        
        var operators: [SBDUser] = Array(users.values)
        operators.append(currentUser)
        
        guard let channel = self.channel else { return }
        channel.update(withName: nil, coverUrl: nil, data: nil, operatorUsers: operators) { (channel, error) in
            self.hideLoadingIndicatorView()
            
            guard error == nil else { return }
            
            DispatchQueue.main.async {
                self.operators.removeAll()
                for op in channel!.operators! as! [SBDUser] {
                    if op.userId == currentUser.userId {
                        self.operators.insert(op, at: 0)
                    }
                    else {
                        self.operators.append(op)
                    }
                }
                
                self.settingsTableView.reloadData()
            }
        }
    }
    
    // MARK: - UIAlertController for operators
    @objc func longPress(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            guard let cell = recognizer.view as? UITableViewCell else { return }
            if cell is OpenChannelSettingsUserTableViewCell {
                guard let operatorCell = cell as? OpenChannelSettingsUserTableViewCell else { return }
                guard let removedOperator = operatorCell.user else { return }
                var operators:[SBDUser] = []
                guard let channel = self.channel else { return }
                for user in channel.operators! as? [SBDUser] ?? [] {
                    if user.userId == removedOperator.userId {
                        continue
                    }
                    
                    operators.append(user)
                }
                
                let alert = UIAlertController(title: removedOperator.nickname, message: nil, preferredStyle: .actionSheet)
                let actionRemoveUser = UIAlertAction(title: "Remove from operators", style: .destructive) { (action) in
                    self.showLoadingIndicatorView()
                    
                    guard let channel = self.channel else { return }
                    channel.update(withName: nil, coverUrl: nil, data: nil, operatorUsers: operators, completionHandler: { (channel, error) in
                        if error != nil {
                            self.hideLoadingIndicatorView()
                            
                            return
                        }
                        
                        DispatchQueue.main.async {
                            self.hideLoadingIndicatorView()
                            self.operators.removeAll()
                            guard let currentUser = SBDMain.getCurrentUser() else { return }
                            for op in channel!.operators! as! [SBDUser] {
                                if op.userId == currentUser.userId {
                                    self.operators.insert(op, at: 0)
                                }
                                else {
                                    self.operators.append(op)
                                }
                            }
                            self.settingsTableView.reloadData()
                        }
                    })
                }
                let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                
                alert.addAction(actionRemoveUser)
                alert.addAction(actionCancel)
                
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    func refreshOperators() {
        self.operators.removeAll()
        
        guard let channel = self.channel else { return }
        if let operators = channel.operators as? [SBDUser] {
            for op: SBDUser in operators {
                if op.userId == SBDMain.getCurrentUser()!.userId {
                    self.operators.insert(op, at: 0)
                }
                else {
                    self.operators.append(op)
                }
            }
        }
    }
    
    // MARK: - OpenChannelCoverImageNameSettingDelegate
    func didUpdateOpenChannel() {
        DispatchQueue.main.async {
            self.settingsTableView.reloadData()
        }
    }
    
    // MARK: - SBDChannelDelegate
    func channel(_ sender: SBDOpenChannel, userDidExit user: SBDUser) {
        if sender == self.channel {
            DispatchQueue.main.async {
                self.settingsTableView.reloadData()
            }
        }
    }
    
    func channel(_ sender: SBDBaseChannel, userWasBanned user: SBDUser) {
        if sender == self.channel {
            DispatchQueue.main.async {
                self.settingsTableView.reloadData()
            }
        }
    }
    
    func channel(_ sender: SBDOpenChannel, userDidEnter user: SBDUser) {
        if sender == self.channel {
            DispatchQueue.main.async {
                self.settingsTableView.reloadData()
            }
        }
    }
    
    func channelWasChanged(_ sender: SBDBaseChannel) {
        if sender == self.channel {
            DispatchQueue.main.async {
                self.refreshOperators()
                self.settingsTableView.reloadData()
            }
        }
    }
    
    // MARK: - Utilities
    private func showLoadingIndicatorView() {
        self.loadingIndicatorView.superViewSize = self.view.frame.size
        self.loadingIndicatorView.updateFrame()
        
        DispatchQueue.main.async {
            self.loadingIndicatorView.isHidden = false
            self.loadingIndicatorView.startAnimating()
        }
    }
    
    private func hideLoadingIndicatorView() {
        DispatchQueue.main.async {
            self.loadingIndicatorView.isHidden = true
            self.loadingIndicatorView.stopAnimating()
        }
    }
}
