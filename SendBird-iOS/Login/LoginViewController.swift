//
//  LoginViewController.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 10/3/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import Photos

class LoginViewController: UIViewController, UITextFieldDelegate, SBDAuthenticateDelegate, NotificationDelegate {
    
    private var keyboardShown: Bool = false
    private var logoChanged: Bool = false
    private var logoInvisble: Bool = false
    
    @IBOutlet weak var connectButton: CustomButton!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var nicknameTextField: CustomTextField!
    @IBOutlet weak var scrollViewBottom: NSLayoutConstraint!
    @IBOutlet weak var userIdLabelTop: NSLayoutConstraint!
    @IBOutlet weak var userIdTextField: CustomTextField!
    @IBOutlet weak var versionInfoLabel: UILabel!
    
    // MARK: - Override
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        SBDConnectionManager.setAuthenticateDelegate(self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.keyboardWillShow(_:)), name: UIWindow.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LoginViewController.keyboardWillHide(_:)), name: UIWindow.keyboardWillHideNotification, object: nil)
        let contentViewTapRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(LoginViewController.tapContentView))
        
        self.contentView.isUserInteractionEnabled = true
        self.contentView.addGestureRecognizer(contentViewTapRecognizer)
        
        self.userIdTextField.delegate = self
        self.nicknameTextField.delegate = self
        
        self.setupUI()
    }
    
    func setupUI() {
        if let userId = UserDefaults.standard.object(forKey: "sendbird_user_id") as? String {
            self.userIdTextField.text = userId
        }
        if let nickname = UserDefaults.standard.object(forKey: "sendbird_user_nickname") as? String {
            self.nicknameTextField.text = nickname
        }
        
        // Version
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"){
            if let infoDict = NSDictionary.init(contentsOfFile: path), let sampleUIVersion = infoDict["CFBundleShortVersionString"] as? String {
                let version = "Sample UI v\(sampleUIVersion) / SDK v\(SBDMain.getSDKVersion())"
                self.versionInfoLabel.text = version
            }
        }
        
        let authStatus = PHPhotoLibrary.authorizationStatus()
        if authStatus != PHAuthorizationStatus.authorized {
            PHPhotoLibrary.requestAuthorization { (status) in
                
            }
        }
        
        let autoLogin = UserDefaults.standard.bool(forKey: "sendbird_auto_login")
        if autoLogin {
            self.connect()
        }
    }
    
    // MARK: - Keyboard
    // Show
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrameBegin = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else  { return }
        let keyboardFrameBeginRect = keyboardFrameBegin.cgRectValue
        
        if !self.keyboardShown {
            let distanceFromBottom = self.view.frame.height - self.connectButton.frame.maxY
            if distanceFromBottom <= keyboardFrameBeginRect.size.height + 90 {
                animateUI(keyboardFrameBeginRect.size.height)
            }
        }
        self.keyboardShown = true
    }
    
    // Hide
    @objc func keyboardWillHide(_ notification: Notification) {
        if self.keyboardShown && logoInvisble {
            animateUI(0)
        }
        self.keyboardShown = false
    }
    
    // Disable
    @objc func tapContentView() {
        if self.keyboardShown == true {
            self.view.endEditing(true)
        }
    }
    
    // MARK: - IBAction
    @IBAction func didTapConnectButton() {
        self.connect()
    }
    
    // MARK: - Functions
    // Animation during showing / hiding keyboard
    func animateUI(_ scrollValue: CGFloat) {
        self.view.layoutIfNeeded()
        self.scrollViewBottom.constant = scrollValue
        
        let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeOut) {
            self.userIdLabelTop.constant = !self.keyboardShown ? 23 : 56
            self.view.layoutIfNeeded()
            self.versionInfoLabel.alpha = self.keyboardShown ? 1 : 0
        }
        animator.startAnimation()
        logoInvisble = !logoInvisble
    }
    
    
    func connect() {
        self.view.endEditing(true)
        if SBDMain.getConnectState() == .open {
            SBDMain.disconnect {
                DispatchQueue.main.async {
                    self.setUIsForDefault()
                }
            }
        }
        else {
            let userId = self.userIdTextField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let nickname = self.nicknameTextField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            if userId?.count == 0 || nickname?.count == 0 {
                Utils.showAlertController(title: "Error", message: "User ID and Nickname are required.", viewController: self)
                
                return
            }
            
            let userDefault = UserDefaults.standard
            userDefault.setValue(userId, forKey: "sendbird_user_id")
            userDefault.setValue(nickname, forKey: "sendbird_user_nickname")
            
            self.setUIsWhileConnecting()
            
            SBDConnectionManager.setAuthenticateDelegate(self)
            SBDConnectionManager.authenticate()
        }
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.userIdTextField {
            textField.resignFirstResponder()
            self.nicknameTextField.becomeFirstResponder()
        } else {
            self.connect()
        }
        
        return true
    }
    
    // MARK: - SBDAuthenticateDelegate
    func shouldHandleAuthInfo(completionHandler: @escaping (String?, String?, String?, String?) -> Void) {
        let userId = UserDefaults.standard.object(forKey: "sendbird_user_id") as? String
        completionHandler(userId, nil, nil, nil)
    }
    
    func didFinishAuthentication(with user: SBDUser?, error: SBDError?) {
        if error != nil {
            DispatchQueue.main.async {
                self.setUIsForDefault()
            }
            Utils.showAlertController(error: error!, viewController: self)
            
            return
        }
        
        UserDefaults.standard.setValue(true, forKey: "sendbird_auto_login")
        
        DispatchQueue.main.async {
            self.setUIsForDefault()
            
            self.performSegue(withIdentifier: "LoggedIn", sender: self)
        }
        
        SBDMain.getDoNotDisturb { (isDoNotDisturbOn, startHour, startMin, endHour, endMin, timezone, error) in
            UserDefaults.standard.set(startHour, forKey: "sendbird_dnd_start_hour")
            UserDefaults.standard.set(startMin, forKey: "sendbird_dnd_start_min")
            UserDefaults.standard.set(endHour, forKey: "sendbird_dnd_end_hour")
            UserDefaults.standard.set(endMin, forKey: "sendbird_dnd_end_min")
            UserDefaults.standard.set(isDoNotDisturbOn, forKey: "sendbird_dnd_on")
            UserDefaults.standard.synchronize()
        }
        
        if let deviceToken = SBDMain.getPendingPushToken() {
            SBDMain.registerDevicePushToken(deviceToken, unique: true) { (status, error) in
                if error == nil {
                    if status == SBDPushTokenRegistrationStatus.pending {
                        print("Push registration is pending.")
                    }
                    else {
                        print("APNS Token is registered.")
                    }
                }
                else {
                    print("APNS registration failed with error: \(String(describing: error))")
                }
            }
        }
        
        if let nickname = UserDefaults.standard.object(forKey: "sendbird_user_nickname") as? String, nickname != SBDMain.getCurrentUser()?.nickname {
            SBDMain.updateCurrentUserInfo(withNickname: nickname, profileUrl: nil) { (error) in
                if error != nil {
                    SBDMain.disconnect(completionHandler: {
                        Utils.showAlertController(error: error!, viewController: self)
                    })
                    
                    return
                }
            }
        }
    }
    
    // MARK: NotificationDelegate
    func openChat(_ channelUrl: String) {
        self.navigationController?.popViewController(animated: false)
        let tabBarVC = MainTabBarController.init(nibName: "MainTabBarController", bundle: nil)
        self.present(tabBarVC, animated: false) {
            let vc = UIViewController.currentViewController()
            if vc is GroupChannelsViewController {
                (vc as! GroupChannelsViewController).openChat(channelUrl)
            }
        }
    }
    
    private func setUIsWhileConnecting() {
        self.userIdTextField.isEnabled = false
        self.nicknameTextField.isEnabled = false
        self.connectButton.isEnabled = false
        self.connectButton.setTitle("Connecting...", for: .normal)
    }
    
    private func setUIsForDefault() {
        self.userIdTextField.isEnabled = true
        self.nicknameTextField.isEnabled = true
        self.connectButton.isEnabled = true
        self.connectButton.setTitle("Connect", for: .normal)
    }
}
