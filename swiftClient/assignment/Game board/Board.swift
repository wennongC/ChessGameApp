//
//  Board.swift
//  assignment
//
//  Created by Wennong Cai on 26/4/19.
//  Copyright © 2019 Wennong Cai. All rights reserved.
//

import UIKit

// Board is a class contains all data related to the whole game board, including the chess rules logic and move figure logic.
// It contains a 2D array to represent 8x8 cells on the board.

protocol requestMoveFigureDelegate {
    var cells: [[BoardCell]] {get}
    var checkFlag: String? {get}
    
    // For saving function
    func makeSaveBundle(currentSide: String) -> SaveBundle
    func restoreAttr(bundle: SaveBundle)
}

class Board: requestMoveFigureDelegate {
    var cells: [[BoardCell]] = Array(repeating: Array(repeating: BoardCell(), count: 8), count: 8) // It's a 2-D array that contains all cells on the game board.
    var boardView: UIView? // it is the reference to the board UIview in the Main Game Controller
    var boardLength:CGFloat? // The side length of the board view
    
    var movingFlag = false // It indicates if there is a figure currently is moving. Used for preventing one figure starting to move before another figure finishing its move.
    
    var enPassantFlagOnBlack: Int = 0
    var enPassantFlagOnWhite: Int = 0
    var whiteKingCastlingFlag: Bool = true // King's wing castling
    var blackKingCastlingFlag: Bool = true
    var whiteQueenCastlingFlag: Bool = true // Queen's wing castling
    var blackQueenCastlingFlag: Bool = true
    var castlingType: castlingTypeEnum? // record which type of castling
    enum castlingTypeEnum {
        case whiteKingCastlingFlag, blackKingCastlingFlag, whiteQueenCastlingFlag, blackQueenCastlingFlag
    }
    
