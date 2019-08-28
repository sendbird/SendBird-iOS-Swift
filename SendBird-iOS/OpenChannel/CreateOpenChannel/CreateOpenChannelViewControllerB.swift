//
//  CreateOpenChannelViewControllerB.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 10/16/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import AlamofireImage

class CreateOpenChannelViewControllerB: UIViewController, SelectOperatorsDelegate, UITableViewDelegate, UITableViewDataSource, NotificationDelegate {
    var channelName: String?
    var coverImageData: Data?
    var channelUrl: String?
    var doneButtonItem: UIBarButtonItem?
    var selectedUsers: [String:SBDUser] = [:]
    var viewTapGestureRecognizer: UITapGestureRecognizer?
    
    
    @IBOutlet weak var bottomMargin: NSLayoutConstraint!
    @IBOutlet weak var activityIndicatorView: CustomActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Create Open Channel"
        self.navigationItem.largeTitleDisplayMode = .never
       
        self.doneButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(CreateOpenChannelViewControllerB.clickDoneButton(_:)))
        self.navigationItem.rightBarButtonItem = self.doneButtonItem
        
        self.channelUrl = String.randomUUIDString()
        
        self.activityIndicatorView.isHidden = true
        self.view.bringSubviewToFront(self.activityIndicatorView)

        NotificationCenter.default.addObserver(self, selector: #selector(CreateOpenChannelViewControllerB.keyboardWillShow(_:)), name: UIWindow.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CreateOpenChannelViewControllerB.keyboardWillHide(_:)), name: UIWindow.keyboardWillHideNotification, object: nil)
        
        viewTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard(recognizer:)))
        self.tableView.addGestureRecognizer(viewTapGestureRecognizer!)
        viewTapGestureRecognizer?.isEnabled = false
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
    @objc func clickDoneButton(_ sender: AnyObject) {
        self.activityIndicatorView.superViewSize = self.view.frame.size
        self.activityIndicatorView.updateFrame()
        
        self.activityIndicatorView.isHidden = false
        self.activityIndicatorView.startAnimating()
        var operatorIds: [String] = []
        operatorIds += self.selectedUsers.keys
        operatorIds.append((SBDMain.getCurrentUser()?.userId)!)
        let channelUrl = self.channelUrl
        
        SBDOpenChannel.createChannel(withName: self.channelName, channelUrl: channelUrl, coverImage: self.coverImageData!, coverImageName: "cover_image.jpg", data: nil, operatorUserIds: operatorIds, customType: nil, progressHandler: nil) { (channel, error) in
            if let error = error {
                self.activityIndicatorView.isHidden = true
                self.activityIndicatorView.stopAnimating()
                
                Utils.showAlertController(error: error, viewController: self)
                
                return
            }
            
            if let nc = self.navigationController as? CreateOpenChannelNavigationController {
                
                if let delegate = nc.createChannelDelegate {
                    delegate.didCreate!(channel!)
                }
            }
            
            channel?.enter(completionHandler: { (error) in
                self.activityIndicatorView.isHidden = true
                self.activityIndicatorView.stopAnimating()
                
                if let error = error {
                    Utils.showAlertController(error: error, viewController: self)
                    
                    return
                }
                
                self.navigationController?.dismiss(animated: true, completion: nil)
                
            })
        }
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        
        let (height, _, _) = Utils.getKeyboardAnimationOptions(notification: notification)
        
        DispatchQueue.main.async {
            self.bottomMargin.constant = (height ?? 0) - self.view.safeAreaInsets.bottom
            self.view.layoutIfNeeded()
        }
        viewTapGestureRecognizer?.isEnabled = true
    }
    
    
    @objc func keyboardWillHide(_ notification: Notification) {
        
        DispatchQueue.main.async {
                self.bottomMargin.constant = 0
                self.view.layoutIfNeeded()
        }
        viewTapGestureRecognizer?.isEnabled = false
    }
    
    @objc func hideKeyboard(recognizer: UITapGestureRecognizer) {
        if recognizer.state == .ended {
            self.view.endEditing(true)
        }
    }
    
    
    // MARK: - NotificationDelegate
    func openChat(_ channelUrl: String) {
        self.navigationController?.popViewController(animated: false)
        if let cvc = UIViewController.currentViewController() as? NotificationDelegate {
            cvc.openChat(channelUrl)
        }
    }
    
    // MARK: - SelectOperatorsDelegate
    func didSelectUsers(_ users: [String : SBDUser]) {
        self.selectedUsers = users
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    

     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SelectOperators", let destination = segue.destination as? SelectOperatorsViewController{
            destination.title = "Select an operator"
            destination.delegate = self
            destination.selectedUsers = self.selectedUsers
        }
     }
 
    // MARK: - UITableViewDelegate

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: false)
        if indexPath.section == 1, indexPath.row == 0 {
            performSegue(withIdentifier: "SelectOperators", sender: nil)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (section == 0) ? 1 : self.selectedUsers.count + 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return (section == 1) ? "Operators" : nil
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return (section == 0) ? "Channel URL is a unique value to identify a channel" : nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0, let channelUrlCell = tableView.dequeueReusableCell(withIdentifier: "CreateOpenChannelChannelUrlTableViewCell") as? CreateOpenChannelChannelUrlTableViewCell {
                channelUrlCell.channelUrlTextField.text = self.channelUrl
                channelUrlCell.channelUrlTextField.addTarget(self, action: #selector(CreateOpenChannelViewControllerB.channelUrlChanged(_:)), for: .editingChanged)
                
                return channelUrlCell
        }
        else if indexPath.section == 1 {
            switch indexPath.row{
            case 0:
                return tableView.dequeueReusableCell(withIdentifier: "CreateOpenChannelAddOperatorTableViewCell") ?? UITableViewCell()
            case 1:
                if let currentUserCell = tableView.dequeueReusableCell(withIdentifier: "CreateOpenChannelUserTableViewCell") as? CreateOpenChannelUserTableViewCell {
                    currentUserCell.nicknameLabel.text = SBDMain.getCurrentUser()?.nickname
                    DispatchQueue.main.async {
                        if let updateCell = tableView.cellForRow(at: indexPath) as? CreateOpenChannelUserTableViewCell {
                            updateCell.profileImageView.setProfileImageView(for: SBDMain.getCurrentUser()!)
                        }
                    }
                    
                    return currentUserCell
                }
            default:
                if let operatorCell = tableView.dequeueReusableCell(withIdentifier: "CreateOpenChannelUserTableViewCell") as? CreateOpenChannelUserTableViewCell {
                    let op = Array(self.selectedUsers.values)[indexPath.row - 2]
                    operatorCell.user = op
                    operatorCell.nicknameLabel.text = op.nickname
                    operatorCell.meLabel.isHidden = true
                    operatorCell.profileCoverView.isHidden = true
                    DispatchQueue.main.async {
                        if let updateCell = tableView.cellForRow(at: indexPath) as? CreateOpenChannelUserTableViewCell{
                            updateCell.profileImageView.setProfileImageView(for: op)
                        }
                    }

                    return operatorCell
                }
            }
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.section == 1, indexPath.row > 1 {
            let delete = UIContextualAction(style: .destructive, title: "Remove") { (action, view, completionHandler) in
                if let op = (view as? CreateOpenChannelUserTableViewCell)?.user {
                    self.selectedUsers.removeValue(forKey: op.userId)
                }
                completionHandler(true)
            }
            return UISwipeActionsConfiguration(actions: [delete])
        }
        return UISwipeActionsConfiguration(actions: [])
    }
    
    @objc func channelUrlChanged(_ sender: AnyObject) {
        if let textField = sender as? UITextField {
            self.channelUrl = textField.text
        }
    }
}
