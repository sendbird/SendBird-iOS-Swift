//
//  GroupChannelCoverImageNameSettingViewController.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 11/16/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import RSKImageCropper
import Photos
import MobileCoreServices
import AlamofireImage

class GroupChannelCoverImageNameSettingViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, RSKImageCropViewControllerDelegate, NotificationDelegate {
    weak var delegate: GroupChannelCoverImageNameSettingDelegate?
    var channel: SBDGroupChannel?

    var coverImage: UIImage?
    
    @IBOutlet weak var loadingIndicatorView: CustomActivityIndicatorView!
    @IBOutlet weak var channelNameTextField: UITextField!
    
    @IBOutlet weak var profileImageView: ProfileImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.title = "Cover Image & Name"
        self.navigationItem.largeTitleDisplayMode = .never
        
        let barButtonItemDone = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(GroupChannelCoverImageNameSettingViewController.clickDoneButton(_:)))
        self.navigationItem.rightBarButtonItem = barButtonItemDone
        
        self.view.bringSubviewToFront(self.loadingIndicatorView)
        self.loadingIndicatorView.isHidden = true
        
        self.coverImage = nil
        self.channelNameTextField.attributedPlaceholder = NSAttributedString(string: Utils.createGroupChannelNameFromMembers(channel: self.channel!), attributes: [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0, weight: .regular),
            NSAttributedString.Key.foregroundColor: UIColor(named: "color_channelname_nickname_placeholder") as Any
            ])
        self.channelNameTextField.text = self.channel!.name
        
        self.profileImageView.isUserInteractionEnabled = true
        let tapCoverImageGesture = UITapGestureRecognizer(target: self, action: #selector(GroupChannelCoverImageNameSettingViewController.clickCoverImage))
        self.profileImageView.addGestureRecognizer(tapCoverImageGesture)

        var currentMembers: [SBDMember] = []
        var count = 0
        for member in self.channel?.members as? [SBDMember] ?? [] {
            if member.userId == SBDMain.getCurrentUser()?.userId {
                continue
            }
            currentMembers.append(member)
            count += 1
            if count == 4 {
                break
            }
        }
        if let coverUrl = self.channel?.coverUrl {
            if coverUrl.count > 0 && !coverUrl.hasPrefix("https://sendbird.com/main/img/cover/") {
                self.profileImageView.setImage(withCoverUrl: coverUrl)
            }
        } else {
            self.profileImageView.users = currentMembers
        }
        self.profileImageView.makeCircularWithSpacing(spacing: 1)
    }
    
    @objc func clickDoneButton(_ sender: Any) {
        self.updateChannelInfo()
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
        weak var weakSelf: GroupChannelCoverImageNameSettingViewController? = self
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
        self.coverImage = croppedImage

        controller.dismiss(animated: false, completion: nil)
    }
    
    // The original image has been cropped. Additionally provides a rotation angle used to produce image.
    func imageCropViewController(_ controller: RSKImageCropViewController, willCropImage originalImage: UIImage) {
        // Use when `applyMaskToCroppedImage` set to true
    }
    
    @objc func clickCoverImage() {
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
        
        let actionLibrary = UIAlertAction(title: "Choose from Library...", style: .default) { (action) in
            DispatchQueue.main.async {
                let mediaUI = UIImagePickerController()
                mediaUI.sourceType = UIImagePickerController.SourceType.photoLibrary
                let mediaTypes = [String(kUTTypeImage)]
                mediaUI.mediaTypes = mediaTypes
                mediaUI.delegate = self
                self.present(mediaUI, animated: true, completion: nil)
            }
        }
        
        let actionCancel = UIAlertAction(title: "Close", style: .cancel, handler: nil)
        
        alert.addAction(actionPhoto)
        alert.addAction(actionLibrary)
        alert.addAction(actionCancel)
        
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = self.view
            presenter.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.maxY, width: 0, height: 0)
            presenter.permittedArrowDirections = []
        }
        
        self.present(alert, animated: true, completion: nil)
    }

    func updateChannelInfo() {
        self.loadingIndicatorView.superViewSize = self.view.frame.size
        self.loadingIndicatorView.updateFrame()
        self.loadingIndicatorView.isHidden = false
        self.loadingIndicatorView.startAnimating()
        
        let params = SBDGroupChannelParams()
        if self.coverImage != nil {
            params.coverImage = self.coverImage?.jpegData(compressionQuality: 0.5)
        }
        else {
            params.coverUrl = self.channel?.coverUrl
        }
        
        params.name = self.channelNameTextField.text
        
        if let channel = self.channel {
            channel.update(with: params) { (channel, error) in
                self.loadingIndicatorView.isHidden = true
                self.loadingIndicatorView.stopAnimating()
                
                if let error = error {
                    Utils.showAlertController(error: error, viewController: self)
                    return
                }
                
                if let delegate = self.delegate {
                    delegate.didUpdateGroupChannel()
                }
                
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}