    var blackKingCell: BoardCell? // Record the King's position. (It's redundant because It could be done by loop through all cells to find a king, but since the king's cell will needed to be used in this class for multiple times, record it as variable might be a little faster to run the program)
    var whiteKingCell: BoardCell?
    var checkFlag: String? // record which side is current in "be check" status, "none" for default
    
    
    init(boardView: UIView) {
        self.boardView = boardView // reference the view in the controller
        
        GlobalVars.boardDelegate = self
        
        initCells() // Create all of 64 cells on the game board
        
        initFigure() // set figures of cells at their initial positions.
        
        updateAttackArea()
    }
    
    
    // This method will do the process of moving a figure from one cell to another. The third parameter indicates whether it is a instant move or animation move.
    // The "force" element indicates if this move should follow the rules.(ie. Some actions may require this, such as "take a step back", the pawn can not move backwards legally when you want to take it back step)
    func moveFigure(from: BoardCell, to: BoardCell, animate: Bool, castling: Bool=false, fromOnline: Bool=false) -> Bool{
        // You can not move the figures of opponent (black figures) under online mode)
        if !fromOnline {
            if GlobalVars.mainDelegate?.onlineFlag ?? true && from.cellFigureType == GlobalVars.BLACK_SIDE { return false }
        }
        
        if movingFlag && !castling {
            return false // if there is a figure is moving currently, do not perform the move.
            // Unless it is a castling
        } else {
            
            if let moving = from.cellFigure { // if The "from" cell has a figure
                
                if !from.isSameCell(to) // The FROM and TO can not be the same cell
                    && (chessRulesProtector(from: from, to: to) || castling) { // Check the rules, or the special case "castling"
                    
                    movingFlag = true // set the flag to indicate "in moving Progress"
                    GlobalVars.mainDelegate!.enableTouch(false) // disable the touch interaction on the game board when figure is moving
                    
                    // Get the type and name of moving figure
                    let type = from.cellFigureType!
                    let name = from.cellFigureName!
                    let removedType = to.cellFigureType ?? "null"
                    let removedName = to.cellFigureName ?? "null"
                    from.removeFigure() // first remove the figure from cell
                    to.setFigure(type, name)
                    to.hideFigure(true) // add it to new cell but hide it for now
                    updateKingCell(to)
                    updateAttackArea() // Update the attacking area
                    
                    // Check for there is a checkmate or not
                    if isChecked_KingFrom(type) {
                        // If it is, ROLL BACK this move.
                        ROLL_BACK(from: from, to: to, removedType: removedType, removedName: removedName) // Because this checking processing need to be tested after the figure has moved, so it can not be done inside the chessRulesProtector function.
                        GlobalVars.mainDelegate?.makeWarningMsg("The King will be danger⚠️ if you do that move", showToWhichSide: type)
                        
                        // reset all the settings
                        to.hideFigure(false)
                        self.movingFlag = false
                        GlobalVars.mainDelegate!.enableTouch(true)
                        return false // Terminate the current moveFigure
                    }
                    
                    let didPromotion = checkPromotionForPawn(originCell: from, cell: to) // check if it is a pawn and be ready for promotion
                    
                    // then create a new figure as subview of the whole boardView for animation
                    //   and create a new for the figure to be eaten if has.(Because if perform the animation, the eaten figure will take out before the moving figure arrives the destination)
                    // If user click two cell to make a move, the figure will perform an animation.
                    if animate {
                        if removedType != "null"{
                            let eaten = UIImageView(image: UIImage(named: "\(removedType)_\(removedName)"))
                            if GlobalVars.reverseBlackFlag && removedType == GlobalVars.BLACK_SIDE {
                                eaten.transform = eaten.transform.rotated(by: .pi/1)
                            }
                            eaten.frame = CGRect(x: to.cellX! + 1, y: to.cellY! + 1, width: from.cellLength!-2, height: from.cellLength!-2)
                            eaten.tag = 444
                            boardView!.addSubview(eaten)
                        }
                        
                        moving.frame = CGRect(x: from.cellX! + 1, y: from.cellY! + 1, width: from.cellLength!-2, height: from.cellLength!-2)
                        moving.tag = 999
                        boardView!.addSubview(moving)
                        // and set its new position to move it to there
                        let xPosition = moving.frame.origin.x + to.cellX! - from.cellX!
                        let yPosition = moving.frame.origin.y + to.cellY! - from.cellY!
                        let length = moving.frame.size.height
                        UIView.animate(withDuration: GlobalVars.MOVE_DURATION, animations: {
                            moving.frame = CGRect(x: xPosition, y: yPosition, width: length, height: length)
                        }) { _ in
                            // after animation done, remove the "eaten" figure, and show the figure in "to" cell
                            self.boardView!.viewWithTag(444)?.removeFromSuperview()
                            to.hideFigure(false)
                            self.boardView!.viewWithTag(999)?.removeFromSuperview()
                            // also, set teh movingFlag back to false
                            self.movingFlag = false
                            GlobalVars.mainDelegate!.enableTouch(true)
                        }
                    }
                    else
                    {
                        // If user drag to figure to the destination directly, there will be no additional animation
                        to.hideFigure(false)
                        self.movingFlag = false
                        GlobalVars.mainDelegate!.enableTouch(true)
                    }
                    
                    // If the move succeed, and under online mode, then send this move to the server (then the opponent will receive).
                    if type == GlobalVars.WHITE_SIDE
                        && GlobalVars.mainDelegate?.onlineFlag ?? false
                        && !didPromotion {
                        // If the user is performing a promotion, then do not emit the event for now, wait user to select which figure to promote
                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                        let olController = appDelegate.olController
                        olController?.makeMove(fromHor: from.horizontal, fromVer: from.vertical, toHor: to.horizontal, toVer: to.vertical)
                    }
                    
                    // After move, find out if the opposite side is a check or checkmate
                    detectGameOver(whichSideJustMoved: type, anime: animate)
                    
                    if movingFlag && !castling {
                        to.hideFigure(true)// detectCheckmate method might cancel the "hide" status by accident, which will cause the figure get showed earlier than expected when moveFigure by animation. Therefore, when movingFlag has not yet been changed back to false, we need make sure the Figure of "to" cell is still hidden.
                    }
                    
                    if castlingType != nil {
                        performCastling() // Perform the castling for Rook
                    }
                    
                    from.resetBackgroundColor()
                    
                    return true
                }
            }
        }

        // If the movement break the rules of chess
        // or if the figure does not have a figure do not make move
        return false
    }
    
    
    func initCells(){
        
        var screenWidth: CGFloat {
            return UIScreen.main.bounds.width
        }   // Screen width.
        
        boardLength = screenWidth - 8 // The height and width of The board
        let cellLength = boardLength! / 8.0
        
        // Initial all cell objects and add them as subviews of board
        // x is horizontal coordinate of board from 0 to 7
        // y is vertical coordinate of board from 0 to 7
        for x in 0...7{
            for y in 0...7{
                let cellX = 0 + cellLength * CGFloat(x)
                let cellY = 0 + cellLength * CGFloat(y)
                if (x + y) % 2 == 0 {
                    cells[x][y] = BoardCell(horId:x+1, verId:y+1, x: cellX, y: cellY, length: cellLength, color: GlobalVars.WHITE_CELL_COLOR)
                } else {
                    cells[x][y] = BoardCell(horId:x+1, verId:y+1, x: cellX, y: cellY, length: cellLength, color: GlobalVars.BLACK_CELL_COLOR)
                }
                self.boardView!.addSubview(cells[x][y].getCellView())
            }
        }
    }
    
    
    func initFigure(){
        // And for 8 pawns for each side
        for pawn_count in 1...8{
            cells[pawn_count-1][1].setFigure(GlobalVars.BLACK_SIDE, "pawn")
            cells[pawn_count-1][6].setFigure(GlobalVars.WHITE_SIDE, "pawn")
        }
        
        // Put all figures into their initial cells
        cells[0][0].setFigure(GlobalVars.BLACK_SIDE, "rook")
        cells[1][0].setFigure(GlobalVars.BLACK_SIDE, "knight")
        cells[2][0].setFigure(GlobalVars.BLACK_SIDE, "bishop")
        cells[3][0].setFigure(GlobalVars.BLACK_SIDE, "queen")
        cells[4][0].setFigure(GlobalVars.BLACK_SIDE, "king")
        cells[5][0].setFigure(GlobalVars.BLACK_SIDE, "bishop")
        cells[6][0].setFigure(GlobalVars.BLACK_SIDE, "knight")
        cells[7][0].setFigure(GlobalVars.BLACK_SIDE, "rook")
        blackKingCell = cells[4][0]
        
        cells[0][7].setFigure(GlobalVars.WHITE_SIDE, "rook")
        cells[1][7].setFigure(GlobalVars.WHITE_SIDE, "knight")
        cells[2][7].setFigure(GlobalVars.WHITE_SIDE, "bishop")
        cells[3][7].setFigure(GlobalVars.WHITE_SIDE, "queen")
        cells[4][7].setFigure(GlobalVars.WHITE_SIDE, "king")
        cells[5][7].setFigure(GlobalVars.WHITE_SIDE, "bishop")
        cells[6][7].setFigure(GlobalVars.WHITE_SIDE, "knight")
        cells[7][7].setFigure(GlobalVars.WHITE_SIDE, "rook")
        whiteKingCell = cells[4][7]
    }
    
