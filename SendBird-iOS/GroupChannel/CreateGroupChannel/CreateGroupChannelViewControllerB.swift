//
//  CreateGroupChannelViewControllerB.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 10/15/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import RSKImageCropper
import AlamofireImage
import MobileCoreServices
import Photos

class CreateGroupChannelViewControllerB: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, RSKImageCropViewControllerDelegate, NotificationDelegate {
    var members: [SBDUser] = []
    
    @IBOutlet weak var profileImageView: ProfileImageView!
    
    @IBOutlet weak var channelNameTextField: UITextField!
    
    @IBOutlet weak var publicChannelSwitch: UISwitch!
    @IBOutlet weak var loadingIndicatorView: CustomActivityIndicatorView!
    
    @IBOutlet weak var accessCodeSwitch: UISwitch!
    @IBOutlet weak var accessCodeTextField: UITextField!
    
    @IBOutlet weak var accessCodeSwitchContainerView: UIView!
    @IBOutlet weak var accessCodeTextFieldContainerView: UIView!
    @IBOutlet weak var accessCodeSwitchContainerConstraint: NSLayoutConstraint!
    @IBOutlet weak var accessCodeTextFieldContainerConstraint: NSLayoutConstraint!
    
    var coverImageData: Data?
    var createButtonItem: UIBarButtonItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Create Group Channel"
        
        self.navigationItem.largeTitleDisplayMode = .never

