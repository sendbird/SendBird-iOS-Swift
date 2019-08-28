//
//  CreateOpenChannelNavigationController.swift
//  SendBird-iOS
//
//  Created by Jed Gyeong on 10/16/18.
//  Copyright © 2018 SendBird. All rights reserved.
//

import UIKit
import SendBirdSDK

class CreateOpenChannelNavigationController: UINavigationController {
    weak var createChannelDelegate: CreateOpenChannelDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationBar.prefersLargeTitles = false
    }
}