    func getBoardView() -> UIView{
        return boardView!
    }
    
    func makeSaveBundle(currentSide: String) -> SaveBundle {
        return SaveBundle(boardCells: cells,
                          wkcf: whiteKingCastlingFlag,
                          bkcf: blackKingCastlingFlag,
                          wqcf: whiteQueenCastlingFlag,
                          bqcf: blackQueenCastlingFlag,
                          enPassBlack: enPassantFlagOnBlack,
                          enPassWhite: enPassantFlagOnWhite,
                          current: currentSide)
    }
    
    func restoreAttr(bundle: SaveBundle) {
        whiteKingCastlingFlag = bundle.whiteKingCastlingFlag
        blackKingCastlingFlag = bundle.blackKingCastlingFlag
        whiteQueenCastlingFlag = bundle.whiteQueenCastlingFlag
        blackQueenCastlingFlag = bundle.blackQueenCastlingFlag
        enPassantFlagOnBlack = bundle.enPassantFlagOnBlack
        enPassantFlagOnWhite = bundle.enPassantFlagOnWhite
        
        findKingCell()
        updateAttackArea()
        detectGameOver(whichSideJustMoved: bundle.currentSide == GlobalVars.WHITE_SIDE ? GlobalVars.BLACK_SIDE:GlobalVars.WHITE_SIDE, anime: false)
        // Check if user should choose new figure to make Promotion now
        for i in 0...7 {
            // Loop throught the last row.(because there only can be 1 pawn at the last row at same time
            let _ = checkPromotionForPawn(originCell: nil, cell: cells[i][bundle.currentSide == GlobalVars.WHITE_SIDE ? 7:0])
        }
    }
    
    

/*
     
======================================================
||                                                  ||
||     All Below are the Game Rules Logic Part      ||
||                                                  ||
======================================================
     
*/
    // If the test flag is true, The enPassantFlag and castlingFlag will not be updated
    
    // "Test is true" means that the program are just try to make a move to see is it still in rules after moving, but these "trying" moves should not be showed to users, they all will be roll back after tried.
    
