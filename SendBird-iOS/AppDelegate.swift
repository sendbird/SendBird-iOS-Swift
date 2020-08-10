//
//  AppDelegate.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 10/3/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import UserNotifications
import SendBirdSDK
import AVKit
import AVFoundation
import Alamofire
import AlamofireImage

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, SBDChannelDelegate {

    var window: UIWindow?
    var receivedPushChannelUrl: String?
    var pushReceivedGroupChannel: String?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        SBDMain.initWithApplicationId("9880C4C1-E6C8-46E8-A8F1-D5890D598C08")
        SBDMain.add(self as SBDChannelDelegate, identifier: self.description)
        self.registerForRemoteNotification()
        SBDMain.setAppGroup("group.com.sendbird.sample4");
        
        DataRequest.addAcceptableImageContentTypes(["binary/octet-stream"])
        
        UINavigationBar.appearance().tintColor = UIColor(named: "color_navigation_tint")
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
        } catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
        self.window = UIWindow(frame: UIScreen.main.bounds)
        if let window = self.window {
            let mainStoryboard = UIStoryboard.init(name: "Main", bundle: nil)
            let viewController = mainStoryboard.instantiateViewController(withIdentifier: "LoginViewController")
            window.rootViewController = viewController
            window.makeKeyAndVisible()
        }
        
        return true
    }
    
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        connectingSceneSession.userInfo?["activity"] = options.userActivities.first?.activityType
        
        
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
    
    
    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }
    
    // MARK: - Notification for Foreground mode
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
    
    func registerForRemoteNotification() {
        if self.compareVersions(version1: UIDevice.current.systemVersion, version2: "10.0") >= 0 {
#if !targetEnvironment(simulator)
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
                if granted == true {
                    UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { (settings) in
                        if settings.authorizationStatus != UNAuthorizationStatus.authorized {
                            return
                        }
                        
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    })
                }
            }
            
            return
#else
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            center.requestAuthorization(options: [.alert]) { (granted, error) in
                
            }
