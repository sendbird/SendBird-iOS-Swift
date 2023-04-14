//
//  GroupChannelsViewController.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 10/12/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import AlamofireImage

class GroupChannelsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SBDChannelDelegate, SBDConnectionDelegate, NotificationDelegate, CreateGroupChannelViewControllerDelegate, GroupChannelsUpdateListDelegate {
    @IBOutlet weak var groupChannelsTableView: UITableView!
    @IBOutlet weak var loadingIndicatorView: CustomActivityIndicatorView!
    @IBOutlet weak var toastView: UIView!
    @IBOutlet weak var toastMessageLabel: UILabel!
    @IBOutlet weak var emptyLabel: UILabel!
    
    var refreshControl: UIRefreshControl?
    var trypingIndicatorTimer: [String : Timer] = [:]
    
    var channelListQuery: SBDGroupChannelListQuery?
    var channels: [SBDGroupChannel] = []
    var toastCompleted: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.title = "Group Channels"
        self.navigationController?.title = "Group"
        self.navigationItem.largeTitleDisplayMode = .automatic
                
        let createChannelBarButton = UIBarButtonItem.init(image: UIImage(named: "img_btn_create_group_channel_blue"), style: .plain, target: self, action: #selector(GroupChannelsViewController.clickCreateGroupChannel(_:)))
        
        self.navigationItem.rightBarButtonItem = createChannelBarButton
        
        self.groupChannelsTableView.delegate = self
        self.groupChannelsTableView.dataSource = self

        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(GroupChannelsViewController.longPressChannel(_:)))
        longPressGesture.minimumPressDuration = 1.0
        self.groupChannelsTableView.addGestureRecognizer(longPressGesture)
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: #selector(GroupChannelsViewController.refreshChannelList), for: .valueChanged)
        
        self.groupChannelsTableView.refreshControl = self.refreshControl
        
        self.hideLoadingIndicatorView()
        self.view.bringSubviewToFront(self.loadingIndicatorView)
        
        self.updateTotalUnreadMessageCountBadge()
        
        self.loadChannelListNextPage(true)
        