    func chessRulesProtector(from: BoardCell, to: BoardCell, test:Bool=false, attackTest:Bool=false) -> Bool {
        if from.cellFigureType == to.cellFigureType{
            return false    // A figure can never eat another figure on the same side
        }
        
        // When the white side starts to make a new move, reset the flag of enPassant. And same for the black side.
        if !test {
            if from.cellFigureType == GlobalVars.WHITE_SIDE {
                enPassantFlagOnWhite = 0
            } else {
                enPassantFlagOnBlack = 0
            }
        }
        
        switch from.cellFigureName {
        case "pawn":
            if pawnRules(from, to, moveTest: test, attackTest: attackTest) {
                return true
            }
            break
        case "rook":
            if rookRules(from, to, test: test) {
                return true
            }
            break
        case "knight":
            if knightRules(from, to) {
                return true
            }
            break
        case "bishop":
            if bishopRules(from, to) {
                return true
            }
            break
        case "queen":
            if queenRules(from, to) {
                return true
            }
            break
        case "king":
            if kingRules(from, to, test: test) {
                return true
            }
            break
        default:
            break
        }
        return false
        
    }
    
    // Pawn Rules (and King Rules), are probably the most complex two compared with other types of figures.
    func pawnRules(_ from: BoardCell, _ to: BoardCell, moveTest: Bool, attackTest: Bool) -> Bool {
        if from.cellFigureType == GlobalVars.WHITE_SIDE {
            if from.vertical == 7
                && to.vertical == 5
                && to.horizontal == from.horizontal
                && to.cellFigure == nil
                && cells[to.horizontal-1][5].cellFigure == nil
                && !attackTest {
                // First move of pawn could be 2 cells vertically
                if !moveTest{
                    enPassantFlagOnWhite = from.horizontal// this flag indicates the next step of Black side could perform an En Passant move.
                }
                return true
            }
            else if from.vertical - 1 == to.vertical {  // " i 1 " Because white pawn is moving up
                if to.horizontal == from.horizontal
                    && to.cellFigure == nil
                    && !attackTest {
                    // Move straight one cell with no other figure ahead
                    return true
                }
                else if abs(from.horizontal - to.horizontal) == 1 {
                    // Eating other figures
                    if to.cellFigureType == GlobalVars.BLACK_SIDE || attackTest {
                        // Normal eat
                        return true
                    } else if from.vertical == 4
                        && to.horizontal == enPassantFlagOnBlack
                        && !attackTest {
                        if !moveTest {
                            // En Passant eat
                            cells[to.horizontal-1][3].removeFigure()
                        }
                        return true
                    }
                }
            }
        }
        else if from.cellFigureType == GlobalVars.BLACK_SIDE {
            if from.vertical == 2
                && to.vertical == 4
                && to.horizontal == from.horizontal
                && to.cellFigure == nil
                && cells[to.horizontal-1][2].cellFigure == nil
                && !attackTest {
                // First move of pawn could be 2 cells vertically
                if !moveTest {
                    enPassantFlagOnBlack = from.horizontal// this flag indicates the next step of White side could perform an En Passant move.
                }
                return true
            }
            else if from.vertical + 1 == to.vertical {  // " + 1 " Because black pawn is moving down
                if to.horizontal == from.horizontal
                    && to.cellFigure == nil
                    && !attackTest {
                    // Move straight one cell with no other figure ahead
                    return true
                }
                else if abs(from.horizontal - to.horizontal) == 1 {
                    // Eating other figures
                    if to.cellFigureType == GlobalVars.WHITE_SIDE || attackTest {
                        // Normal eat
                        return true
                    } else if(from.vertical == 5
                        && to.horizontal == enPassantFlagOnWhite)
                        && !attackTest{
                        if !moveTest {
                            // En Passant eat
                            cells[to.horizontal-1][4].removeFigure()
                        }
                        return true
                    }
                }
            }
        }
        return false
    }
    
