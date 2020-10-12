//
//  UtilityFunctions.swift
//  assignment
//
//  Created by Wennong Cai on 25/5/19.
//  Copyright © 2019 Wennong Cai. All rights reserved.
//

// This file is to put here some code that will be used cross multiple files to simplify other files.

import UIKit

// Let all UIViewController class have a simple way to show a Alert Message
extension UIViewController {
    // return means "after user read the alert message, should the screen pop back to last screen automatically or not
    func createAlertMsg(title:String, msg: String, returnVal: Bool=false, UpsideDown: Bool=false) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {_ in
            if returnVal {
                self.navigationController?.popViewController(animated: true)
            }
        }))
        self.present(alert,animated: true, completion: {()->Void in
            if UpsideDown {
                alert.view.transform = CGAffineTransform(rotationAngle: .pi/1)
            }
        })
    }
    
    // Make a 2.5 seconds message to users without a "OK" button
    func makeWarningMsg(_ msg: String, showToWhichSide: String = GlobalVars.WHITE_SIDE) {
        if GlobalVars.reverseBlackFlag && showToWhichSide == GlobalVars.BLACK_SIDE {
            self.view.makeToast(msg, duration: 2.5, position: .center, UpsideDown: true)
        } else {
            self.view.makeToast(msg, duration: 2.5, position: .center)
        }
    }
    
}
