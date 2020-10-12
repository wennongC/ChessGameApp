//
//  spinner.swift
//  assignment
//
//  Created by Wennong Cai on 23/5/19.
//  Copyright © 2019 Wennong Cai. All rights reserved.
//
// Reference: http://brainwashinc.com/2017/07/21/loading-activity-indicator-ios-swift/
// have some changes from the origin code

import UIKit

var vSpinner : UIView?

extension UIViewController {
    func showSpinner(onView : UIView, msg: String = "Loading...") {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 83/256, green: 92/256, blue: 104/256, alpha: 0.9)
        let ai = UIActivityIndicatorView.init(style: .whiteLarge)
        ai.startAnimating()
        ai.center = spinnerView.center
        let label = UILabel.init(frame: CGRect(x: 0, y: ai.center.y - 64, width: spinnerView.frame.width, height: 30))
        label.text = msg
        label.textColor = .white
        label.textAlignment = .center
        
        print("\n\n\nSTART\n\n\n")
        spinnerView.addSubview(ai)
        spinnerView.addSubview(label)
        onView.addSubview(spinnerView)
        
        vSpinner = spinnerView
    }
    
    func removeSpinner() {
        print("\n\n\nEND\n\n\n")
        vSpinner?.removeFromSuperview()
        vSpinner = nil
    }
}