    func rookRules(_ from: BoardCell, _ to: BoardCell, test: Bool) -> Bool {
        // Using FOR loops to check if there is a barrier figure in the way.
        if from.horizontal == to.horizontal {   // Move Vertically
            let a = min(from.vertical, to.vertical)
            let b = max(from.vertical, to.vertical)
            for i in a+1 ..< b{
                if cells[from.horizontal-1][i-1].cellFigure != nil {
                    return false
                }
            }
        } else if from.vertical == to.vertical {   // Move Horizontally
            let a = min(from.horizontal, to.horizontal)
            let b = max(from.horizontal, to.horizontal)
            for i in a+1..<b{
                if cells[i-1][from.vertical-1].cellFigure != nil {
                    return false
                }
            }
        } else {
            return false
        }
        
        if !test{
            // If the rook leaves its initial position successfully, then its side will no longer be able to perform a castling
            if from.horizontal == 1 && from.vertical == 1 {
                blackQueenCastlingFlag = false
            } else if from.horizontal == 8 && from.vertical == 1 {
                blackKingCastlingFlag = false
            } else if from.horizontal == 1 && from.vertical == 8 {
                whiteQueenCastlingFlag = false
            } else if from.horizontal == 8 && from.vertical == 8 {
                whiteKingCastlingFlag = false
            }
        }
        
        return true
    }
    
    func knightRules(_ from: BoardCell, _ to: BoardCell) -> Bool {
        // I use the multiplication to simplify the condition statement: Since both of horizontal and vertical are positive Int, the absolute value of their difference should be 1 for horizontally and 2 for vertically or in reverse order. So it is enough to just test if their multiplication equals to 1*2 == 2*1 == 2
        if abs(from.horizontal - to.horizontal) * abs(from.vertical - to.vertical) == 2 {
            return true
        }
        return false
    }
    
    func bishopRules(_ from: BoardCell, _ to: BoardCell) -> Bool {
        if abs(from.horizontal-to.horizontal) == abs(from.vertical-to.vertical) {   // Move diagonally
            let minHor = min(from.horizontal, to.horizontal)
            let maxHor = max(from.horizontal, to.horizontal)
            let minVer = min(from.vertical, to.vertical)
            
            // Using FOR loops to check if there is a barrier figure in the way.
            if (from.horizontal-to.horizontal)*(from.vertical-to.vertical) > 0 { // Ascent diagonal
                for i in 1 ..< (maxHor - minHor) {
                    if cells[minHor+i-1][minVer+i-1].cellFigure != nil {
                        return false
                    }
                }
            } else {    // Descent diagonal
                for i in 1 ..< (maxHor - minHor) {
                    if cells[maxHor-i-1][minVer+i-1].cellFigure != nil {
                        return false
                    }
                }
            }
            return true
        }
        return false
    }
    
    func queenRules(_ from: BoardCell, _ to: BoardCell) -> Bool {
        // Queen's move is actually just combination of rook and bishop :)
        if rookRules(from, to, test: true) || bishopRules(from, to) {
            return true
        }
        return false
    }
    
