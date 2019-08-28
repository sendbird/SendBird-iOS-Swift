//
//  SettingsTimeViewController.swift
//  SendBird-iOS
//
//  Created by Minhyuk Kim on 18/07/2019.
//  Copyright © 2019 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK

class SettingsTimeViewController: UIViewController, SettingsTableViewCellDelegate, SettingsTimePickerDelegate, NotificationDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingIndicatorView: CustomActivityIndicatorView!
    
    var isDoNotDisturbOn: Bool = true
    
    var startHour: Int32 = 0
    var startMin: Int32 = 0
    var startAmPm: String = "AM"
    var endHour: Int32 = 0
    var endMin: Int32 = 0
    var endAmPm: String = "PM"
    var startTimeShown: Bool = false
    var endTimeShown: Bool = false
    var showPreview: Bool = false
    var showFromTimePicker: Bool = false
    var showToTimePicker: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.title = "Settings"
        self.navigationItem.largeTitleDisplayMode = .automatic

        self.tableView.delegate = self
        self.tableView.dataSource = self

        if let value = UserDefaults.standard.object(forKey: Constants.ID_SHOW_PREVIEWS) as? Bool{
            self.showPreview = value
        }
        
        self.view.bringSubviewToFront(self.loadingIndicatorView)
        self.loadingIndicatorView.isHidden = false
        self.loadingIndicatorView.startAnimating()
    
        SBDMain.getDoNotDisturb { (isDoNotDisturbOn, startHour, startMin, endHour, endMin, timezone, error) in
            DispatchQueue.main.async {
                self.loadingIndicatorView.isHidden = true
                self.loadingIndicatorView.stopAnimating()
            }
            
            UserDefaults.standard.set(startHour, forKey: "sendbird_dnd_start_hour")
            UserDefaults.standard.set(startMin, forKey: "sendbird_dnd_start_min")
            UserDefaults.standard.set(endHour, forKey: "sendbird_dnd_end_hour")
            UserDefaults.standard.set(endMin, forKey: "sendbird_dnd_end_min")
            UserDefaults.standard.set(isDoNotDisturbOn, forKey: "sendbird_dnd_on")
            UserDefaults.standard.synchronize()
            
            guard error == nil else { return }
            
            self.isDoNotDisturbOn = isDoNotDisturbOn
            if startHour < 12 {
                self.startHour = startHour
                self.startAmPm = "AM"
            }
            else {
                self.startHour = startHour - 12
                self.startAmPm = "PM"
            }
            
            self.startMin = startMin
            
            if endHour < 12 {
                self.endHour = endHour
                self.endAmPm = "AM"
            }
            else {
                self.endHour = endHour - 12
                self.endAmPm = "PM"
            }
            
            self.endMin = endMin
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                if let switchViewCell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? SettingsSwitchTableViewCell{
                    switchViewCell.switchButton.isOn = isDoNotDisturbOn
                }
            }
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    // MARK: - NotificationDelegate
    func openChat(_ channelUrl: String) {
        (self.navigationController?.parent as! MainTabBarController).selectedIndex = 0
        if let cvc = UIViewController.currentViewController() as? GroupChannelsViewController {
            cvc.openChat(channelUrl)
        }
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.row {
        case 0:
            let viewCell = tableView.dequeueReusableCell(withIdentifier: "SettingsSwitchTableViewCell") as! SettingsSwitchTableViewCell
            viewCell.settingsLabel.text = "Do Not Disturb"
            
            viewCell.bottomBorderView.isHidden = !self.isDoNotDisturbOn
            
            viewCell.switchIdentifier = Constants.ID_DO_NOT_DISTURB
            viewCell.delegate = self
            
            return viewCell
        case 1:
            let viewCell = tableView.dequeueReusableCell(withIdentifier: "SettingsTimeTableViewCell") as! SettingsTimeTableViewCell
            viewCell.settingLabel.text = "From"
            viewCell.expandedTopBorderView.isHidden = true
            viewCell.timeLabel.text = String(format: "%02d:%02d %@", self.startHour, self.startMin, self.startAmPm)
            
            if self.startTimeShown {
                viewCell.bottomBorderView.isHidden = true
                viewCell.expandedBottomBorderView.isHidden = false
                viewCell.timeLabel.textColor = UIColor(named: "color_settings_time_label_highlighted")
            }
            else {
                viewCell.bottomBorderView.isHidden = false
                viewCell.expandedBottomBorderView.isHidden = true
                viewCell.timeLabel.textColor = UIColor(named: "color_settings_time_label_normal")
            }
            
            viewCell.isHidden = !self.isDoNotDisturbOn
            
            return viewCell
        case 2:
            let viewcell = tableView.dequeueReusableCell(withIdentifier: "SettingsTimePickerTableViewCell") as! SettingsTimePickerTableViewCell
            viewcell.delegate = self
            viewcell.identifier = "START"
            viewcell.timerPicker.selectRow(Int(self.startHour), inComponent: 1, animated: false)
            viewcell.timerPicker.selectRow(Int(self.startMin), inComponent: 2, animated: false)
            if self.startAmPm == "AM" {
                viewcell.timerPicker.selectRow(0, inComponent: 3, animated: false)
            }
            else {
                viewcell.timerPicker.selectRow(1, inComponent: 3, animated: false)
            }
            
            return viewcell
        case 3:
            let viewcell = tableView.dequeueReusableCell(withIdentifier: "SettingsTimeTableViewCell") as! SettingsTimeTableViewCell
            viewcell.settingLabel.text = "To"
            viewcell.bottomBorderView.isHidden = true
            viewcell.timeLabel.text = String(format: "%02d:%02d %@", self.endHour, self.endMin, self.endAmPm)

            viewcell.expandedTopBorderView.isHidden = !self.startTimeShown
            
            if self.endTimeShown {
                viewcell.expandedBottomBorderView.isHidden = false
                viewcell.timeLabel.textColor = UIColor(named: "color_settings_time_label_highlighted")
            }
            else {
                viewcell.expandedBottomBorderView.isHidden = true
                viewcell.timeLabel.textColor = UIColor(named: "color_settings_time_label_normal")
            }
            
            viewcell.isHidden = !self.isDoNotDisturbOn
            
            return viewcell
        case 4:
            let viewcell = tableView.dequeueReusableCell(withIdentifier: "SettingsTimePickerTableViewCell") as! SettingsTimePickerTableViewCell
            viewcell.delegate = self
            viewcell.identifier = "END"
            viewcell.timerPicker.selectRow(Int(self.endHour), inComponent: 1, animated: false)
            viewcell.timerPicker.selectRow(Int(self.endMin), inComponent: 2, animated: false)
            
            if self.endAmPm == "AM" {
                viewcell.timerPicker.selectRow(0, inComponent: 3, animated: false)
            }
            else {
                viewcell.timerPicker.selectRow(1, inComponent: 3, animated: false)
            }
            
            return viewcell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return 44
        case 1, 3:
            if self.isDoNotDisturbOn {
                return 44
            } else {
                return 0
            }
        case 2:
            if self.isDoNotDisturbOn, self.startTimeShown {
                return 217
            } else {
                return 0
            }
        case 4:
            if self.isDoNotDisturbOn, self.endTimeShown {
                return 127
            } else {
                return 0
            }
        default:
            return UITableView.automaticDimension
        }
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 1 {
            if self.startTimeShown {
                self.setDoNotDisturbTime()
            }
            
            self.startTimeShown = !self.startTimeShown
            self.endTimeShown = false
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        else if indexPath.row == 3 {
            if self.endTimeShown {
                self.setDoNotDisturbTime()
            }
            
            self.endTimeShown = !self.endTimeShown
            self.startTimeShown = false
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - SettingsTableViewCellDelegate
    func didChangeSwitchButton(isOn: Bool, identifier: String) {
        if identifier == Constants.ID_DO_NOT_DISTURB {
            self.isDoNotDisturbOn = isOn
            DispatchQueue.main.async {
                self.loadingIndicatorView.isHidden = false
                self.loadingIndicatorView.startAnimating()

                self.tableView.reloadData()
                
                let startHour24 = self.startAmPm == "AM" ? self.startHour : self.startHour + 12
                let endHour24 = self.endAmPm == "AM" ? self.endHour : self.endHour + 12
                
                UserDefaults.standard.set(startHour24, forKey: "sendbird_dnd_start_hour")
                UserDefaults.standard.set(self.startMin, forKey: "sendbird_dnd_start_min")
                UserDefaults.standard.set(endHour24, forKey: "sendbird_dnd_end_hour")
                UserDefaults.standard.set(self.endMin, forKey: "sendbird_dnd_end_min")
                UserDefaults.standard.set(self.isDoNotDisturbOn, forKey: "sendbird_dnd_on")
                UserDefaults.standard.synchronize()
                
                SBDMain.setDoNotDisturbWithEnable(isOn, startHour: startHour24, startMin: self.startMin, endHour: endHour24, endMin: self.endMin, timezone: TimeZone.current.identifier, completionHandler: { (error) in
                    
                    DispatchQueue.main.async {
                        self.loadingIndicatorView.isHidden = true
                        self.loadingIndicatorView.stopAnimating()
                    }
                    
                    guard error == nil else { return }
                    
                })
            }
        }
    }
    
    func setDoNotDisturbTime() {
        DispatchQueue.main.async {
            self.loadingIndicatorView.isHidden = false
            self.loadingIndicatorView.startAnimating()

            let startHour24 = self.startAmPm == "AM" ? self.startHour : self.startHour + 12
            let endHour24 = self.endAmPm == "AM" ? self.endHour : self.endHour + 12
            
            SBDMain.setDoNotDisturbWithEnable(true, startHour: startHour24, startMin: self.startMin, endHour: endHour24, endMin: self.endMin, timezone: TimeZone.current.identifier, completionHandler: { (error) in
                DispatchQueue.main.async {
                    self.loadingIndicatorView.isHidden = true
                    self.loadingIndicatorView.stopAnimating()
                }
                
                guard error == nil else { return }
                
                UserDefaults.standard.set(startHour24, forKey: "sendbird_dnd_start_hour")
                UserDefaults.standard.set(self.startMin, forKey: "sendbird_dnd_start_min")
                UserDefaults.standard.set(endHour24, forKey: "sendbird_dnd_end_hour")
                UserDefaults.standard.set(self.endMin, forKey: "sendbird_dnd_end_min")
                UserDefaults.standard.set(true, forKey: "sendbird_dnd_on")
                UserDefaults.standard.synchronize()
            })
        }
    }
    
    // MARK: - SettingsTimePickerDelegate
    func didSetTime(timeValue: String, component: Int, identifier: String) {
        if identifier == "START" {
            if component == 1 {
                self.startHour = Int32(timeValue)!
            }
            else if component == 2 {
                self.startMin = Int32(timeValue)!
            }
            else if component == 3 {
                self.startAmPm = timeValue
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
            }
        }
        else if identifier == "END" {
            if component == 1 {
                self.endHour = Int32(timeValue)!
            }
            else if component == 2 {
                self.endMin = Int32(timeValue)!
            }
            else if component == 3 {
                self.endAmPm = timeValue
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadRows(at: [IndexPath(row: 3, section: 0)], with: .none)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isDoNotDisturbOn{
            setDoNotDisturbTime()
        }
    }
}
