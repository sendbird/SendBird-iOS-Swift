//
//  SettingsViewController.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 10/17/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import Photos
import AlamofireImage
import MobileCoreServices

class SettingsViewController: UITableViewController, SettingsTableViewCellDelegate, UserProfileImageNameSettingDelegate, NotificationDelegate {

    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var userIdLabel: UILabel!
    
    
    var showPreview: Bool = false
    var createDistinctChannel: Bool = true

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Settings"
        self.navigationItem.largeTitleDisplayMode = .automatic

        self.nicknameLabel.text = SBDMain.getCurrentUser()?.nickname
        if SBDMain.getCurrentUser()?.nickname!.count == 0 {
            self.nicknameLabel.attributedText = NSAttributedString(string: "Please write your nickname", attributes: [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16.0, weight: .regular),
                NSAttributedString.Key.foregroundColor: UIColor.gray as Any
                ])
        }
        self.userIdLabel.text = SBDMain.getCurrentUser()?.userId
        DispatchQueue.main.async {
            self.profileImageView.setProfileImageView(for: SBDMain.getCurrentUser()!)
        }

        self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 14, right: 0)
        
        if let showPreview = UserDefaults.standard.object(forKey: Constants.ID_SHOW_PREVIEWS) as? Bool {
            self.showPreview = showPreview
        }
        
        if let createDistinctChannel = UserDefaults.standard.object(forKey: Constants.ID_CREATE_DISTINCT_CHANNEL) as? Bool {
            self.createDistinctChannel = createDistinctChannel
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "UpdateUserProfile", let destination = segue.destination as? UpdateUserProfileViewController{
            destination.delegate = self
        }
    }

    // MARK: - NotificationDelegate
    func openChat(_ channelUrl: String) {
        (self.navigationController?.parent as? UITabBarController)?.selectedIndex = 0
        
        if let cvc = UIViewController.currentViewController() as? NotificationDelegate{
            cvc.openChat(channelUrl)
        }
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    // MARK: - UITableViewDataSource
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            performSegue(withIdentifier: "UpdateUserProfile", sender: nil)
        } else if indexPath.section == 1{
            performSegue(withIdentifier: "ShowTimeSettings", sender: nil)
        } else if indexPath.section == 3 {
            performSegue(withIdentifier: "ShowBlockedList", sender: nil)
        }
        else if indexPath.section == 4 {
            let alert = UIAlertController(title: "Sign Out", message: "Do you want to sign out?", preferredStyle: .alert)
            let actionConfirm = UIAlertAction(title: "OK", style: .default) { (action) in
                
                if let pushToken = SBDMain.getPendingPushToken() {
                    SBDMain.unregisterPushToken(pushToken, completionHandler: { (response, error) in
                        /// Fixed Optional Problem(.getPendingPushToken()! -> pushToken)
                    })
                }
                
                ConnectionManager.logout {
                    self.dismiss(animated: true, completion: nil)
                }
            }
            let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            alert.addAction(actionConfirm)
            alert.addAction(actionCancel)
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - SettingsTableViewCellDelegate
    func didChangeSwitchButton(isOn: Bool, identifier: String) {
      if identifier == Constants.ID_SHOW_PREVIEWS {
            UserDefaults.standard.set(isOn, forKey: Constants.ID_SHOW_PREVIEWS)
            UserDefaults.standard.synchronize()
            self.showPreview = isOn
        }
        else if identifier == Constants.ID_CREATE_DISTINCT_CHANNEL {
            UserDefaults.standard.set(isOn, forKey: Constants.ID_CREATE_DISTINCT_CHANNEL)
            UserDefaults.standard.synchronize()
            
            self.createDistinctChannel = isOn
        }
    }
    
    // MARK: - UserProfileImageNameSettingDelegate
    func didUpdateUserProfile() {
        self.nicknameLabel.text = SBDMain.getCurrentUser()?.nickname
        if SBDMain.getCurrentUser()?.nickname!.count == 0 {
            self.nicknameLabel.attributedText = NSAttributedString(string: "Please write your nickname", attributes: [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16.0, weight: .regular),
                NSAttributedString.Key.foregroundColor: UIColor.gray as Any
                ])
        }
        self.userIdLabel.text = SBDMain.getCurrentUser()?.userId
        DispatchQueue.main.async {
            self.profileImageView.setProfileImageView(for: SBDMain.getCurrentUser()!)
        }
    }
}