    func kingRules(_ from: BoardCell, _ to: BoardCell, test: Bool) -> Bool {
        // King's move is actually just same as Queen's except he can only move one cell each time
        if (abs(from.horizontal-to.horizontal) == 0 || abs(from.horizontal-to.horizontal) == 1)
            && (abs(from.vertical-to.vertical) == 0 || abs(from.vertical-to.vertical) == 1){
            
            // King can not move to the cell that is attacked by enermy
            if isInAttackArea(of: from.cellFigureType == GlobalVars.WHITE_SIDE ? GlobalVars.BLACK_SIDE:GlobalVars.WHITE_SIDE, whichCell: to){
                if !test {
                    GlobalVars.mainDelegate?.makeWarningMsg("The king will be attacked in that cell", showToWhichSide: from.cellFigureType!)
                }
                return false
            }
            
            if queenRules(from, to) {
                if !test {
                    // If the king left his origin position, then it will no longer be able to perform a castling
                    if from.cellFigureType == GlobalVars.WHITE_SIDE {
                        whiteKingCastlingFlag = false
                        whiteQueenCastlingFlag = false
                    } else {
                        blackKingCastlingFlag = false
                        blackQueenCastlingFlag = false
                    }
                }
                return true
            }
        } else if from.vertical == to.vertical
                    && (to.horizontal == 3 || to.horizontal == 7)
                    && from.horizontal == 5 {
            if from.cellFigureType == GlobalVars.WHITE_SIDE
                && from.vertical == 8 {
                if to.horizontal == 3 && whiteQueenCastlingFlag
                    && !isInAttackArea(of: GlobalVars.BLACK_SIDE, whichCell: cells[4][7])
                    && !isInAttackArea(of: GlobalVars.BLACK_SIDE, whichCell: cells[3][7])
                    && !isInAttackArea(of: GlobalVars.BLACK_SIDE, whichCell: cells[2][7])
                    && cells[3][7].cellFigure == nil
                    && cells[2][7].cellFigure == nil {
                    if !test {
                        // white queen's wing castling
                        castlingType = .whiteQueenCastlingFlag
                    }
                    return true
                } else if to.horizontal == 7 && whiteKingCastlingFlag
                    && !isInAttackArea(of: GlobalVars.BLACK_SIDE, whichCell: cells[4][7])
                    && !isInAttackArea(of: GlobalVars.BLACK_SIDE, whichCell: cells[5][7])
                    && !isInAttackArea(of: GlobalVars.BLACK_SIDE, whichCell: cells[6][7])
                    && cells[5][7].cellFigure == nil
                    && cells[6][7].cellFigure == nil {
                    if !test {
                        // white king's wing castling
                        castlingType = .whiteKingCastlingFlag
                    }
                    return true
                }
            } else if from.cellFigureType == GlobalVars.BLACK_SIDE
                && from.vertical == 1 {
                if to.horizontal == 3 && blackQueenCastlingFlag
                    && !isInAttackArea(of: GlobalVars.WHITE_SIDE, whichCell: cells[4][0])
                    && !isInAttackArea(of: GlobalVars.WHITE_SIDE, whichCell: cells[3][0])
                    && !isInAttackArea(of: GlobalVars.WHITE_SIDE, whichCell: cells[2][0])
                    && cells[3][0].cellFigure == nil
                    && cells[2][0].cellFigure == nil {
                    if !test {
                        // black queen's wing castling
                        castlingType = .blackQueenCastlingFlag
                    }
                    return true
                } else if to.horizontal == 7 && blackKingCastlingFlag
                    && !isInAttackArea(of: GlobalVars.WHITE_SIDE, whichCell: cells[4][0])
                    && !isInAttackArea(of: GlobalVars.WHITE_SIDE, whichCell: cells[5][0])
                    && !isInAttackArea(of: GlobalVars.WHITE_SIDE, whichCell: cells[6][0])
                    && cells[5][0].cellFigure == nil
                    && cells[6][0].cellFigure == nil {
                    if !test {
                        // black king's wing castling
                        castlingType = .blackKingCastlingFlag
                    }
                    return true
                }
            }
        }
        return false
    }
    
    // ========================
    // The below methods are not working for chessRulesProtector function, this one will be invoked by moveFigure after the figure completed the move
    func checkPromotionForPawn(originCell: BoardCell?, cell: BoardCell) -> Bool {
        // Check for Promotion for pawn
        if cell.cellFigureName == "pawn"{
            if cell.cellFigureType == GlobalVars.WHITE_SIDE && cell.vertical == 1 {
                GlobalVars.mainDelegate?.pawnPromotionNotify(from: originCell, toPromote: cell)
                return true
            } else if cell.cellFigureType == GlobalVars.BLACK_SIDE && cell.vertical == 8 {
                GlobalVars.mainDelegate?.pawnPromotionNotify(from: originCell, toPromote: cell)
                return true
            }
        }
        return false
    }
    
    // based on type then perform the castling for the rook
    func performCastling(){
        if let t = castlingType {
            // Decide if this castling is online move or not
            let isOnline: Bool = GlobalVars.mainDelegate?.onlineFlag ?? false
            
            switch t {
            case .whiteKingCastlingFlag:
                let _ = moveFigure(from: cells[7][7], to: cells[5][7], animate: true, castling: true, fromOnline: isOnline)
                break
            case .whiteQueenCastlingFlag:
                let _ = moveFigure(from: cells[0][7], to: cells[3][7], animate: true, castling: true, fromOnline: isOnline)
                break
            case .blackKingCastlingFlag:
                let _ = moveFigure(from: cells[7][0], to: cells[5][0], animate: true, castling: true, fromOnline: isOnline)
                break
            case .blackQueenCastlingFlag:
                let _ = moveFigure(from: cells[0][0], to: cells[3][0], animate: true, castling: true, fromOnline: isOnline)
                break
            }
            castlingType = nil
        }
    }
    