#endif
        }
        else {
#if !targetEnvironment(simulator)
            if UIApplication.shared.responds(to: #selector(UIApplication.registerUserNotificationSettings(_:))) {
                let notificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
                UIApplication.shared.registerUserNotificationSettings(notificationSettings)
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
#endif
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
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
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to get token, error: \(String(describing: error))")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let sendbirdDict = userInfo["sendbird"] as? [String:Any] {
            if let channelDict  = sendbirdDict["channel"] as? [String:Any] {
                self.pushReceivedGroupChannel = channelDict["channel_url"] as? String
            }
        }
    }
    
    func channel(_ sender: SBDBaseChannel, didReceive message: SBDBaseMessage) {
        let topViewController = UIViewController.currentViewController()
        if topViewController is GroupChannelsViewController {
            return
        }
        
        if let vc = topViewController as? GroupChannelChatViewController {
            if vc.channel?.channelUrl == sender.channelUrl {
                return
            }
        }
        guard let groupChannel = sender as? SBDGroupChannel else { return }
        
        let pushOption = groupChannel.myPushTriggerOption
        
        switch pushOption {
        case .all, .default, .mentionOnly:
            break
        case .off:
            return
        }
        
        // Do Not Disturb - Need to implement as a function
        var startHour = 0
        var startMin = 0
        var endHour = 0
        var endMin = 0
        var isDoNotDisturbOn = false
        
        if UserDefaults.standard.value(forKey: "sendbird_dnd_start_hour") != nil {
            startHour = UserDefaults.standard.value(forKey: "sendbird_dnd_start_hour") as! Int
        }
        else {
            startHour = -1
        }
        
        if UserDefaults.standard.value(forKey: "sendbird_dnd_start_min") != nil {
            startMin = UserDefaults.standard.value(forKey: "sendbird_dnd_start_min") as! Int
        }
        else {
            startMin = -1
        }
        
        if UserDefaults.standard.value(forKey: "sendbird_dnd_end_hour") != nil {
            endHour = UserDefaults.standard.value(forKey: "sendbird_dnd_end_hour") as! Int
        }
        else {
            endHour = -1
        }
        
        if UserDefaults.standard.value(forKey: "sendbird_dnd_end_min") != nil {
            endMin = UserDefaults.standard.value(forKey: "sendbird_dnd_end_min") as! Int
        }
        else {
            endMin = -1
        }
        
        if UserDefaults.standard.value(forKey: "sendbird_dnd_on") != nil {
            isDoNotDisturbOn = UserDefaults.standard.value(forKey: "sendbird_dnd_on") as! Bool
        }
        
        if startHour != -1 && startMin != -1 && endHour != -1 && endMin != -1 && isDoNotDisturbOn {
            let date = Date()
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: date)
            let hour = components.hour
            let minute = components.minute
            
            let convertedStartMin = startHour * 60 + startMin
            let convertedEndMin = endHour * 60 + endMin
            let convertedCurrentMin = hour! * 60 + minute!
            
            if convertedStartMin <= convertedEndMin && convertedStartMin <= convertedCurrentMin && convertedEndMin >= convertedCurrentMin {
                return
            }
            else if convertedStartMin > convertedEndMin && (convertedStartMin < convertedCurrentMin || convertedEndMin > convertedCurrentMin) {
                return
            }
        }
        
        var title = ""
        var body = ""
        var type = ""
        var customType = ""
        if message is SBDUserMessage {
            let userMessage = message as! SBDUserMessage
            let sender = userMessage.sender
            
            type = "MESG"
            body = String(format: "%@: %@", (sender?.nickname)!, userMessage.message)
            customType = userMessage.customType!
        }
        else if message is SBDFileMessage {
            let fileMessage = message as! SBDFileMessage
            let sender = fileMessage.sender
            
            if fileMessage.type.hasPrefix("image") {
                body = String(format: "%@: (Image)", (sender?.nickname)!)
            }
            else if fileMessage.type.hasPrefix("video") {
                body = String(format: "%@: (Video)", (sender?.nickname)!)
            }
            else if fileMessage.type.hasPrefix("audio") {
                body = String(format: "%@: (Audio)", (sender?.nickname)!)
            }
            else {
                body = String(format: "%@: (File)", sender!.nickname!)
            }
        }
        else if message is SBDAdminMessage {
            let adminMessage = message as! SBDAdminMessage
            
            title = ""
            body = adminMessage.message
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "SENDBIRD_NEW_MESSAGE"
        content.userInfo = [
            "sendbird": [
                "type": type,
                "custom_type": customType,
                "channel": [
                    "channel_url": sender.channelUrl
                ],
                "data": "",
            ],
        ]
        let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: String(format: "%@_%@", content.categoryIdentifier, sender.channelUrl), content: content, trigger: trigger)
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error) in
            if error != nil {
                
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        guard let userInfo = response.notification.request.content.userInfo as? [String : Any] else { return }
        guard let sendbirdDict = userInfo["sendbird"] as? [String:Any] else { return }
        guard let channelDict = sendbirdDict["channel"] as? [String:Any] else { return }
        guard let channelUrl = channelDict["channel_url"] as? String else { return }
        self.pushReceivedGroupChannel = channelUrl
        
        ConnectionManager.login { user, error in
            if error == nil {
                if self.pushReceivedGroupChannel != nil {
                    if let vc = UIViewController.currentViewController() {
                        vc.dismiss(animated: false) {
                            self.jumpToGroupChannel(self.pushReceivedGroupChannel)
                        }
                    }
                    else {
                        let viewController = UIStoryboard(name: "main", bundle: nil).instantiateViewController(withIdentifier: "MainTabBarViewController")
                        self.window = UIWindow(frame: UIScreen.main.bounds)
                        if let window = self.window {
                            window.rootViewController = viewController
                            window.makeKeyAndVisible()
                        }
                        self.jumpToGroupChannel(self.pushReceivedGroupChannel)
                    }
                    
                    self.pushReceivedGroupChannel = nil
                } else {
                    let viewController = UIStoryboard(name: "main", bundle: nil).instantiateInitialViewController()
                    
                    self.window = UIWindow(frame: UIScreen.main.bounds)
                    if let window = self.window {
                        window.rootViewController = viewController
                        window.makeKeyAndVisible()
                    }
                }
            }
        }
        completionHandler()
    }
    
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    func jumpToGroupChannel(_ channelUrl: String?) -> Void {
        if let vc = UIViewController.currentViewController() as? NotificationDelegate, let url = channelUrl{
            vc.openChat(url)
        }
    }
    
    // Swift version only.
    private func compareVersions(version1: String, version2: String) -> Int {
        var ret: Int = 0
        
        var v1:[Int] = version1.split(separator: ".").map { (substring) -> Int in
            return Int(substring)!
        }
        var v2 = version2.split(separator: ".").map { (substring) -> Int in
            return Int(substring)!
        }
        
        let cntv1 = v1.count
        let cntv2 = v2.count
        let mincnt = cntv1 < cntv2 ? cntv1 : cntv2
        
        for i in 0..<mincnt {
            if v1[i] == v2[i] {
                ret = 0
                continue
            }
            else if v1[i] > v2[i] {
                ret = 1
            }
            else {
                ret = -1
            }
            
            break
        }
        
        if ret == 0 {
            if cntv1 > cntv2 {
                ret = 1
            }
            else if cntv1 < cntv2 {
                ret = -1
            }
        }
        
        return ret
    }
}

