//
//  UpdateUserProfileViewController.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 10/17/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import RSKImageCropper
import Photos
import MobileCoreServices
import AlamofireImage
import SendBirdSDK

class UpdateUserProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, RSKImageCropViewControllerDelegate, NotificationDelegate {
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nicknameTextField: UITextField!
    @IBOutlet weak var loadingIndicatorView: CustomActivityIndicatorView!
    
    weak var delegate: UserProfileImageNameSettingDelegate?
    
    var user: SBDUser?
    var profileImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Profile Image & Name"
        self.navigationItem.largeTitleDisplayMode = .never
        
        let barButtonItemBack = UIBarButtonItem(title: "Back", style: .plain, target: self, action: nil)
        if let prevVC = self.navigationController?.viewControllers[(self.navigationController?.viewControllers.count)! - 2] {
            prevVC.navigationItem.backBarButtonItem = barButtonItemBack
        }
        
        let barButtonItemDone = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(UpdateUserProfileViewController.clickDoneButton(_:)))
        self.navigationItem.rightBarButtonItem = barButtonItemDone
        
        self.loadingIndicatorView.isHidden = true
        self.view.bringSubviewToFront(self.loadingIndicatorView)
        
        self.profileImageView.isUserInteractionEnabled = true
        let tapProfileImageGesture = UITapGestureRecognizer(target: self, action: #selector(UpdateUserProfileViewController.clickProfileImage))
        self.profileImageView.addGestureRecognizer(tapProfileImageGesture)
        
        self.profileImageView.setProfileImageView(for: SBDMain.getCurrentUser()!)
        
        self.nicknameTextField.text = SBDMain.getCurrentUser()!.nickname
        self.nicknameTextField.attributedPlaceholder = NSAttributedString(string: "Please write your nickname", attributes: [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0, weight: .regular),
            NSAttributedString.Key.foregroundColor: UIColor(named: "color_channelname_nickname_placeholder") as Any
            ])
    }
    
    @objc func clickDoneButton(_ sender: AnyObject) {
        self.updateUserProfile()
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
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let mediaType = info[UIImagePickerController.InfoKey.mediaType] as! CFString
        picker.dismiss(animated: true) {
            if CFStringCompare(mediaType, kUTTypeImage, []) == .compareEqualTo {
                if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                    if let imageData = originalImage.jpegData(compressionQuality: 1.0) {
                        self.cropImage(imageData)
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
        self.profileImage = croppedImage
        self.profileImageView.image = croppedImage
        
        controller.dismiss(animated: false, completion: nil)
    }
    
    // The original image will be cropped.
    func imageCropViewController(_ controller: RSKImageCropViewController, willCropImage originalImage: UIImage) {
        // Use when `applyMaskToCroppedImage` set to true
    }
    
    @objc func clickProfileImage(_ sender: AnyObject) {
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
                                             frame: CGRect(x: self.view.bounds.minX, y: self.profileImageView.bounds.maxY + self.profileImageView.frame.height * 1.5, width: 0, height: 0),
                                             viewController: self
        )
    }

    func updateUserProfile() {
        let imageData = self.profileImage?.jpegData(compressionQuality: 0.5)
        self.loadingIndicatorView.isHidden = false
        self.loadingIndicatorView.startAnimating()
        SBDMain.updateCurrentUserInfo(withNickname: self.nicknameTextField.text, profileImage: imageData) { (error) in
            DispatchQueue.main.async {
                self.loadingIndicatorView.isHidden = true
                self.loadingIndicatorView.stopAnimating()
            }
            
            UserDefaults.standard.set(SBDMain.getCurrentUser()!.nickname, forKey: "sendbird_user_nickname")
            UserDefaults.standard.synchronize()
            
            self.delegate?.didUpdateUserProfile()
            self.navigationController?.popViewController(animated: true)
        }
    }
}
