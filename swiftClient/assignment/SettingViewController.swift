//
//  SettingViewController.swift
//  assignment
//
//  Created by Wennong Cai on 30/3/19.
//  Copyright © 2019 Wennong Cai. All rights reserved.
//

import UIKit

// SettingViewController is the setting screen of the app.

class SettingViewController: UIViewController {
    @IBOutlet weak var EAslider: UISlider!
    @IBOutlet weak var EAlabel: UILabel!
    @IBOutlet weak var hintModeSwitch: UISwitch!
    @IBOutlet weak var reverseSwitch: UISwitch!
    @IBOutlet weak var breatheSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        changeEA(GlobalVars.EA_value)
        hintModeSwitch.isOn = GlobalVars.moveableHintFlag
        reverseSwitch.isOn = GlobalVars.reverseBlackFlag
        breatheSwitch.isOn = GlobalVars.breatheToolbarFlag
    }
    
    func changeEA(_ value: Float){
        EAslider.value = value
        EA_valueChanged(self)
    }
    
    @IBAction func EA_valueChanged(_ sender: Any) {
        let text = "\(Int(EAslider.value))%"
        EAlabel.text = text
    }
    
    @IBAction func saveOnClick(_ sender: Any) {
        GlobalVars.EA_value = EAslider.value
        UserDefaults.standard.set(EAslider.value, forKey: GlobalVars.EA_value_KEY)
        GlobalVars.moveableHintFlag = hintModeSwitch.isOn
        UserDefaults.standard.set(hintModeSwitch.isOn, forKey: GlobalVars.moveableHint_KEY)
        GlobalVars.reverseBlackFlag = reverseSwitch.isOn
        UserDefaults.standard.set(reverseSwitch.isOn, forKey: GlobalVars.reverseBlack_KEY)
        GlobalVars.breatheToolbarFlag = breatheSwitch.isOn
        UserDefaults.standard.set(breatheSwitch.isOn, forKey: GlobalVars.breatheBlack_KEY)
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func resetOnClick(_ sender: Any) {
        changeEA(GlobalVars.EA_default)
        hintModeSwitch.isOn = false
        reverseSwitch.isOn = false
        breatheSwitch.isOn = false
    }
    

}
