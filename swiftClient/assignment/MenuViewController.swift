//
//  MenuViewController.swift
//  assignment
//
//  Created by Wennong Cai on 30/3/19.
//  Copyright © 2019 Wennong Cai. All rights reserved.
//

import UIKit

// MenuViewController is the entry screen of the app

class MenuViewController: UIViewController {
    @IBOutlet weak var continueButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // First try to get Save Data
        // Then check if there is a save data
        if UserDefaults.standard.bool(forKey: GlobalVars.storedGame_KEY) {
            continueButton.isHidden = false
        } else {
            continueButton.isHidden = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "continueSegue" {
            if let vc = segue.destination as? MainGameViewController {
                vc.loadingFlag = true
            }
        }
    }

}
