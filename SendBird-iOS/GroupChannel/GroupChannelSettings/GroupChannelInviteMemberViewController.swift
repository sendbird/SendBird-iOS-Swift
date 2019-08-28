//
//  GroupChannelInviteMemberViewController.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 11/16/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK

class GroupChannelInviteMemberViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, NotificationDelegate {

    weak var delegate: GroupChannelInviteMemberDelegate?
    
    var selectedUsers: [String:SBDUser] = [:]
    var channel: SBDGroupChannel?
    var users: [SBDUser] = []
    var userListQuery: SBDApplicationUserListQuery?
    var refreshControl: UIRefreshControl?
    var searchController: UISearchController?
    var okButtonItem: UIBarButtonItem?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var updatingIndicatorView: CustomActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Invite Members"
      
        self.okButtonItem = UIBarButtonItem.init(title: "OK(0)", style: .plain, target: self, action: #selector(GroupChannelInviteMemberViewController.clickOkButton(_:)))
        self.navigationItem.rightBarButtonItem = self.okButtonItem
        
        self.view.bringSubviewToFront(self.updatingIndicatorView)
        self.updatingIndicatorView.isHidden = true
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.register(SelectableUserTableViewCell.nib(), forCellReuseIdentifier: "SelectableUserTableViewCell")
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(refreshUserList), for: .valueChanged)
        self.tableView.refreshControl = self.refreshControl
        
        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController?.searchBar.delegate = self
        self.searchController?.searchBar.placeholder = "User ID"
        self.searchController?.obscuresBackgroundDuringPresentation = false
        self.navigationItem.searchController = self.searchController
        self.navigationItem.hidesSearchBarWhenScrolling = false
        self.searchController?.searchBar.tintColor = UIColor(named: "color_bar_item")
        
        self.userListQuery = nil
        
        if self.selectedUsers.count == 0 {
            self.okButtonItem?.isEnabled = false
        }
        else {
            self.okButtonItem?.isEnabled = true
        }
        
        self.okButtonItem?.title = String(format: "OK(%d)", self.selectedUsers.count)
        
        self.refreshUserList()
    }

    // MARK: - NotificationDelegate
    func openChat(_ channelUrl: String) {
        
        navigationController?.popViewController(animated: false)
        
        if let cvc = UIViewController.currentViewController() as? NotificationDelegate {
            cvc.openChat(channelUrl)
        }
    }
    
    @objc func refreshUserList() {
        self.loadUserListNextPage(refresh: false)
    }
    
    func loadUserListNextPage(refresh: Bool) {
        if refresh {
            self.userListQuery = nil
        }
        
        if self.userListQuery == nil {
            self.userListQuery = SBDMain.createApplicationUserListQuery()
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
                
                for user in users ?? [] {
                    if user.userId == SBDMain.getCurrentUser()?.userId {
                        continue
                    }
                    self.users.append(user)
                }
                
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
            }
        })
    }
    
    @objc func clickOkButton(_ sender: Any) {
        guard let channel = self.channel else { return }
            
        self.updatingIndicatorView.isHidden = false
        self.updatingIndicatorView.startAnimating()
        
        channel.invite(Array(self.selectedUsers.values) as [SBDUser]) { (error) in
            self.updatingIndicatorView.isHidden = true
            self.updatingIndicatorView.stopAnimating()
            
            if let error = error {
                let vc = UIAlertController(title: "Error", message: error.domain, preferredStyle: .alert)
                let actionClose = UIAlertAction(title: "Close", style: .cancel, handler: nil)
                vc.addAction(actionClose)
                self.present(vc, animated: true, completion: nil)
                
                return
            }
            
            if let delegate = self.delegate {
                if delegate.responds(to: #selector(GroupChannelInviteMemberDelegate.didInviteMembers)) {
                    delegate.didInviteMembers!()
                }
            }
            if let navigationController = self.navigationController {
                navigationController.popViewController(animated: true)
            }
        }
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SelectableUserTableViewCell", for: indexPath) as! SelectableUserTableViewCell
        
        cell.user = self.users[indexPath.row]
        
        DispatchQueue.main.async {
            if let updateCell = tableView.cellForRow(at: indexPath) as? SelectableUserTableViewCell {
                let user = self.users[indexPath.row]
                updateCell.nicknameLabel.text = user.nickname
                updateCell.profileImageView.setProfileImageView(for: user)
                
                if self.selectedUsers[user.userId] != nil {
                    updateCell.selectedUser = true
                }
                else {
                    updateCell.selectedUser = false
                }
            }
        }
        
        if self.users.count > 0 && indexPath.row == self.users.count - 1 {
            self.loadUserListNextPage(refresh: false)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.users.count
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = self.users[indexPath.row]
        if self.selectedUsers[user.userId] != nil {
            self.selectedUsers.removeValue(forKey: user.userId)
        }
        else {
            self.selectedUsers[user.userId] = user
        }
        
        self.okButtonItem!.title = String(format: "OK(%d)", self.selectedUsers.count)
        
        if self.selectedUsers.count == 0 {
            self.okButtonItem?.isEnabled = false
        }
        else {
            self.okButtonItem?.isEnabled = true
        }
        
        tableView.reloadData()
    }
    
    // MARK: - UISearchBarDelegate
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.refreshUserList()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count > 0 {
            self.userListQuery = SBDMain.createApplicationUserListQuery()
            self.userListQuery?.userIdsFilter = [searchText]
            self.userListQuery?.loadNextPage(completionHandler: { (users, error) in
                if error != nil {
                    DispatchQueue.main.async {
                        self.refreshControl?.endRefreshing()
                    }
                    
                    return
                }
                
                DispatchQueue.main.async {
                    self.users.removeAll()
                    for user in users ?? [] {
                        if user.userId == SBDMain.getCurrentUser()?.userId {
                            continue
                        }
                        self.users.append(user)
                    }
                    
                    self.tableView.reloadData()
                    self.refreshControl?.endRefreshing()
                }
            })
        }
    }
}
