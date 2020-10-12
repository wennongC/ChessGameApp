//
//  ViewController.swift
//  assignment
//
//  Created by Wennong Cai on 11/3/19.
//  Copyright © 2019 Wennong Cai. All rights reserved.
//

import UIKit
import AVFoundation

// MainGameViewController is the main screen for the actual game
// It contains the Board instance and also control the functions of Toolbars.

protocol MainGameDelegate {
    func gameOverNotify(winningSide: String) // value "both" of winningSide argument means draw
    func pawnPromotionNotify(from: BoardCell?, toPromote: BoardCell)
    func cellClickedNotify(horizontal: Int, vertical: Int)
    func enableTouch(_ enable: Bool)
    func receiveChatMessage(msg: String)
    func makeWarningMsg(_ msg: String, showToWhichSide: String)
    func makeSound(fileName: String)
    
    var draggingFigureFlag: Bool {get}
    var gameOverFlag: Bool {get}
    var onlineFlag: Bool {get}
    
    // Invoked by OnlineGameController
    func onlineGameCheckOK()
    func onlineGameCheckFailed()
    func onlineMoveReceived(fromHor: Int, fromVer: Int, toHor: Int, toVer: Int)
    func onlinePromotionMoveReceived(fromHor: Int, fromVer: Int, toHor: Int, toVer: Int, become: String)
    func winReceived(msg: String)
    
    func save() // Used by AppDelegate.swift under offline mode
}

class MainGameViewController: UIViewController, MainGameDelegate {
    @IBOutlet weak var board: UIView!
    @IBOutlet weak var blackToolBar: UIView!
    @IBOutlet weak var blackToolBackground: UIView!
    @IBOutlet weak var whiteToolBar: UIView!
    @IBOutlet weak var whiteToolBackground: UIView!
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var blackExitButton: UIButton!
    @IBOutlet weak var surrenderButton: UIButton!
    @IBOutlet weak var blackSurrenderButton: UIButton!
    @IBOutlet weak var stepBackButton: UIButton!
    @IBOutlet weak var blackStepBackButton: UIButton!

    var EA_player: AVAudioPlayer!
    var gameBoard: Board?
    var boardLength: CGFloat = 0
    
    var draggingFigureFlag: Bool = false // Indicate if user is draging a figure currently.
    var dragFrom: BoardCell? // Record the initial cell drag from
    var lastDrag: BoardCell? // Record the last cell when user is doing the continous touching.( touchMoved )
    
    var currentSide = GlobalVars.WHITE_SIDE // Record which side is making the move currently
    var gameOverFlag = false
    var allStepsCollector: [SaveBundle] = [] // It will remember all steps been made in this game
    
    var loadingFlag = false // Told by the MenuViewController if the game should be loaded from data
    
    var onlineFlag = false
    var olController: OnlineGameController?
    var username: String?
    var mark: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GlobalVars.mainDelegate = self
        gameBoard = Board(boardView: board) // Initialize Game board
        boardLength = (gameBoard?.boardLength)!
        gameOverFlag = false
        
        if GlobalVars.reverseBlackFlag && !onlineFlag {
            blackToolBar.transform = blackToolBar.transform.rotated(by: .pi/1)
        }
        
        if loadingFlag && UserDefaults.standard.bool(forKey: GlobalVars.storedGame_KEY) && !onlineFlag {
            load()
        } else {
            // Save the initial Save Data
            let initialSaveData = GlobalVars.boardDelegate!.makeSaveBundle(currentSide: currentSide)
            allStepsCollector.append(initialSaveData)
        }
        