    // King's move, Castling, Winning condition all needs to know the attacking area of each figure.
    func updateAttackArea() {
        // Loop through all cells that has a figure
        for m in 0...7 {
            for n in 0...7 {
                if cells[m][n].cellFigure == nil {
                    cells[m][n].attackArea = []
                } else {
                    var moveArea: [BoardCell] = []
                    for x in 0...7 {
                        for y in 0...7 {
                            if chessRulesProtector(from: cells[m][n], to: cells[x][y], test: true) {
                                moveArea.append(cells[x][y])
                            }
                        }
                    }
                    cells[m][n].attackArea = moveArea
                    cells[m][n].moveableArea = moveArea
                    
                    // The special case for the pawn (attackArea is smaller than moveArea
                    if cells[m][n].cellFigureName == "pawn" {
                        var attackArea: [BoardCell] = []
                        for x in 0...7 {
                            for y in 0...7 {
                                if chessRulesProtector(from: cells[m][n], to: cells[x][y], test: true, attackTest: true) {
                                    attackArea.append(cells[x][y])
                                }
                            }
                        }
                        cells[m][n].attackArea = attackArea
                    } else if cells[m][n].cellFigureName == "king" {
                        // The special case for the king (attackArea is bigger than moveArea
                        var attackArea: [BoardCell] = []
                        let h = cells[m][n].horizontal
                        let v = cells[m][n].vertical
                        if h != 8 { attackArea.append(cells[h][v-1]) }
                        if h != 1 { attackArea.append(cells[h-2][v-1]) }
                        if v != 8 { attackArea.append(cells[h-1][v]) }
                        if v != 1 { attackArea.append(cells[h-1][v-2]) }
                        if h != 1 && v != 1 { attackArea.append(cells[h-2][v-2]) }
                        if h != 8 && v != 1 { attackArea.append(cells[h][v-2]) }
                        if h != 1 && v != 8 { attackArea.append(cells[h-2][v]) }
                        if h != 8 && v != 8 { attackArea.append(cells[h][v]) }
                        cells[m][n].attackArea = attackArea
                    }
                }
            }
        }
    }
    
    func updateKingCell(_ cell:BoardCell) {
        if cell.cellFigureName == "king" {
            if cell.cellFigureType == GlobalVars.WHITE_SIDE{
                whiteKingCell = cell
            } else {
                blackKingCell = cell
            }
        }
    }
    
    func findKingCell() {
        for x in 0...7 {
            for y in 0...7 {
                if cells[x][y].cellFigureName == "king" {
                    if cells[x][y].cellFigureType == GlobalVars.WHITE_SIDE {
                        whiteKingCell = cells[x][y]
                    } else if cells[x][y].cellFigureType == GlobalVars.BLACK_SIDE {
                        blackKingCell = cells[x][y]
                    }
                }
            }
        }
    }
    
    func ROLL_BACK(from:BoardCell, to:BoardCell, removedType:String, removedName:String) {
        // Roll back the "from" and "to" cell's figures
        from.setFigure(to.cellFigureType!, to.cellFigureName!)
        if removedType != "null" {
            to.setFigure(removedType, removedName)
        } else {
            to.removeFigure()
        }
        
        // Roll back the KingCell
        for x in 0...7 {
            for y in 0...7 {
                if let name = cells[x][y].cellFigureName{
                    if name == "king" {
                        if cells[x][y].cellFigureType == GlobalVars.WHITE_SIDE {
                            whiteKingCell = cells[x][y]
                        } else {
                            blackKingCell = cells[x][y]
                        }
                    }
                }
            }
        }
        updateAttackArea()
    }
    
    // Test if the specific cell is being attacked by the oppsite side
    func isInAttackArea(of: String, whichCell: BoardCell) -> Bool {
        for x in 0...7 {
            for y in 0...7 {
                if let type = cells[x][y].cellFigureType {
                    if type == of {
                        let count = cells[x][y].attackArea.count
                        for i in 0..<count {
                            if whichCell.isSameCell(cells[x][y].attackArea[i]) {
                                return true
                            }
                        }
                    }
                }
            }
        }
        return false
    }
    
    func isChecked_Test(from: BoardCell, to: BoardCell) -> Bool{
        var returnValue = false
        
        // Make the move by the program itself to test if there is a check after move
        let type = from.cellFigureType!
        let name = from.cellFigureName!
        let removedType = to.cellFigureType ?? "null"
        let removedName = to.cellFigureName ?? "null"
        from.removeFigure() // first remove the figure from cell
        to.setFigure(type, name)
        to.hideFigure(true) // add it to new cell but hide it for now
        updateKingCell(to)
        updateAttackArea() // Update the attacking area
        
        returnValue = isChecked_KingFrom(type)
        
        // ROLL BACK this move.
        ROLL_BACK(from: from, to: to, removedType: removedType, removedName: removedName) // Because this checking processing need to be tested after the figure has moved, so it can not be done inside the chessRulesProtector function.
        to.hideFigure(false)
        return returnValue
    }
    
