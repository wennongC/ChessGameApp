//
//  SaveFunction.swift
//  assignment
//
//  Created by Wennong Cai on 26/5/19.
//  Copyright © 2019 Wennong Cai. All rights reserved.
//

import UIKit

// SaveFunctions has some static utility functions related to deal with saving function of the game.

class SaveFunctions {
    // Save the current game function (UserDefault Way)
    static func saveGame(data: [SaveBundle]) {
        UserDefaults.standard.set(true, forKey: GlobalVars.storedGame_KEY)
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: false)
            UserDefaults.standard.set(data, forKey: "allSteps")
        } catch {
            print(error)
        }
    }

    // Load Game saving data (UserDefault Way)
    static func loadGame(cells: [[BoardCell]]) -> [SaveBundle]? {
        if UserDefaults.standard.bool(forKey: GlobalVars.storedGame_KEY) {
            var allStepsCollector: [SaveBundle] = []
            do {
                allStepsCollector = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(UserDefaults.standard.object(forKey: "allSteps") as! Data) as! [SaveBundle]
            } catch {
                print(error)
            }
            
            return allStepsCollector
        }
        return nil
    }
    
    static func reverseGameBoard(cells: [[BoardCell]], figureNames: [String], figureTypes: [String]) {
        var counter = 0
        for x in 0...7 {
            for y in 0...7 {
                if figureNames[counter] == "" {
                    cells[x][y].removeFigure()
                } else {
                    cells[x][y].setFigure(figureTypes[counter], figureNames[counter])
                }
                counter += 1
            }
        }
    }
    
    
}