        if !onlineFlag{
            GlobalVars.current_in_offline_gaming_flag = true
        } else {
            //           >>> In the Online Mode <<<
            GlobalVars.current_in_offline_gaming_flag = false
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            olController = appDelegate.olController
            if olController?.connectedFlag ?? false {
                // Before the final connection check for both side of players
                showSpinner(onView: view, msg: "Waiting for Opponent")
                olController?.gameStartCheck()
                
                if let order = olController?.whoFirst {
                    switchSide(switchTo: order=="first" ? GlobalVars.WHITE_SIDE:GlobalVars.BLACK_SIDE)
                } else { createAlertMsg(title: "Error!", msg: "The server data occured some problem. (bug: side)") }
                // Some buttons are not available under online mode, so we need to remove them
                stepBackButton.removeFromSuperview()
                blackStepBackButton.removeFromSuperview()
                
                // In the online mode, change the blackExitButton's function to "View Opponent's detail"
                blackExitButton.setTitle("📜", for: .normal)
                blackExitButton.addTarget(self, action: #selector(userInfoButtonClick(_:)), for: .touchUpInside)
                // and change the blackSurrenderButton's function to "Online Chatting"
                blackSurrenderButton.setTitle("Chat", for: .normal)
                blackSurrenderButton.addTarget(self, action: #selector(chatButtonClick(_:)), for: .touchUpInside)
            } else {
                createAlertMsg(title: "Error!", msg: "The internet occured some problem. (bug: onlineController does not have connection)")
            }
        }
        
        if GlobalVars.breatheToolbarFlag {
            startBreathing()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        GlobalVars.current_in_offline_gaming_flag = false
    }
    
    // The game is ready to start
    func onlineGameCheckOK() {
        let order = olController?.whoFirst ?? "(bug: side)"
        removeSpinner()
        createAlertMsg(title: "\(order) to Start!", msg: "You are \(order) one to make move")
        username = olController?.oppositePlayer?.username ?? "Loading failed"
        mark = olController?.oppositePlayer?.mark ?? "Loading failed"
    }
    
    // The opponent did not connect to the current game, end it.
    func onlineGameCheckFailed() {
        removeSpinner()
        gameOverFlag = true
        createAlertMsg(title: "Woops", msg: "The opponent already left the game", returnVal: true)
    }
    
    // The opponent surrender or left the game
    func winReceived(msg: String) {
        gameOverNotify(winningSide: GlobalVars.WHITE_SIDE, msg: msg)
    }
    
    // It will be invoked when the game is over by someone wining or both drawing
    func gameOverNotify(winningSide: String) { gameOverNotify(winningSide: winningSide, msg: nil) }
    // If no game result message is passed in, the function will use its default value.
    func gameOverNotify(winningSide: String, msg: String?) {
        gameOverFlag = true
        
        if onlineFlag {
            if winningSide == GlobalVars.WHITE_SIDE {
                createAlertMsg(title: "🎉", msg: msg ?? "You Won!")
                olController?.updateRecord(gameResult: .win)
            } else if winningSide == GlobalVars.BLACK_SIDE {
                createAlertMsg(title: "😔", msg: msg ?? "You lost~")
                olController?.updateRecord(gameResult: .lose)
            } else if winningSide == "both" {
                createAlertMsg(title: "🤝", msg: msg ?? "Draw")
                olController?.updateRecord(gameResult: .draw)
            }
        } else {
            UserDefaults.standard.set(false, forKey: GlobalVars.storedGame_KEY) // Remove the current stored game
        }
        
        whiteToolBackground.alpha = 1.0
        blackToolBackground.alpha = 1.0
        if winningSide == GlobalVars.WHITE_SIDE {
            blackToolBackground.backgroundColor = GlobalVars.CHECKING_COLOR
        } else if winningSide == GlobalVars.BLACK_SIDE {
            whiteToolBackground.backgroundColor = GlobalVars.CHECKING_COLOR
        } else if winningSide == "both" {
            whiteToolBackground.backgroundColor = UIColor.green
            blackToolBackground.backgroundColor = UIColor.green
        }
    }
    
    
    // For saving the current game
    func save() {
        // The game will not be saved in online mode
        if !onlineFlag {
//            let saveBundle = GlobalVars.boardDelegate!.makeSaveBundle(currentSide: currentSide)
            SaveFunctions.saveGame(data: allStepsCollector)
        }
    }
    // For loading the saved game
    func load() {
        let saveBundles = SaveFunctions.loadGame(cells: gameBoard!.cells)
        if saveBundles != nil && saveBundles!.count > 0 {
            allStepsCollector = saveBundles!
            let current = saveBundles!.last!
            switchSide(switchTo: current.currentSide)
            SaveFunctions.reverseGameBoard(cells: gameBoard!.cells, figureNames: current.figureNames, figureTypes: current.figureTypes)
            GlobalVars.boardDelegate!.restoreAttr(bundle: current)
        } else {
            createAlertMsg(title: "Woops", msg: "An Error occured when loading the save data")
            let initialSaveData = GlobalVars.boardDelegate!.makeSaveBundle(currentSide: currentSide)
            allStepsCollector.append(initialSaveData)
        }
    }
    
    
    // It will exit the current Game
    func exit() {
        if onlineFlag {
            if !gameOverFlag {
                olController?.exitGame()
                olController?.updateRecord(gameResult: .lose)
                gameOverFlag = true
                // Delay a little bit to ensure the previous step all completed
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.navigationController?.popViewController(animated: true)
                }
            }
            navigationController?.popViewController(animated: true)
        }
        else {
            if !gameOverFlag { save() }
            navigationController?.popViewController(animated: true)
        }
    }
    
    // It will make a surrender to the opposite
    func surrender(who: String) {
        if onlineFlag {
            olController?.exitGame()
        }
        if who == GlobalVars.WHITE_SIDE {
            gameOverNotify(winningSide: GlobalVars.BLACK_SIDE)
        } else if who == GlobalVars.BLACK_SIDE {
            gameOverNotify(winningSide: GlobalVars.WHITE_SIDE)
        }
    }
    
    // It allows user to take a step back
    func stepBack() {
        if allStepsCollector.count > 1 {
            let _ = allStepsCollector.popLast()! // Throw the last saveData (which is the data user is viewing before step back
            let lastStep = allStepsCollector.last! // read the new last saveData after thrown (so originally second last element)
            switchSide(switchTo: lastStep.currentSide)
            SaveFunctions.reverseGameBoard(cells: gameBoard!.cells, figureNames: lastStep.figureNames, figureTypes: lastStep.figureTypes)
            GlobalVars.boardDelegate!.restoreAttr(bundle: lastStep)
        } else {
            makeWarningMsg("No more step can be reversed", showToWhichSide: GlobalVars.WHITE_SIDE)
        }
    }
    
    
// The Action function of six buttons in the Toolbars
    func getToolBtnMsg(_ action: actionType) -> String{
        switch action {
        case .exit:
            var msg = "Are you sure you want to exit the current game?"
            if !gameOverFlag {
                if onlineFlag { msg += "\nYou will lose if you exit game in the Online Mode" }
                else { msg += "\nThe current game will be saved for continuing next time." }
            }
            return msg
        case .blackSurrender:
            return "Are you sure you want to surrender now?"
        case .whiteSurrender:
            return "Are you sure you want to surrender now?"
        case .stepBack:
            return "Are you sure you want to step back?\nSteps record:\(allStepsCollector.count - 1)"
        }
    }
    @IBAction func exitButtonClick(_ sender: Any) {
        confirmAlertController(title: "Exit Game", msg: getToolBtnMsg(.exit), action: .exit)
    }
    @IBAction func blackExitButtonClick(_ sender: Any) {
        if !onlineFlag {
            confirmAlertController(title: "Exit Game", msg: getToolBtnMsg(.exit), action: .exit, UpsideDown: GlobalVars.reverseBlackFlag)
        }
    }
    @objc func userInfoButtonClick(_ sender: UIButton) {
        // This handler will share the same button with blackExitButtonClick, but in online mode.
        createAlertMsg(title: "Opponent", msg: "Name: \(username ?? "LoadingFailed")\n mark: \(mark ?? "LoadingFailed")\n")
    }
    @IBAction func surrenderButtonClick(_ sender: Any) {
        if !gameOverFlag {
            confirmAlertController(title: "Surrender", msg: getToolBtnMsg(.whiteSurrender), action: .whiteSurrender)
        }
    }
    @IBAction func blackSurrenderButtonClick(_ sender: Any) {
        if !gameOverFlag && !onlineFlag {
            confirmAlertController(title: "Surrender", msg: getToolBtnMsg(.blackSurrender), action: .blackSurrender, UpsideDown: GlobalVars.reverseBlackFlag)
        }
    }
    @objc func chatButtonClick(_ sender: UIButton) {
        // This handler will share the same button with blackSurrenderButtonClick, but in online mode.
        showOnlineChatAlert()
    }
    @IBAction func whiteStepBackButtonClick(_ sender: Any) {
        confirmAlertController(title: "Step Back", msg: getToolBtnMsg(.stepBack), action: .stepBack)
    }
    @IBAction func blackStepBackButtonClick(_ sender: Any) {
        confirmAlertController(title: "Step Back", msg: getToolBtnMsg(.stepBack), action: .stepBack, UpsideDown: GlobalVars.reverseBlackFlag)
    }
    
    enum actionType {
        case exit
        case whiteSurrender
        case blackSurrender
        case stepBack
    }
    func confirmAlertController(title: String, msg: String, action: actionType, UpsideDown: Bool=false){
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Confirm", style: .destructive, handler: { _ in
            if action == .exit { self.exit() }
            else if action == .whiteSurrender { self.surrender(who: GlobalVars.WHITE_SIDE) }
            else if action == .blackSurrender { self.surrender(who: GlobalVars.BLACK_SIDE) }
            else if action == .stepBack { self.stepBack() }
        }))
        self.present(alert, animated: false, completion: {() -> Void in
            if UpsideDown {
                alert.view.transform = CGAffineTransform(rotationAngle: .pi/1)
            }
        })
    }
    

    
    // It will be called by moveFigure func inside Board class when a pawn reaches its last line.
    func pawnPromotionNotify(from: BoardCell?, toPromote: BoardCell) {
        if onlineFlag && toPromote.cellFigureType == GlobalVars.BLACK_SIDE { return }
        
        if toPromote.cellFigureName == "pawn" {
            let alert = UIAlertController(title: "Promotion", message: "Select a figure to make promotion", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Rook", style: .default, handler: { (_) in
                handler("rook")
            }))
            alert.addAction(UIAlertAction(title: "Knight", style: .default, handler: { (_) in
                handler("knight")
            }))
            alert.addAction(UIAlertAction(title: "Bishop", style: .default, handler: { (_) in
                handler("bishop")
            }))
            alert.addAction(UIAlertAction(title: "Queen", style: .default, handler: { (_) in
                handler("queen")
            }))
            
            func handler(_ figureName: String) {
                if onlineFlag {
                    olController?.makePromotionMove(
                        fromHor: from!.horizontal,
                        fromVer: from!.vertical,
                        toHor: toPromote.horizontal,
                        toVer: toPromote.vertical, become: figureName)
                }
                
                toPromote.setFigure(toPromote.cellFigureType!, figureName)
                
                if !onlineFlag {
                    let saveData: SaveBundle = gameBoard!.makeSaveBundle(currentSide: currentSide)
                    let _ = allStepsCollector.popLast()
                    allStepsCollector.append(saveData)
                }
                
                gameBoard!.updateAttackArea()
                gameBoard!.detectGameOver(whichSideJustMoved: toPromote.cellFigureType!, anime: false)
            }
            self.present(alert, animated: false, completion: {() -> Void in
                if GlobalVars.reverseBlackFlag && toPromote.cellFigureType == GlobalVars.BLACK_SIDE {
                    alert.view.transform = CGAffineTransform(rotationAngle: .pi/1)
                }
            })
        }
    }
    
    // It will be invoked by a BoardCell object when that object is clicked by users.
    func cellClickedNotify(horizontal: Int, vertical: Int){
        if gameOverFlag { return }
        
        let bd = gameBoard!   // Access Board class
        let preX = GlobalVars.previousCellX
        let preY = GlobalVars.previousCellY  // These three variables are just for simplify the variable names
        
        if bd.cells[horizontal-1][vertical-1].cellFigureType == currentSide {
            // This might improve the UX
            // When user first click his/her own figure, then click another figure on same side, he/she probably just want to re-select a figure that he/she want to move.
            
            if GlobalVars.previousCellX != nil {bd.cells[preX!-1][preY!-1].resetBackgroundColor(resetHint: true)}
            bd.cells[horizontal-1][vertical-1].activeBackgroundColor() // Change the color to indicate the figure has been re-selected
            GlobalVars.previousCellX = horizontal
            GlobalVars.previousCellY = vertical
        }
        else if GlobalVars.previousCellX != nil {
            // If find the previous cell has already been selected.
            // The user might mean to make a move now.
            bd.cells[preX!-1][preY!-1].resetBackgroundColor(resetHint: true)
            let moveIsSuccess = bd.moveFigure(from: bd.cells[preX!-1][preY!-1], to: bd.cells[horizontal-1][vertical-1], animate: true)
            if moveIsSuccess {
                bd.cells[preX!-1][preY!-1].resetBackgroundColor() // reset the color again to resolve the bug that CHECK_COLOR didn't dispear
                moveSuccess()
            }
            
            GlobalVars.previousCellX = nil
            GlobalVars.previousCellY = nil
        }
        
    }
    
    func onlineMoveReceived(fromHor: Int, fromVer: Int, toHor: Int, toVer: Int) {
        if let b = gameBoard {
            let s = b.moveFigure(from: b.cells[fromHor-1][fromVer-1], to: b.cells[toHor-1][toVer-1], animate: true, fromOnline: true)
            if s {
                moveSuccess()
            }
        }
    }
    
    func onlinePromotionMoveReceived(fromHor: Int, fromVer: Int, toHor: Int, toVer: Int, become: String) {
        if let b = gameBoard {
            let s = b.moveFigure(from: b.cells[fromHor-1][fromVer-1], to: b.cells[toHor-1][toVer-1], animate: true, fromOnline: true)
            if s {
                let toPromote = b.cells[toHor-1][toVer-1]
                toPromote.setFigure(GlobalVars.BLACK_SIDE, become)
                gameBoard!.updateAttackArea()
                gameBoard!.detectGameOver(whichSideJustMoved: toPromote.cellFigureType!, anime: false)
                moveSuccess()
            }
        }
    }
    
    // It contains things to do after a successful figure move
    func moveSuccess() {
        if gameOverFlag { return }
        //  change "currentSide" value, as well as the alpha value of Side ToolBar
        switchSide(switchTo: currentSide == GlobalVars.WHITE_SIDE ? GlobalVars.BLACK_SIDE:GlobalVars.WHITE_SIDE)
        // And save the steps of players
        let saveData: SaveBundle = GlobalVars.boardDelegate!.makeSaveBundle(currentSide: currentSide)
        allStepsCollector.append(saveData)
    }
    
    func switchSide(switchTo: String){
        currentSide = switchTo
        if currentSide == GlobalVars.WHITE_SIDE {
            whiteToolBackground.alpha = 1.0
            blackToolBackground.alpha = 0.3
        } else {
            whiteToolBackground.alpha = 0.3
            blackToolBackground.alpha = 1.0
        }
    }
    
    func startBreathing() {
        if gameOverFlag { return }
        
        var toolbar: UIView = whiteToolBackground
        if currentSide == GlobalVars.WHITE_SIDE {
            blackToolBackground.alpha = 0.3
            toolbar = whiteToolBackground
        }
        else if currentSide == GlobalVars.BLACK_SIDE {
            whiteToolBackground.alpha = 0.3
            toolbar = blackToolBackground
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            toolbar.alpha = 0.5
        }) { _ in
            UIView.animate(withDuration: 0.3, animations: {
                toolbar.alpha = 1.0
            }) { _ in
                self.startBreathing()
            }
        }
    }
    
    func showOnlineChatAlert() {
        let alertMsg = "You could send Chat message to the opponent"
        let alert = UIAlertController(title: "Online Chat", message: alertMsg, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Send", style: .default) { (_) in
            if let txtField = alert.textFields?.first, let text = txtField.text {
                self.olController?.sendMessage(msg: text)
                let displayMsg = "You : \"" + text + "\""
                self.view.makeToast(displayMsg, duration: 4.0, position: .top)
            }
        })
        alert.addTextField { (textField) in
            textField.placeholder = "Chat Message"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alert, animated: true, completion: nil)
    }
    
    func receiveChatMessage(msg: String) {
        let user = username ?? "Your opponent"
        let displayMsg = user + ": \"" + msg + "\""
        view.makeToast(displayMsg, duration: 4.0, position: .top)
    }
    
    // This function could disable user interaction
    func enableTouch(_ enable: Bool) {
        board.isUserInteractionEnabled = enable
    }
    
    // Send '.wav' sound file name to make sound
    func makeSound(fileName: String) {
        // Not block other background music (ie. 3rd Party music app)
        // --- Reference ---
        // Solution found at: https://stackoverflow.com/questions/29024320/how-can-i-allow-background-music-to-continue-playing-while-my-app-still-plays-it
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.ambient)
        try? AVAudioSession.sharedInstance().setActive(true)
        
        let url = Bundle.main.url(forResource: fileName, withExtension: "wav")
        do {
            EA_player = try AVAudioPlayer(contentsOf: url!)
        } catch {
            print(error)
        }
        EA_player.volume = GlobalVars.EA_value / 100
        EA_player.play()
    }
    
    //==========================================================//
    // The code below is to deal with dragging figure function  //
    
    // When user start to try to drag a figure
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameOverFlag { return } // If game is already over, do not handle any touch event
        if let touch = touches.first {
            
            if !draggingFigureFlag {   // First check draggingFlag to avoid users using 2 fingers to move figures
                let position = touch.location(in: board)// Get the inital touch position
                // Check if the touch point is inside the game board
                if position.x > 0 && position.x < boardLength && position.y > 0 && position.y < boardLength {
                    let cell = getCellOnPostion(position) // get the cell information based on the position of touch point
                    if cell.cellFigureType == currentSide {
                        dragFrom = cell // Remember the current cell
                        // Only When user move their fingers from one cell to another Then it will be recognized as dragging gesture
                        // (This could avoid some small drag by accident
                    } else {
                        dragFrom = nil
                    }
                }
            }
            else if dragFrom != nil {
                // If user try to drag figures with multiple fingers, Terminate the current drag and give user a little warning
                draggingFigureFlag = false
                dragFrom?.updateFigureStatus()// Rollback the position of the figure
                board.viewWithTag(1111)?.removeFromSuperview()
                dragFrom = nil
                if lastDrag != nil {lastDrag?.resetBackgroundColor()}
                makeWarningMsg("Please don't use multi-fingers to move figures😉", showToWhichSide: currentSide)
            }
        }
    }
    // When user is dragging a figure
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: board)
            var cell: BoardCell?
            
            if position.x > 0 && position.x < boardLength && position.y > 0 && position.y < boardLength {
                cell = getCellOnPostion(position)
            }
            
            if draggingFigureFlag {
                let imageFrame = board.viewWithTag(1111)?.frame
                let imgLength = (imageFrame?.size.width)!
                // Always keep the central of the figure image at the touch point
                board.viewWithTag(1111)?.frame =
                    CGRect(x: position.x-(imgLength/2), y: position.y-(imgLength/2),
                           width: imgLength, height: imgLength)
                
                // These lines will could light up the cell which user currently is, to help user avoid to drag into wrong cell.
                if lastDrag != nil {lastDrag?.resetBackgroundColor()}
                cell?.activeBackgroundColor(isHovering: true)
                lastDrag = cell
            }
            else if dragFrom != nil {
                if !(cell?.isSameCell(dragFrom!) ?? true) && dragFrom!.cellFigure != nil {
                    // Only When user move their fingers from one cell to another, Then it will be recognized as dragging gesture
                    // (This could avoid some small drag by accident)
                    draggingFigureFlag = true
                    dragFrom?.resetBackgroundColor()
                    if GlobalVars.moveableHintFlag { dragFrom?.activeBackgroundColor() }
                    // Hide the original figure and create a new one as subview of the whole boardView
                    let moving = dragFrom!.cellFigure!
                    let length = dragFrom!.cellLength!
                    moving.frame = CGRect(x: dragFrom!.cellX! + 1, y: dragFrom!.cellY! + 1, width: length-2, height: length-2)
                    moving.tag = 1111
                    board.addSubview(moving)
                }
            }
        }
    }
    // When user release his/her touch. (ie. Stop dragging a figure)
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if draggingFigureFlag {
                let position = touch.location(in: board)
                if GlobalVars.moveableHintFlag { dragFrom?.resetBackgroundColor(resetHint: true) }
                
                if position.x > 0 && position.x < boardLength && position.y > 0 && position.y < boardLength {
                    let destinationCell = getCellOnPostion(position)
                    // Invoke the "moveFigure" method. Use "if statement" to test if the move is successful
                    if gameBoard?.moveFigure(from: dragFrom!, to: destinationCell, animate: false) ?? false {
                        dragFrom?.resetBackgroundColor()
                        board.viewWithTag(1111)?.removeFromSuperview()
                        moveSuccess()
                    } else {
                        // Move fail case
                        dragFrom?.updateFigureStatus()// Rollback the position of the figure
                        board.viewWithTag(1111)?.removeFromSuperview()
                    }
                    destinationCell.resetBackgroundColor() // reset color
                } else {
                    // Throw the figure outside the game board case
                    dragFrom?.updateFigureStatus()// Rollback the position of the figure
                    board.viewWithTag(1111)?.removeFromSuperview()
                }
                draggingFigureFlag = false // reset the drag
                dragFrom = nil
            }
        }
    }
    // This function could calculate which cell the user is touched.
    func getCellOnPostion(_ position: CGPoint) -> BoardCell{
        let cellXIndex = Int(floor(position.x / (boardLength/8)))
        let cellYIndex = Int(floor(position.y / (boardLength/8)))
        return (GlobalVars.boardDelegate?.cells[cellXIndex][cellYIndex])!
    }
    
    // The dragging figure function part completed here         //
    //==========================================================//
}

