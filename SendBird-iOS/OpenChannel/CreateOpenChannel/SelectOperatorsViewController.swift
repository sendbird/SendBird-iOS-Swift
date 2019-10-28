//
//  SelectOperatorsViewController.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 10/17/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK

class SelectOperatorsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate, NotificationDelegate {
    @IBOutlet weak var selectedUserListView: UICollectionView!
    @IBOutlet weak var selectedUserListHeight: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    
    weak var delegate: SelectOperatorsDelegate?
    var selectedUsers: [String: SBDUser] = [:]
    
    var users: [SBDUser] = []
    var userListQuery: SBDApplicationUserListQuery?
    var refreshControl: UIRefreshControl?
    var searchController: UISearchController?
    var okButtonItem: UIBarButtonItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.navigationItem.largeTitleDisplayMode = .automatic
        
        self.okButtonItem = UIBarButtonItem(title: "OK(0)", style: .plain, target: self, action: #selector(SelectOperatorsViewController.clickOkButton(_:)))
        self.navigationItem.rightBarButtonItem = self.okButtonItem
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.register(SelectableUserTableViewCell.nib(), forCellReuseIdentifier: "SelectableUserTableViewCell")
        
        self.selectedUserListView.contentInset = UIEdgeInsets.init(top: 0, left: 14, bottom: 0, right: 14)
        self.selectedUserListView.delegate = self
        self.selectedUserListView.dataSource = self
        self.selectedUserListView.register(SelectedUserCollectionViewCell.nib(), forCellWithReuseIdentifier: SelectedUserCollectionViewCell.cellReuseIdentifier())
        self.selectedUserListHeight.constant = 0
        self.selectedUserListView.isHidden = true
        
        self.selectedUserListView.showsHorizontalScrollIndicator = false
        self.selectedUserListView.showsVerticalScrollIndicator = false
        
        if let layout = self.selectedUserListView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
        }
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(SelectOperatorsViewController.refreshUserList), for: .valueChanged)
        
        self.tableView.refreshControl = self.refreshControl
        
        self.searchController = UISearchController.init(searchResultsController: nil)
        self.searchController?.searchBar.delegate = self
        self.searchController?.searchBar.placeholder = "User ID"
        self.searchController?.obscuresBackgroundDuringPresentation = false
        self.navigationItem.searchController = self.searchController
        self.navigationItem.hidesSearchBarWhenScrolling = false
        self.searchController?.searchBar.tintColor = UIColor(named: "color_bar_item")
        self.searchController?.searchBar.showsCancelButton = true
        
        if self.selectedUsers.count == 0 {
            self.okButtonItem?.isEnabled = false
        }
        else {
            self.okButtonItem?.isEnabled = true
        }
        
        self.okButtonItem?.title = "OK(\(Int(self.selectedUsers.count)))"
        
        self.refreshUserList()
    }

    // MARK: - NotificationDelegate
    func openChat(_ channelUrl: String) {
        if let navigationController = self.navigationController {
            navigationController.popViewController(animated: false)
        }
        
        if let cvc = UIViewController.currentViewController() as? NotificationDelegate {
            cvc.openChat(channelUrl)
        }
    }

    // MARK: - Load users
    @objc func refreshUserList() {
        self.loadUserListNextPage(true)
    }
    
    func loadUserListNextPage(_ refresh: Bool) {
        if refresh {
            self.userListQuery = nil
        }
        
        if self.userListQuery == nil {
            self.userListQuery = SBDMain.createApplicationUserListQuery()
            self.userListQuery!.limit = 20
        }
        
        if self.userListQuery!.hasNext == false {
            return
        }
        
        self.userListQuery!.loadNextPage { (users, error) in
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
                
                for user in users! {
                    if user.userId == SBDMain.getCurrentUser()!.userId {
                        continue
                    }
                    self.users.append(user)
                }
                
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
            }
        }
    }
    
    @objc func clickOkButton(_ sender: AnyObject) {
        if let delegate = self.delegate {
            delegate.didSelectUsers(self.selectedUsers)
        }
        
        self.navigationController?.popViewController(animated: true)
    }

    
    // MARK: UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.selectedUsers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = (collectionView.dequeueReusableCell(withReuseIdentifier: SelectedUserCollectionViewCell.cellReuseIdentifier(), for: indexPath)) as! SelectedUserCollectionViewCell
        
        let selectedUserKeys = self.selectedUsers.keys
        let key = Array(selectedUserKeys)[indexPath.row]
        
        cell.setModel(aUser: selectedUsers[key]!)
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedUserKeys = self.selectedUsers.keys
        let key = Array(selectedUserKeys)[indexPath.row]
       
        self.selectedUsers.removeValue(forKey: key)
        self.okButtonItem?.title = "OK(\(Int(self.selectedUsers.count)))"
        
        if self.selectedUsers.count == 0 {
            self.okButtonItem?.isEnabled = false
        }
        else {
            self.okButtonItem?.isEnabled = true
        }
        
        DispatchQueue.main.async {
            if self.selectedUsers.count == 0 {
                self.selectedUserListHeight.constant = 0
                self.selectedUserListView.isHidden = true
            }
            collectionView.reloadData()
            self.tableView.reloadData()
        }
    }
    
    
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SelectableUserTableViewCell") as! SelectableUserTableViewCell
        cell.user = self.users[indexPath.row]
        
        DispatchQueue.main.async {
            if let updateCell = tableView.cellForRow(at: indexPath) as? SelectableUserTableViewCell {
                updateCell.nicknameLabel.text = self.users[indexPath.row].nickname
                updateCell.profileImageView.setProfileImageView(for: self.users[indexPath.row])
                
                if self.selectedUsers[self.users[indexPath.row].userId] != nil {
                   updateCell.selectedUser = true
                }
                else {
                    updateCell.selectedUser = false
                }
            }
        }
        
        if self.users.count > 0 && indexPath.row == self.users.count - 1 {
            self.loadUserListNextPage(false)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.users.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.selectedUsers[self.users[indexPath.row].userId] != nil {
            self.selectedUsers.removeValue(forKey: self.users[indexPath.row].userId)
        }
        else {
            self.selectedUsers[self.users[indexPath.row].userId] = self.users[indexPath.row]
        }
        
        self.okButtonItem?.title = "OK(\(Int(self.selectedUsers.count)))"
        
        if self.selectedUsers.count == 0 {
            self.okButtonItem?.isEnabled = false
        }
        else {
            self.okButtonItem?.isEnabled = true
        }
        
        DispatchQueue.main.async {
            if self.selectedUsers.count > 0 {
                self.selectedUserListHeight.constant = 70
                self.selectedUserListView.isHidden = false
            }
            else {
                self.selectedUserListHeight.constant = 0
                self.selectedUserListView.isHidden = true
            }
            
            self.tableView.reloadRows(at: [indexPath], with: UITableView.RowAnimation.none)
            self.selectedUserListView.reloadData()
        }
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    // MARK: - UISearchBarDelegate
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.refreshUserList()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count > 0 {
            self.userListQuery = SBDMain.createApplicationUserListQuery()
            self.userListQuery?.userIdsFilter = [searchText]
            self.userListQuery?.loadNextPage { (users, error) in
                if error != nil {
                    DispatchQueue.main.async {
                        self.refreshControl?.endRefreshing()
                    }
                    
                    return
                }
                
                DispatchQueue.main.async {
                    self.users.removeAll()
                    for user in users! {
                        if user.userId == SBDMain.getCurrentUser()!.userId {
                            continue
                        }
                        self.users.append(user)
                    }
                    
                    self.tableView.reloadData()
                    self.refreshControl?.endRefreshing()
                }
            }
        }
    }
}