        SBDMain.add(self as SBDChannelDelegate, identifier: NSUUID().uuidString)
        SBDMain.add(self as SBDConnectionDelegate, identifier: NSUUID().uuidString)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.groupChannelsTableView.layoutIfNeeded()
    }
    
    func showToast(message: String, completion: (() -> Void)?) {
        self.toastCompleted = false
        self.toastView.alpha = 1
        self.toastMessageLabel.text = message
        self.toastView.isHidden = false
        
        UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseIn, animations: {
            self.toastView.alpha = 0
        }) { (finished) in
            self.toastView.isHidden = true
            self.toastCompleted = true
            
            completion?()
        }
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "CreateGroupChannel", let destination = segue.destination as? CreateGroupChannelNavigationController{
            destination.channelCreationDelegate = self
        } else if segue.identifier == "ShowGroupChat", let destination = segue.destination.children.first as? GroupChannelChatViewController {
            destination.hidesBottomBarWhenPushed = true
            if let index = sender as? Int {
                destination.channel = self.channels[index]
            } else if let channel = sender as? SBDGroupChannel {
                destination.channel = channel
            }
            
            destination.delegate = self
        }
    }
    

    @objc func clickCreateGroupChannel(_ sender: Any) {
        performSegue(withIdentifier: "CreateGroupChannel", sender: self)
    }
    
    @objc func longPressChannel(_ recognizer: UILongPressGestureRecognizer) {
        let point = recognizer.location(in: self.groupChannelsTableView)
        guard let indexPath = self.groupChannelsTableView.indexPathForRow(at: point) else { return }
        if recognizer.state == .began {
            let channel = self.channels[indexPath.row]
            let alert = UIAlertController(title: Utils.createGroupChannelName(channel: channel), message: nil, preferredStyle: .actionSheet)
            
            let actionLeave = UIAlertAction(title: "Leave Channel", style: .destructive) { (action) in
                channel.leave(completionHandler: { (error) in
                    if let error = error {
                        Utils.showAlertController(error: error, viewController: self)
                        return
                    }
                })
            }
            
            let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            alert.modalPresentationStyle = .popover
            alert.addAction(actionLeave)
            alert.addAction(actionCancel)
            
            if let presenter = alert.popoverPresentationController {
                presenter.sourceView = self.view
                presenter.sourceRect = CGRect(x: self.view.bounds.minX, y: self.view.bounds.maxY, width: 0, height: 0)
                presenter.permittedArrowDirections = []
            }
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func updateTotalUnreadMessageCountBadge() {
        SBDMain.getTotalUnreadMessageCount { (unreadCount, error) in
            guard let navigationController = self.navigationController else { return }
            if error != nil {
                navigationController.tabBarItem.badgeValue = nil
                
                return
            }
            
            if unreadCount > 0 {
                navigationController.tabBarItem.badgeValue = String(format: "%ld", unreadCount)
            }
            else {
                navigationController.tabBarItem.badgeValue = nil
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
            SBDMain.getTotalUnreadMessageCount { (unreadCount, error) in
                guard let navigationController = self.navigationController else { return }
                if error != nil {
                    navigationController.tabBarItem.badgeValue = nil
                    return
                }
                
                if unreadCount > 0 {
                    navigationController.tabBarItem.badgeValue = String(format: "%ld", unreadCount)
                }
                else {
                    navigationController.tabBarItem.badgeValue = nil
                }
            }
        }
    }
    
    func buildTypingIndicatorLabel(channel: SBDGroupChannel) -> String {
        let typingMembers = channel.getTypingUsers()
        if typingMembers == nil || typingMembers?.count == 0 {
            return ""
        }
        else {
            if typingMembers?.count == 1 {
                return String(format: "%@ is typing.", typingMembers![0].nickname!)
            }
            else if typingMembers?.count == 2 {
                return String(format: "%@ and %@ are typing.", typingMembers![0].nickname!, typingMembers![1].nickname!)
            }
            else {
                return "Several people are typing."
            }
        }
    }
    
    @objc func typingIndicatorTimeout(_ timer: Timer) {
        if let channelUrl = timer.userInfo as? String {
            self.trypingIndicatorTimer[channelUrl]?.invalidate()
            self.trypingIndicatorTimer.removeValue(forKey: channelUrl)
            DispatchQueue.main.async {
                self.groupChannelsTableView.reloadData()
            }
        }
    }
    
    // MARK: - NotificationDelegate
    func openChat(_ channelUrl: String) {
        SBDGroupChannel.getWithUrl(channelUrl) { (channel, error) in
            if error != nil {
                return
            }
            
            DispatchQueue.main.async {
                (UIApplication.shared.delegate as? AppDelegate)?.pushReceivedGroupChannel = nil
                self.performSegue(withIdentifier: "ShowGroupChat", sender: channel)
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupChannelTableViewCell") as! GroupChannelTableViewCell
        let channel = self.channels[indexPath.row]
        
        cell.channelNameLabel.text = Utils.createGroupChannelName(channel: channel)
        
        let lastMessageDateFormatter = DateFormatter()
        var lastUpdatedAt: Date?
        
        /// Marking Date on the Group Channel List
        if channel.lastMessage != nil {
            lastUpdatedAt = Date(timeIntervalSince1970: Double((channel.lastMessage?.createdAt)! / 1000))
        } else {
            lastUpdatedAt = Date(timeIntervalSince1970: Double(channel.createdAt))
        }
        
        let currDate = Date()
        
        let lastMessageDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: lastUpdatedAt!)
        let currDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: currDate)
        
        if lastMessageDateComponents.year != currDateComponents.year || lastMessageDateComponents.month != currDateComponents.month || lastMessageDateComponents.day != currDateComponents.day {
            lastMessageDateFormatter.dateStyle = .short
            lastMessageDateFormatter.timeStyle = .none
            cell.lastUpdatedDateLabel.text = lastMessageDateFormatter.string(from: lastUpdatedAt!)
        }
        else {
            lastMessageDateFormatter.dateStyle = .none
            lastMessageDateFormatter.timeStyle = .short
            cell.lastUpdatedDateLabel.text = lastMessageDateFormatter.string(from: lastUpdatedAt!)
        }
        
        let typingIndicatorText = self.buildTypingIndicatorLabel(channel: channel)
        let timer = self.trypingIndicatorTimer[channel.channelUrl]
        var showTypingIndicator = false
        if timer != nil && typingIndicatorText.count > 0 {
            showTypingIndicator = true
        }
        
        if showTypingIndicator {
            cell.lastMessageLabel.isHidden = true
            cell.typingIndicatorContainerView.isHidden = false
            cell.typingIndicatorLabel.text = typingIndicatorText
        }
        else {
            cell.lastMessageLabel.isHidden = false
            cell.typingIndicatorContainerView.isHidden = true
            if channel.lastMessage != nil {
                if channel.lastMessage is SBDUserMessage {
                    let lastMessage = channel.lastMessage as! SBDUserMessage
                    cell.lastMessageLabel.text = lastMessage.message
                }
                else if channel.lastMessage is SBDFileMessage {
                    let lastMessage = channel.lastMessage as! SBDFileMessage
                    if lastMessage.type.hasPrefix("image") {
                        cell.lastMessageLabel.text = "(Image)"
                    }
                    else if lastMessage.type.hasPrefix("video") {
                        cell.lastMessageLabel.text = "(Video)"
                    }
                    else if lastMessage.type.hasPrefix("audio") {
                        cell.lastMessageLabel.text = "(Audio)"
                    }
                    else {
                        cell.lastMessageLabel.text = "(File)"
                    }
                }
                else {
                    cell.lastMessageLabel.text = ""
                }
            }
            else {
                cell.lastMessageLabel.text = ""
            }
        }
        
        cell.unreadMessageCountContainerView.isHidden = false
        if channel.unreadMessageCount > 99 {
            cell.unreadMessageCountLabel.text = "+99"
        }
        else if channel.unreadMessageCount > 0 {
            cell.unreadMessageCountLabel.text = String(channel.unreadMessageCount)
        }
        else {
            cell.unreadMessageCountContainerView.isHidden = true
        }
        
        if channel.memberCount <= 2 {
            cell.memberCountContainerView.isHidden = true
        }
        else {
            cell.memberCountContainerView.isHidden = false
            cell.memberCountLabel.text = String(channel.memberCount)
        }
        
        let pushOption = channel.myPushTriggerOption
        
        switch pushOption {
        case .all, .default, .mentionOnly:
            cell.notiOffIconImageView.isHidden = true
            break
        case .off:
            cell.notiOffIconImageView.isHidden = false
            break
        @unknown default:
            cell.notiOffIconImageView.isHidden = true
        }
        
        DispatchQueue.main.async {
            var members: [SBDUser] = []
            var count = 0
            if let channelMembers = channel.members as? [SBDMember], let currentUser = SBDMain.getCurrentUser() {
                for member in channelMembers {
                    if member.userId == currentUser.userId {
                        continue
                    }
                    members.append(member)
                    count += 1
                    if count == 4 {
                        break
                    }
                }
            }
            
            
            if let updateCell = tableView.cellForRow(at: indexPath) as? GroupChannelTableViewCell {
                if let coverUrl = channel.coverUrl {
                    if coverUrl.count > 0 && !coverUrl.hasPrefix("https://sendbird.com/main/img/cover/") {
                        updateCell.profileImagView.setImage(withCoverUrl: coverUrl)
                    }
                    else {
                        updateCell.profileImagView.users = members
                        updateCell.profileImagView.makeCircularWithSpacing(spacing: 1)
                    }
                }
            }
        }
        
        if self.channels.count > 0 && indexPath.row == self.channels.count - 1 {
            self.loadChannelListNextPage(false)
        }
        
        
        return cell
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.channels.count == 0 && self.toastCompleted {
            self.emptyLabel.isHidden = false
        }
        else {
            self.emptyLabel.isHidden = true
        }
        
        return self.channels.count
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 76
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ShowGroupChat", sender: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let leaveAction: UIContextualAction = UIContextualAction.init(style: .destructive, title: "Leave") { (action, sourceView, completionHandler) in
            self.channels[indexPath.row].leave(completionHandler: { (error) in
                if let error = error {
                    Utils.showAlertController(error: error, viewController: self)
                    return
                }
            })
            
            completionHandler(true)
        }
        leaveAction.backgroundColor = UIColor(named: "color_leave_group_channel_bg")
        
        return UISwipeActionsConfiguration(actions: [leaveAction])
    }
    
    // MARK: - Load channels
    @objc func refreshChannelList() {
        self.loadChannelListNextPage(true)
    }
    
    func loadChannelListNextPage(_ refresh: Bool) {
        if refresh {
            self.channelListQuery = nil
        }
        
        if self.channelListQuery == nil {
            self.channelListQuery = SBDGroupChannel.createMyGroupChannelListQuery()
            self.channelListQuery?.order = .latestLastMessage
            self.channelListQuery?.limit = 20
            self.channelListQuery?.includeEmptyChannel = true
        }
        
        if self.channelListQuery?.hasNext == false {
            return
        }
        
        self.channelListQuery?.loadNextPage(completionHandler: { (channels, error) in
            if error != nil {
                DispatchQueue.main.async {
                    self.refreshControl?.endRefreshing()
                }
                
                return
            }
            
            DispatchQueue.main.async {
                if refresh {
                    self.channels.removeAll()
                }
                
                self.channels += channels!
                self.groupChannelsTableView.reloadData()
                self.refreshControl?.endRefreshing()
            }
        })
    }
    
    // MARK: - CreateGroupChannelViewControllerDelegate
    func didCreateGroupChannel(_ channel: SBDGroupChannel) {
        DispatchQueue.main.async {
            if self.channels.firstIndex(of: channel) == nil {
                self.channels.insert(channel, at: 0)
            }
            
            self.groupChannelsTableView.reloadData()
        }
    }
    
    // MARK: - GroupChannelsUpdateListDelegate
    func updateGroupChannelList() {
        DispatchQueue.main.async {
            self.groupChannelsTableView.reloadData()
        }
        
        self.updateTotalUnreadMessageCountBadge()
    }
    
    // MARK: - SBDChannelDelegate
    func channel(_ sender: SBDBaseChannel, didReceive message: SBDBaseMessage) {
        DispatchQueue.main.async {
            if sender is SBDGroupChannel {
                var hasChannelInList = false
                for ch in self.channels {
                    if ch.channelUrl == sender.channelUrl {
                        self.channels.removeObject(ch)
                        self.channels.insert(ch, at: 0)
                        self.groupChannelsTableView.reloadData()
                        self.updateTotalUnreadMessageCountBadge()
                        
                        hasChannelInList = true
                        break
                    }
                }
                
                if hasChannelInList == false {
                    self.channels.insert(sender as! SBDGroupChannel, at: 0)
                    self.groupChannelsTableView.reloadData()
                    self.updateTotalUnreadMessageCountBadge()
                }
            }
        }
    }
    
    func channelDidUpdateTypingStatus(_ sender: SBDGroupChannel) {
        if let timer = self.trypingIndicatorTimer[sender.channelUrl] {
            timer.invalidate()
        }
        
        let timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(GroupChannelsViewController.typingIndicatorTimeout(_ :)), userInfo: sender.channelUrl, repeats: false)
        self.trypingIndicatorTimer[sender.channelUrl] = timer
        
        DispatchQueue.main.async {
            self.groupChannelsTableView.reloadData()
        }
    }
    
    func channel(_ sender: SBDGroupChannel, userDidJoin user: SBDUser) {
        DispatchQueue.main.async {
            if self.channels.firstIndex(of: sender) == nil {
                self.channels.insert(sender, at: 0)
            }
            self.groupChannelsTableView.reloadData()
        }
    }
    
    func channel(_ sender: SBDGroupChannel, userDidLeave user: SBDUser) {
        DispatchQueue.main.async {
            if let index = self.channels.firstIndex(of: sender as SBDGroupChannel) {
                self.channels.remove(at: index)
            }
            self.groupChannelsTableView.reloadData()
        }
    }
    
    func channelWasChanged(_ sender: SBDBaseChannel) {
        DispatchQueue.main.async {
            self.groupChannelsTableView.reloadData()
        }
    }
    
    func channel(_ sender: SBDBaseChannel, messageWasDeleted messageId: Int64) {
        if sender is SBDGroupChannel {
            var hasChannelInList = false
            for ch in self.channels {
                if ch.channelUrl == sender.channelUrl {
                    DispatchQueue.main.async {
                        self.channels.removeObject(ch)
                        self.channels.insert(ch, at: 0)
                        self.groupChannelsTableView.reloadData()
                        self.updateTotalUnreadMessageCountBadge()
                    }
                    
                    hasChannelInList = true
                }
            }
            
            if hasChannelInList == false {
                DispatchQueue.main.async {
                    self.channels.insert(sender as! SBDGroupChannel, at: 0)
                    self.groupChannelsTableView.reloadData()
                    self.updateTotalUnreadMessageCountBadge()
                }
            }
        }
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
