//
//  GlobalVariables.swift
//  assignment
//
//  Created by Wennong Cai on 4/5/19.
//  Copyright © 2019 Wennong Cai. All rights reserved.
//

import UIKit

// GlobalVars contains some important data that need to be used across the whole application, or some data that may need to be changed for better experience, they all are extracted from the messy code to here.

class GlobalVars {
// Part A: might change values of belows for better User Experience
    // Colors for Game board
    static let ACTIVE_COLOR = UIColor(red: 199/255.0, green: 236/255.0, blue: 238/255.0, alpha: 1)    // The color of cell when selected by user
    static let HOVERING_COLOR = UIColor(red: 199/255.0, green: 236/255.0, blue: 238/255.0, alpha: 1)  // The color of the cell which user is dragging the figure and hovering on it
    static let CHECKING_COLOR = UIColor(red: 235/255.0, green: 77/255.0, blue: 75/255.0, alpha: 1) // The color of the cell which the king is checked
    static let BLACK_CELL_COLOR = UIColor.darkGray  // The color for black cells
    static let WHITE_CELL_COLOR = UIColor.lightGray // The color for white cells
    
    static let MOVE_DURATION = 0.8 // The time figure will take to move from one cell to the other
    static let EA_default: Float = 70
    
    // Colors for RegisterViewController
    static let FIELD_WARNING_COLOR = UIColor(red: 255/255.0, green: 121/255.0, blue: 121/255.0, alpha: 1) // When a text Field's text is not expected, it will show this background color to give user a warning
    
    
// ==============================
// Part B: User customised attributes in SettingViewController, require to save into the persistent data
    static var EA_value: Float = GlobalVars.EA_default
    static var moveableHintFlag: Bool = false // Indicate if the figure will show which they are able to move
    static var reverseBlackFlag: Bool = false // Indicate if the black figure should rotate 180 degree
    static var breatheToolbarFlag: Bool = false // Indicate if the toolbar for the current side should have "breathing" animation
    

// ==============================
// Part C: Do not change the values below, may cause APP crash
    static let WHITE_SIDE:String = "white"// Set these two strings as variables could avoid typo by accident when typing string.
    static let BLACK_SIDE:String = "black"
    
    static let EA_value_KEY = "EA_VALUE_KEY"
    static let moveableHint_KEY = "MOVEABLE_HINT_KEY"
    static let reverseBlack_KEY = "REVERSE_BLACK_KEY"
    static let breatheBlack_KEY = "BREATHE_KEY"
    static let storedGame_KEY = "STORED_GAME_KEY" // Keys for UserDefault
    
    static var current_in_offline_gaming_flag = false // This flag will be used by AppDelegate to dicide should the App perform save() function while the app is executing in the background.
    
    static var boardDelegate: requestMoveFigureDelegate?    // boardDelegate provides the access to all cells' data as well as usage of moveFigure method
    static var mainDelegate: MainGameDelegate?      // Through this delegate, we could notify the main ViewController that a cell is clicked
    static var previousCellX: Int?
    static var previousCellY: Int?
}
