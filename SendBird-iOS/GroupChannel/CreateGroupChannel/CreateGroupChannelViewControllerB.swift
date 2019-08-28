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
    @IBOutlet weak var loadingIndicatorView: CustomActivityIndicatorView!

    var coverImageData: Data?
    var createButtonItem: UIBarButtonItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
    }
    
    @objc func clickCoverImage(_ sender: AnyObject) {
        
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
        
        Utils.showAlertControllerWithActions([actionPhoto, actionLibrary, actionCancel],
                                             title: nil,
                                             frame: CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0),
                                             viewController: self)
        
    }
    
    @objc func clickCreateGroupChannel(_ sender: AnyObject) {
        self.showLoadingIndicatorView()
        
        let channelName = self.channelNameTextField.text != "" ? self.channelNameTextField.text : self.channelNameTextField.placeholder
        
        let params = SBDGroupChannelParams()
        params.coverImage = self.coverImageData
        params.add(self.members)
        params.name = channelName
        
        
        SBDGroupChannel.createChannel(with: params) { (channel, error) in
            self.hideLoadingIndicatorView()
            
            if let error = error {
                let alertController = UIAlertController(title: "Error", message: error.domain, preferredStyle: .alert)
                let actionCancel = UIAlertAction(title: "Close", style: .cancel, handler: nil)
                alertController.addAction(actionCancel)
                DispatchQueue.main.async {
                    self.present(alertController, animated: true, completion: nil)
                }
            
                return
            }


            if let navigationController = self.navigationController as? CreateGroupChannelNavigationController{
                if (navigationController.channelCreationDelegate?.responds(to: #selector(CreateGroupChannelNavigationController.didChangeValue(forKey:))))! {
                    navigationController.channelCreationDelegate?.didCreateGroupChannel(channel!)
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
