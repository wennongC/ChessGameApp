//
//  OnlineGameController.swift
//  assignment
//
//  Created by Wennong Cai on 27/5/19.
//  Copyright © 2019 Wennong Cai. All rights reserved.
//

import Foundation
import SocketIO
import Firebase

// OnlineGameController handle all the connection logic to the Socket.IO server
// It can receive data as well as send data to the server.


// The local test server's URL: "http://localhost:8080"
// The server's URL: "https://chess-app-server.herokuapp.com/"

class OnlineGameController {
    let manager = SocketManager(socketURL: URL(string: "https://chess-app-server.herokuapp.com/")!, config: [.log(true), .compress])
    let socket: SocketIOClient
    var connectedFlag: Bool = false
    var ViewControllerConnectFrom: OnlineViewController? // Which viewcontroller invoke the connect() function
    
    var db: Firestore?
    var user: User?
    
    struct PlayerInfo {
        let username: String
        let mark: String
    }
    var oppositePlayer: PlayerInfo?
    var whoFirst: String?
    
    init() {
        socket = manager.defaultSocket
        addHandlers()
    }
    
    func connect(vc: OnlineViewController, user: User) {
        self.user = user
        ViewControllerConnectFrom = vc
        vc.showSpinner(onView: vc.view, msg: "Connecting Server...")
        addHandlers()
        socket.connect(timeoutAfter: 60) {
            vc.removeSpinner()
            do {
                try vc.authController?.signOut()
            } catch let signOutError as NSError {
                print ("Error signing out: %@", signOutError)
            }
            vc.createAlertMsg(title: "Time Out", msg: "The server is not responding", returnVal: true)
        }
    }
    
    func addHandlers() {
        socket.on("connect") {[weak self] data, ack in
            self?.db = Firestore.firestore()
            print("\n\n\n Socket Connected! \n\n\n")
            self?.connectedFlag = true
            let vc = self?.ViewControllerConnectFrom
            if vc?.email != nil && vc?.username != nil && vc?.mark != nil{
                self?.sendLoginInfo(email: vc!.email!, username: vc!.username!, mark: vc!.mark!)
            }
            return
        }
        
        socket.on("loginSuccess") { [weak self] data, ack in
            print("\n\n Login Successful! \n\n")
            self?.ViewControllerConnectFrom?.removeSpinner()
            self?.ViewControllerConnectFrom?.makeWarningMsg("Welcome to the Online Mode")
        }
        
        socket.on("disconnect") {[weak self] data, ack in
            self?.connectedFlag = false
            return
        }
        
        // Found the opposite player, which means the game is ready to start
        socket.on("gameStart") {[weak self] data, ack in
            print("\n\n gameStart: \(data) \n\n")
            if data.count == 3 && self?.oppositePlayer == nil {
                self?.whoFirst = data[0] as? String
                self?.oppositePlayer = PlayerInfo(username: data[1] as! String, mark: data[2] as! String)
                self?.ViewControllerConnectFrom?.view.isUserInteractionEnabled = false
                self?.ViewControllerConnectFrom?.dismissActivityIndicatorAlert()
                // Seemed sometimes the dismissActicity() will take more time than expected to dismiss, so the navigation delays a bit.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.ViewControllerConnectFrom?.view.isUserInteractionEnabled = true
                    self?.ViewControllerConnectFrom?.performSegue(withIdentifier: "onlineStartSegue", sender: self?.ViewControllerConnectFrom)
                }
            }
            return
        }
        
        // Search Result when users want to search a specific user
        socket.on("searchResult") {[weak self] data, ack in
            print("\n\n SEARCH RESULT: \(data) \n\n")
            if data.count != 0 {
                let email = data[0] as! String
                let username = data [1] as! String
                self?.ViewControllerConnectFrom?.showSearchResult(hasResult: true, email: email, username: username)
            } else {
                self?.ViewControllerConnectFrom?.showSearchResult(hasResult: false)
            }
            return
        }
        socket.on("invitation") {[weak self] data, ack in
            print("\n\n Invitation from \(data) \n\n")
            if data.count != 0 {
                self?.ViewControllerConnectFrom?.invitationReceived(from: data[0] as! String)
            }
            return
        }
        socket.on("invitationRefused") {[weak self] data, ack in
            print("\n\n Refused, reason: \(data) \n\n")
            if data.count != 0 {
                self?.ViewControllerConnectFrom?.showRefusedInfo(msg: data[0] as! String)
            } else {
                self?.ViewControllerConnectFrom?.showRefusedInfo(msg: "Some error occurred when invitating other player")
            }
            return
        }
        
        // 2 kinds reply of gameStartCheck from server
        socket.on("ok") {data, ack in
            if GlobalVars.mainDelegate?.onlineFlag ?? false {
                print("\n\n OK \n\n")
                GlobalVars.mainDelegate?.onlineGameCheckOK()
            }
            return
        }
        socket.on("error") {data, ack in
            if GlobalVars.mainDelegate?.onlineFlag ?? false {
                print("\n\n ERROR: \n\n")
                GlobalVars.mainDelegate?.onlineGameCheckFailed()
            }
            return
        }
        
