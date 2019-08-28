//
//  OpenChannelMutedUserListViewController.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 11/2/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK

enum UserListType {
    case banned, muted, participant
}

class OpenChannelUserListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NotificationDelegate {

    @IBOutlet weak var usersTableView: UITableView!
    @IBOutlet weak var emptyLabel: UILabel!

    var channel: SBDOpenChannel?
    
    private var userListQuery: SBDUserListQuery?
    private var users: [SBDUser] = []
    private var refreshControl: UIRefreshControl?
    
    var userListType: UserListType = .participant
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        switch userListType{
        case .banned:
            self.title = "Banned Users"
            self.emptyLabel.text = "There are no banned users"
        case .muted:
            self.title = "Muted Users"
            self.emptyLabel.text = "There are no muted users"
        case .participant:
            self.title = "Participants"
            self.emptyLabel.isHidden = true
        }
        self.navigationItem.largeTitleDisplayMode = .automatic
      
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(OpenChannelUserListViewController.refreshMutedUserList), for: .valueChanged)
        
        self.usersTableView.refreshControl = self.refreshControl
        
        self.usersTableView.delegate = self
        self.usersTableView.dataSource = self
        
        self.loadUserListNextPage(refresh: true)
    }

    @objc func refreshMutedUserList() {
        self.loadUserListNextPage(refresh: true)
    }
    
    func loadUserListNextPage(refresh: Bool) {
        if refresh {
            self.userListQuery = nil
        }
        
        guard let channel = self.channel else { return }
        if self.userListQuery == nil {
            switch userListType {
            case .banned:
                self.userListQuery = channel.createBannedUserListQuery()
            case .muted:
                self.userListQuery = channel.createMutedUserListQuery()
            case .participant:
                self.userListQuery = channel.createParticipantListQuery()
            }
            self.userListQuery?.limit = 20
        }
        
        if self.userListQuery?.hasNext == false {
            return
        }
        
        self.userListQuery?.loadNextPage(completionHandler: { (users, error) in
            if error != nil {
                DispatchQueue.main.async {
                    self.refreshControl?.endRefreshing()
                }
                return
            }
            
            DispatchQueue.main.async {
                if refresh {
                    self.users.removeAll()
                }
                
                self.users += users!
                self.usersTableView.reloadData()
                
                self.refreshControl?.endRefreshing()
            }
        })
    }
    
    // MARK: - NotificationDelegate
    func openChat(_ channelUrl: String) {
        guard let navigationController = self.navigationController else { return }
        navigationController.popViewController(animated: false)
        if let cvc = UIViewController.currentViewController() as? NotificationDelegate {
            cvc.openChat(channelUrl)
        }
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        
        if let userCell = tableView.dequeueReusableCell(withIdentifier: "OpenChannelSettingsUserTableViewCell") as? OpenChannelSettingsUserTableViewCell {
            let user = self.users[indexPath.row]
            userCell.nicknameLabel.text = user.nickname
            userCell.user = user
            
            cell = userCell
            
            DispatchQueue.main.async {
                if let updateCell = tableView.cellForRow(at: indexPath) as? OpenChannelSettingsUserTableViewCell {
                    
                    updateCell.profileImageView.setProfileImageView(for: self.users[indexPath.row])
                }
            }
        }
        
        if self.users.count > 0 && indexPath.row == self.users.count - 1 {
            self.loadUserListNextPage(refresh: false)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.users.count == 0 && self.userListType != .participant{
            self.emptyLabel.isHidden = false
        }
        else {
            self.emptyLabel.isHidden = true
        }
        
        return self.users.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let user = self.users[indexPath.row]
        
        switch userListType{
        case .banned:
            let bannedUser = self.users[indexPath.row]
            
            let actionSeeProfile = UIAlertAction(title: "See profile", style: .default) { (action) in
                let userProfileVC = UserProfileViewController.init(nibName: "UserProfileViewController", bundle: nil)
                userProfileVC.user = bannedUser
                DispatchQueue.main.async {
                    guard let navigationController = self.navigationController else { return }
                    navigationController.pushViewController(userProfileVC, animated: true)
                }
            }
            
            let actionUnbanUser = UIAlertAction(title: "Unban user", style: .default) { (action) in
                guard let channel = self.channel else { return }
                channel.unbanUser(bannedUser, completionHandler: { (error) in
                    if error != nil {
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self.users.removeObject(bannedUser)
                        self.usersTableView.reloadData()
                    }
                })
            }
            
            let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            Utils.showAlertControllerWithActions([actionSeeProfile, actionUnbanUser, actionCancel],
                                                 title: nil,
                                                 frame: CGRect(x: self.view.bounds.minX, y: self.view.bounds.maxY,width: 0, height: 0),
                                                 viewController: self
            )
            
        case .muted:
            let actionSeeProfile = UIAlertAction(title: "See profile", style: .default) { (action) in
                let userProfileVC = UserProfileViewController.init(nibName: "UserProfileViewController", bundle: nil)
                userProfileVC.user = user
                DispatchQueue.main.async {
                    guard let navigationController = self.navigationController else { return }
                    navigationController.pushViewController(userProfileVC, animated: true)
                }
            }
            
            let actionUnmuteUser = UIAlertAction(title: "Unmute user", style: .default) { (action) in
                guard let channel = self.channel else { return }
                channel.unmuteUser(user, completionHandler: { (error) in
                    if error != nil {
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self.users.removeObject(user)
                        self.usersTableView.reloadData()
                    }
                })
            }
            
            let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            Utils.showAlertControllerWithActions([actionSeeProfile, actionUnmuteUser, actionCancel],
                                                 title: nil,
                                                 frame: CGRect(x: self.view.bounds.minX, y: self.view.bounds.maxY, width: 0, height: 0),
                                                 viewController: self
            )
            
        case .participant:
            let participant = self.users[indexPath.row]
            let userProfileVC = UserProfileViewController.init(nibName: "UserProfileViewController", bundle: nil)
            userProfileVC.user = participant
            DispatchQueue.main.async {
                guard let navigationController = self.navigationController else { return }
                navigationController.pushViewController(userProfileVC, animated: true)
            }
        }
        
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
}
