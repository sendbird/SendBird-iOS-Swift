//
//  SelectedUserCollectioViewCell.swift
//  SendBird-iOS
//
//  Created by Jaesung Lee on 27/08/2019.
//  Copyright © 2019 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK
import AlamofireImage

class SelectedUserCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nicknameLabel: UILabel!
    
    private var user: SBDUser!
    
    static func nib() -> UINib {
        return UINib(nibName: String(describing: self), bundle: Bundle(for: self))
    }
    
    static func cellReuseIdentifier() -> String {
        return String(describing: self)
    }
    
    func setModel(aUser: SBDUser) {
        self.user = aUser
        
        if self.user.profileUrl != nil {
            self.profileImageView.af_setImage(withURL: URL(string: self.user.profileUrl!)!, placeholderImage:UIImage(named: "img_profile"))
        }
        else {
            self.profileImageView.image = UIImage(named: "img_profile")
        }
        self.nicknameLabel.text = self.user.nickname
    }
}
