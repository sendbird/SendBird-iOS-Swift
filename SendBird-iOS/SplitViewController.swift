//
//  SplitViewController.swift
//  SendBird-iOS
//
//  Created by Jaesung Lee on 09/08/2019.
//  Copyright © 2019 SendBird. All rights reserved.
//

import UIKit

class SplitViewController: UISplitViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.preferredDisplayMode = .allVisible
        self.modalPresentationStyle = .fullScreen
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