        // Receive the move of opposite player
        socket.on("makeMove") {data, ack in
            if GlobalVars.mainDelegate?.onlineFlag ?? false {
                print("\n\n makeMove: \(data) \n\n")
                if data.count == 4 && GlobalVars.boardDelegate != nil {
                    let fromHor = Int(data[0] as! String)!
                    let fromVer = Int(data[1] as! String)!
                    let toHor = Int(data[2] as! String)!
                    let toVer = Int(data[3] as! String)!
                    GlobalVars.mainDelegate?.onlineMoveReceived(fromHor: fromHor, fromVer: fromVer, toHor: toHor, toVer: toVer)
                }
            }
            return
        }
        socket.on("makePromotionMove") {data, ack in
            if GlobalVars.mainDelegate?.onlineFlag ?? false {
                if data.count == 5 && GlobalVars.boardDelegate != nil {
                    let fromHor = Int(data[0] as! String)!
                    let fromVer = Int(data[1] as! String)!
                    let toHor = Int(data[2] as! String)!
                    let toVer = Int(data[3] as! String)!
                    let become = data[4] as! String
                    GlobalVars.mainDelegate?.onlinePromotionMoveReceived(fromHor: fromHor, fromVer: fromVer, toHor: toHor, toVer: toVer, become: become)
                    print("\n\n makePromotionMove: \(data) \n\n")
                }
            }
            return
        }
        
        socket.on("message") {data, ack in
            if GlobalVars.mainDelegate?.onlineFlag ?? false {
                if let msg = data[0] as? String {
                    GlobalVars.mainDelegate?.receiveChatMessage(msg: msg)
                }
            }
            return
        }
        
        // When the player win the game because of the opponent leaves or surrenders
        socket.on("win") {data, ack in
            print("\n\n OK: \(data) \n\n")
            let winMessage: String = data[0] as? String ?? ""
            GlobalVars.mainDelegate?.winReceived(msg: winMessage)
            return
        }
        
    }
    
    // Server need some basic information about this player
    func sendLoginInfo(email: String, username: String, mark: String) {
        socket.emit("login", with: [email, username, mark])
    }
    
    // quickStart mode (start to search other player)
    func quickStart() {
        oppositePlayer = nil
        socket.emit("quickStart", with: [])
    }
    
    // Stop to search other player
    func cancelWaiting() {
        socket.emit("cancelWaiting", with: [])
    }
    
    func searchPlayer(player: String) {
        socket.emit("searchPlayer", with: [player])
    }
    func selectPlayer(email: String) {
        socket.emit("selectPlayer", with: [email])
    }
    
    func responseInvitation(response: Bool) {
        socket.emit("invitationResponse", with: [response])
    }
    
    // After enter the game, first check with the server if the opposite player is still online.(due to Internet speed, that player may leave the game during this player is entering the game.
    func gameStartCheck() {
        socket.emit("gameStartCheck", with: [])
    }
    
    func makeMove(fromHor: Int, fromVer: Int, toHor: Int, toVer: Int) {
        // Both players will have white-side view, so Vertical is upside-down
        socket.emit("makeMove", with: [String(fromHor), String(9-fromVer), String(toHor), String(9-toVer)])
    }
    
    func makePromotionMove(fromHor: Int, fromVer: Int, toHor: Int, toVer: Int, become: String) {
        // Both players will have white-side view, so Vertical is upside-down
        // become is the name of the figure after promotion
        socket.emit("makePromotionMove", with: [String(fromHor), String(9-fromVer), String(toHor), String(9-toVer), become])
    }
    
    func sendMessage(msg: String) {
        // Send chatting message through chat function
        socket.emit("message", with: [msg])
    }
    
    func exitGame() {
        socket.emit("exitGame", with: [])
        oppositePlayer = nil
    }
    
    func logOut() {
        socket.disconnect()
        connectedFlag = false
        ViewControllerConnectFrom = nil
        oppositePlayer = nil
        user = nil
    }
    
    enum GameResult {
        case win
        case draw
        case lose
    }
    func updateRecord(gameResult: GameResult) {
        oppositePlayer = nil
        let vc = ViewControllerConnectFrom!
        let batch = db?.batch()
        let userRef = db?.collection("users").document(vc.email!)
        
        socket.emit("gameOver")
        switch gameResult {
        case .win:
            batch?.updateData(["win": vc.win! + 1 ], forDocument: userRef!)
            break
        case .lose:
            batch?.updateData(["lose": vc.lose! + 1 ], forDocument: userRef!)
            break
        case .draw:
            batch?.updateData(["draw": vc.draw! + 1 ], forDocument: userRef!)
            break
        }
        
        batch?.commit() { err in
            if let err = err {
                print("Error writing batch \(err)")
            }
        }
    }
}