        self.createButtonItem = UIBarButtonItem(title: "Create", style: .done, target: self, action: #selector(CreateGroupChannelViewControllerB.clickCreateGroupChannel(_ :)))
        self.navigationItem.rightBarButtonItem = self.createButtonItem
        
        self.coverImageData = nil
        self.view.bringSubviewToFront(self.loadingIndicatorView)
        self.loadingIndicatorView.isHidden = true
        
        var memberNicknames: [String] = []
        var memberCount: Int = 0
        for user in self.members {
            memberNicknames.append(user.nickname!)
            memberCount += 1
            if memberCount == 4 {
                break
            }
        }
        
        let channelNamePlaceholder = memberNicknames.joined(separator: ", ")
        self.channelNameTextField.attributedPlaceholder = NSAttributedString(string: channelNamePlaceholder, attributes: [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0, weight: .regular),
            NSAttributedString.Key.foregroundColor: UIColor(named: "color_channelname_nickname_placeholder") as Any
            ])
        self.profileImageView.isUserInteractionEnabled = true
        let tapCoverImageGesture = UITapGestureRecognizer(target: self, action: #selector(CreateGroupChannelViewControllerB.clickCoverImage(_ :)))
        self.profileImageView.addGestureRecognizer(tapCoverImageGesture)
        
        self.profileImageView.users = members
        self.profileImageView.makeCircularWithSpacing(spacing: 1)
        
        accessCodeSwitchContainerConstraint.constant = -48
        accessCodeTextFieldContainerConstraint.constant = -48
    }

    
    @IBAction func togglePublicSwitch(_ sender: Any) {
        guard let toggle = sender as? UISwitch else { return }
        if toggle.isOn {
            accessCodeSwitchContainerConstraint.constant = 0
        } else {
            accessCodeSwitchContainerConstraint.constant = -48
            accessCodeTextFieldContainerConstraint.constant = -48
            accessCodeSwitch.setOn(false, animated: false)
        }
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @IBAction func togglePasswordSwitch(_ sender: Any) {
        guard let toggle = sender as? UISwitch else { return }
        if toggle.isOn {
            accessCodeTextFieldContainerConstraint.constant = 0
        } else {
            accessCodeTextFieldContainerConstraint.constant = -48
        }
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }

    @objc func clickCoverImage(_ sender: AnyObject) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let actionTakePhoto = UIAlertAction(title: "Take Photo...", style: .default) { (action) in
            DispatchQueue.main.async {
                let mediaUI = UIImagePickerController()
                mediaUI.sourceType = UIImagePickerController.SourceType.camera
                let mediaTypes = [String(kUTTypeImage)]
                mediaUI.mediaTypes = mediaTypes
                mediaUI.delegate = self
                self.present(mediaUI, animated: true, completion: nil)
            }
        }
        
        let actionChooseFromLibrary = UIAlertAction(title: "Choose from Library...", style: .default) { (action) in
            DispatchQueue.main.async {
                let mediaUI = UIImagePickerController()
                mediaUI.sourceType = UIImagePickerController.SourceType.photoLibrary
                let mediaTypes = [String(kUTTypeImage)]
                mediaUI.mediaTypes = mediaTypes
                mediaUI.delegate = self
                self.present(mediaUI, animated: true, completion: nil)
            }
        }
        
        let actionClose = UIAlertAction(title: "Close", style: .cancel, handler: nil)
        
        alertController.addAction(actionTakePhoto)
        alertController.addAction(actionChooseFromLibrary)
        alertController.addAction(actionClose)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func clickCreateGroupChannel(_ sender: AnyObject) {
        self.showLoadingIndicatorView()
        let channelName = self.channelNameTextField.text
        
        let params = SBDGroupChannelParams()
        params.coverImage = self.coverImageData
        
        if publicChannelSwitch.isOn {
            params.isDistinct = false
            params.isPublic = true
            if accessCodeSwitch.isOn {
                if accessCodeTextField.text != nil {
                    params.accessCode = accessCodeTextField.text
                } else {
                    return
                }
            }
        } else {
            let isDistinct = UserDefaults.standard.object(forKey: Constants.ID_CREATE_DISTINCT_CHANNEL) as? Bool
            params.isDistinct = isDistinct ?? true
        }
        
        params.add(self.members)
        params.name = channelName
        
        SBDGroupChannel.createChannel(with: params) { (channel, error) in
            self.hideLoadingIndicatorView()
            
            if let error = error {
                let alertController = UIAlertController(title: "Error", message: error.domain, preferredStyle: .alert)
                let actionClose = UIAlertAction(title: "Close", style: .cancel, handler: nil)
                alertController.addAction(actionClose)
                DispatchQueue.main.async {
                    self.present(alertController, animated: true, completion: nil)
                }
            
                return
            }


            if let navigationController = self.navigationController as? CreateGroupChannelNavigationController{
                if (navigationController.channelCreationDelegate?.responds(to: #selector(CreateGroupChannelNavigationController.didChangeValue(forKey:))))! {
                    navigationController.channelCreationDelegate?.didCreateGroupChannel!(channel!)
                }
                self.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func cropImage(_ imageData: Data) {
        if let image = UIImage(data: imageData) {
            let imageCropVC = RSKImageCropViewController(image: image)
            imageCropVC.delegate = self
            imageCropVC.cropMode = .square
            self.present(imageCropVC, animated: false, completion: nil)
        }
    }
    
    // MARK: - NotificationDelegate
    func openChat(_ channelUrl: String) {
        self.navigationController?.popViewController(animated: false)
        if let cvc = UIViewController.currentViewController() as? NotificationDelegate {
            cvc.openChat(channelUrl)
        }
    }
    
    // MARK: UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let mediaType = info[UIImagePickerController.InfoKey.mediaType] as! CFString
        weak var weakSelf: CreateGroupChannelViewControllerB? = self
        picker.dismiss(animated: true) {
            let strongSelf = weakSelf
            if CFStringCompare(mediaType, kUTTypeImage, []) == .compareEqualTo {
                if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                    if let imageData = originalImage.jpegData(compressionQuality: 1.0) {
                        strongSelf?.cropImage(imageData)
                    }
                }
            }
        }
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
        self.coverImageData = croppedImage.jpegData(compressionQuality: 0.5)
        controller.dismiss(animated: false, completion: nil)
    }
    
    // The original image will be cropped.
    func imageCropViewController(_ controller: RSKImageCropViewController, willCropImage originalImage: UIImage) {
        // Use when `applyMaskToCroppedImage` set to true
    }
    
    // MARK: - Utilities
    private func showLoadingIndicatorView() {
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
