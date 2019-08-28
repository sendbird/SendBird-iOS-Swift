//
//  CreateOpenChannelViewControllerA.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 10/16/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import RSKImageCropper
import MobileCoreServices
import Photos

class CreateOpenChannelViewControllerA: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, RSKImageCropViewControllerDelegate, NotificationDelegate {

    var cancelButton: UIBarButtonItem?
    var nextButton: UIBarButtonItem?
    @IBOutlet weak var channelNameTextField: UITextField!
    @IBOutlet weak var coverImageView: UIImageView!
    
    var coverImageData: Data?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.title = "Create Open Channel"
        self.navigationItem.largeTitleDisplayMode = .never
        
        self.cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(CreateOpenChannelViewControllerA.clickCancelButton(_:)))
        self.navigationItem.leftBarButtonItem = self.cancelButton
        
        self.nextButton = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(CreateOpenChannelViewControllerA.clickNextButton(_:)))
        self.navigationItem.rightBarButtonItem = self.nextButton
        
        if self.channelNameTextField.text!.count > 0 {
            self.nextButton?.isEnabled = true
        }
        else {
            self.nextButton?.isEnabled = false
        }
        
        self.channelNameTextField.attributedPlaceholder = NSAttributedString(string: "Channel Name", attributes: [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0, weight: .regular),
            NSAttributedString.Key.foregroundColor: UIColor(named: "color_channelname_nickname_placeholder") as Any
            ])
        
        NotificationCenter.default.addObserver(self, selector: #selector(CreateOpenChannelViewControllerA.textFieldDidChangeNotification(_:)), name: UITextField.textDidChangeNotification, object: nil)
        let clickCoverImageRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(CreateOpenChannelViewControllerA.clickCoverImage(_:)))
        self.coverImageView.isUserInteractionEnabled = true
        self.coverImageView.addGestureRecognizer(clickCoverImageRecognizer)
        
        // Set the default cover image randomly.
        let r = arc4random() % 5
        switch r {
        case 0:
            self.coverImageView.image = UIImage(named: "img_default_cover_image_1")
            break
        case 1:
            self.coverImageView.image = UIImage(named: "img_default_cover_image_2")
            break
        case 2:
            self.coverImageView.image = UIImage(named: "img_default_cover_image_3")
            break
        case 3:
            self.coverImageView.image = UIImage(named: "img_default_cover_image_4")
            break
        case 4:
            self.coverImageView.image = UIImage(named: "img_default_cover_image_5")
            break
        default:
            self.coverImageView.image = UIImage(named: "img_default_cover_image_1")
            break
        }
    }
    
    @objc func clickCancelButton(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func clickCoverImage(_ sender: AnyObject) {
        print("clickCoverImage/CreateOpenChannelViewController")
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
            presenter.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            presenter.permittedArrowDirections = []
        }
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func textFieldDidChangeNotification(_ notification: Notification) {
        if (self.channelNameTextField.text?.count)! > 0 {
            self.nextButton?.isEnabled = true
        }
        else {
            self.nextButton?.isEnabled = false
        }
    }
    
    // MARK: - NotificationDelegate
    func openChat(_ channelUrl: String) {
        self.dismiss(animated: false) {
            if let cvc = UIViewController.currentViewController() as? NotificationDelegate {
                cvc.openChat(channelUrl)
            }
        }
    }
    

     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ConfigureOpenChannel", let destination = segue.destination as? CreateOpenChannelViewControllerB{
            destination.channelName = self.channelNameTextField.text
            destination.coverImageData = self.coverImageData ?? self.coverImageView.image?.jpegData(compressionQuality: 0.5)
        }
     }
    
    @objc func clickNextButton(_ sender: AnyObject) {
        performSegue(withIdentifier: "ConfigureOpenChannel", sender: nil)
    }
    
    func cropImage(_ imageData: Data) {
        if let image = UIImage(data: imageData){
            let imageCropVC = RSKImageCropViewController(image: image)
            imageCropVC.delegate = self
            imageCropVC.cropMode = .square
            self.present(imageCropVC, animated: false, completion: nil)
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
        self.coverImageView.image = croppedImage
        self.coverImageData = croppedImage.jpegData(compressionQuality: 0.5)
        controller.dismiss(animated: false, completion: nil)
    }
    
    // The original image will be cropped.
    func imageCropViewController(_ controller: RSKImageCropViewController, willCropImage originalImage: UIImage) {
        // Use when `applyMaskToCroppedImage` set to true
    }
}