    func isChecked_KingFrom(_ type: String) -> Bool {
        if type == GlobalVars.WHITE_SIDE {
            if isInAttackArea(of: GlobalVars.BLACK_SIDE, whichCell: whiteKingCell!) {
                return true
            }
        } else {
            if isInAttackArea(of: GlobalVars.WHITE_SIDE, whichCell: blackKingCell!) {
                return true
            }
        }
        return false
    }
    
    func detectCheckmate(_ type: String) -> Bool {
        for x in 0...7 {
            for y in 0...7 {
                let moveable = cells[x][y].moveableArea
                if cells[x][y].cellFigureType == type
                    && moveable.count != 0 {
                    for i in 0..<moveable.count {
                        // Test if the figure is allowded to move like this way without getting king been eaten
                        if !isChecked_Test(from: cells[x][y], to: moveable[i]){
                            // If yes, the figure can make this move. Then it is not a checkmate!
                            return false
                        }
                    }
                }
            }
        }
        return true
    }
    
    func detectDraw(_ type: String) -> Bool {
        for x in 0...7 {
            for y in 0...7 {
                if cells[x][y].cellFigureType == type
                    && cells[x][y].moveableArea.count != 0 {
                    return false
                }
            }
        }
        return true
    }
    
    // Detect if there is a check, checkmate, stalemate and then make the related reaction.
    // the moveFigure type (ie. "anime") is needed here to decide how to play the sound file
    func detectGameOver(whichSideJustMoved: String, anime: Bool) {
        var soundType: String = "move" // default sound file name
        if whichSideJustMoved == GlobalVars.WHITE_SIDE && isChecked_KingFrom(GlobalVars.BLACK_SIDE) {
            checkFlag = GlobalVars.BLACK_SIDE
            blackKingCell?.checkColor()
            GlobalVars.mainDelegate?.makeWarningMsg(">>> ⚜️CHECK⚜️ <<<", showToWhichSide: GlobalVars.BLACK_SIDE)
            soundType = "check"
            if detectCheckmate(GlobalVars.BLACK_SIDE) {
                // If found there is a checkmate
                GlobalVars.mainDelegate?.makeWarningMsg(">>>>> ♚CHECK MATE♔ <<<<<", showToWhichSide: GlobalVars.BLACK_SIDE)
                soundType = "checkmate"
                GlobalVars.mainDelegate?.gameOverNotify(winningSide: GlobalVars.WHITE_SIDE)
            }
        } else if whichSideJustMoved == GlobalVars.BLACK_SIDE && isChecked_KingFrom(GlobalVars.WHITE_SIDE) {
            checkFlag = GlobalVars.WHITE_SIDE
            whiteKingCell?.checkColor()
            GlobalVars.mainDelegate?.makeWarningMsg(">>> ⚜️CHECK⚜️ <<<", showToWhichSide: GlobalVars.WHITE_SIDE)
            soundType = "check"
            if detectCheckmate(GlobalVars.WHITE_SIDE) {
                // If found there is a checkmate
                GlobalVars.mainDelegate?.makeWarningMsg(">>>>> ♚CHECKMATE♔ <<<<<", showToWhichSide: GlobalVars.WHITE_SIDE)
                soundType = "checkmate"
                GlobalVars.mainDelegate?.gameOverNotify(winningSide: GlobalVars.BLACK_SIDE)
            }
        } else {
            // If none of the king is in danger, then no need for checkColor().
            checkFlag = nil
            blackKingCell?.resetBackgroundColor()
            whiteKingCell?.resetBackgroundColor()
            if detectDraw(whichSideJustMoved==GlobalVars.WHITE_SIDE ? GlobalVars.BLACK_SIDE:GlobalVars.WHITE_SIDE) {
                // If found there is a draw (ie. Stalemate)
                GlobalVars.mainDelegate?.makeWarningMsg("--- ♚STALEMATE♔ ---", showToWhichSide: GlobalVars.WHITE_SIDE)
                soundType = "stalemate"
                GlobalVars.mainDelegate?.gameOverNotify(winningSide: "both")
            }
        }
        
        if anime {
            DispatchQueue.main.asyncAfter(deadline: .now() + (GlobalVars.MOVE_DURATION * 3/4)) { //  For better UX, the sound should be played a little bit earlier than the completion of the animation
                GlobalVars.mainDelegate?.makeSound(fileName: soundType) // Game Sound for animation
            }
        } else {
            GlobalVars.mainDelegate?.makeSound(fileName: soundType)
        }
    }
    
}
