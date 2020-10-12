//
//  BoardCell.swift
//  assignment
//
//  Created by Wennong Cai on 26/4/19.
//  Copyright © 2019 Wennong Cai. All rights reserved.
//

import UIKit

// BoardCell is a class to handle the logic as a single cell on the board, including storing the information about what kind of figure is in this cell currently, or change the background color of the cell.

class BoardCell {
    var horizontal = 0 // the column this cell is located, from 1 to 8
    var vertical = 0 // the row this cell is located. from 1 to 8
    
    var cellX: CGFloat? // The X coordinate in pixels when the top-left of the board is (0, 0)
    var cellY: CGFloat?
    var cellLength: CGFloat?
    var cellFigure: UIImageView?
    var cellFigureType: String?
    var cellFigureName: String?
    var cellView: UIView?
    var cellDefaultBackgroundColor: UIColor?
    
    var movableAreaIsHinting: Bool = false
    
    var attackArea: [BoardCell] = [] // Record all possible moves from this cell. If this cell has no figure, this variable will be empty array
    var moveableArea: [BoardCell] = [] // It will same as attackArea, except when the figure is pawn.(ie. the move and attack of the pawn is not same way)
    
    init() {}    // This is just the default non-input-parameter constructor. will never be invoked.
    
    init(horId:Int, verId:Int, x: CGFloat, y: CGFloat, length: CGFloat, color: UIColor) {
        horizontal = horId
        vertical = verId
        cellX = x
        cellY = y
        cellLength = length
        cellFigure = nil
        
        cellView = UIView(frame: CGRect(x: cellX!, y: cellY!, width: cellLength!, height: cellLength!))
        cellDefaultBackgroundColor = color
        cellView?.backgroundColor = cellDefaultBackgroundColor
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapHandler))
        cellView?.addGestureRecognizer(tap)
    }
    
    // This is the handling function, invoked when a board cell is clicked
    @objc func tapHandler(gesture: UITapGestureRecognizer){
        if gesture.state == .ended && !GlobalVars.mainDelegate!.draggingFigureFlag {
            if cellView!.backgroundColor != GlobalVars.ACTIVE_COLOR {
                // If the background color is the default color, which means the cell is clicked for the first time
                // Notify the main ViewController
                GlobalVars.mainDelegate?.cellClickedNotify(horizontal: horizontal, vertical: vertical)
            } else {
                // If it is not the default color, which means user is clicking it for the second time to cancel its selection.
                resetBackgroundColor(resetHint: true)
                GlobalVars.previousCellX = nil
                GlobalVars.previousCellY = nil
            }
        }
    }
    
    func activeBackgroundColor(isHovering: Bool = false){
        if isHovering {
            cellView!.backgroundColor = GlobalVars.HOVERING_COLOR
        }
        else {
            cellView!.backgroundColor = GlobalVars.ACTIVE_COLOR
            
            // When hint mode is on
            if GlobalVars.moveableHintFlag {
                movableAreaIsHinting = true
                for area in moveableArea {
                    area.cellView!.alpha = 0.5
                }
            }
        }
    }
    
    func checkColor(){cellView!.backgroundColor = GlobalVars.CHECKING_COLOR}
    
    func resetBackgroundColor(resetHint: Bool=false) {
        if GlobalVars.boardDelegate!.checkFlag ?? nil == cellFigureType && cellFigureName == "king" {
            checkColor()
        } else {
            cellView!.backgroundColor = cellDefaultBackgroundColor
        }
        
        if movableAreaIsHinting && resetHint {
            for area in moveableArea {
                area.resetHintAlpha()
            }
        }
    }
    
    func resetHintAlpha() {
        cellView!.alpha = 1.0
    }
    
    func setFigure(_ type: String, _ name: String){
        cellFigureName = name
        cellFigureType = type
        cellFigure = UIImageView(image: UIImage(named: "\(cellFigureType!)_\(cellFigureName!)"))
        if GlobalVars.reverseBlackFlag && type == GlobalVars.BLACK_SIDE {
            cellFigure?.transform = (cellFigure?.transform.rotated(by: .pi/1))!
        }
        updateFigureStatus()
    }
    
    func removeFigure() {
        cellFigure = nil
        cellFigureName = nil
        cellFigureType = nil
        updateFigureStatus()
    }
    
    func hideFigure(_ bool: Bool) {
        cellFigure?.isHidden = bool
    }
    
    func updateFigureStatus(){
        if let lastFigure = cellView!.viewWithTag(666) {
            lastFigure.removeFromSuperview() // if the cell already has a figure, remove it
        }
        // Then if the cell have a (new) figure now, add it as subview.
        if let f = cellFigure {
            f.frame = CGRect(x: 1, y: 1, width: cellLength!-2, height: cellLength!-2)
            f.tag = 666 // set a tag to remember this UIImageView
            cellView!.addSubview(f)
        }
    }
    
    func isSameCell(_ cell: BoardCell) -> Bool{
        if horizontal == cell.horizontal && vertical == cell.vertical {
            return true
        } else {
            return false
        }
    }
    
    func getCellView() -> UIView {
        return cellView!
    }
}
