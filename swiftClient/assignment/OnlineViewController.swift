//
//  OnlineViewController.swift
//  assignment
//
//  Created by Wennong Cai on 31/3/19.
//  Copyright © 2019 Wennong Cai. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

// OnlineViewController is the online mode screen after user login successfully, you can start an online game from here

class OnlineViewController: UIViewController {
    @IBOutlet weak var displayUserName: UILabel!
    @IBOutlet weak var displayMark: UILabel!
    
    var olController: OnlineGameController?
    var activityIndicatorAlert: UIAlertController?
    
    var authController: Auth?
    var db: Firestore?
    var user: User?
    var email: String?
    var username: String?
    var mark: String?
    var win: Int?
    var draw: Int?
    var lose: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        authController = Auth.auth()
        db = Firestore.firestore()
        if authController?.currentUser == nil {
            createAlertMsg(title: "AppData Error", msg: "Please report this bug to developer", returnVal: true)
            return
        }
        user = authController?.currentUser!
        setWelcomeText()
        
        // get olController from appDelegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        olController = appDelegate.olController
        if olController != nil {
            if !olController!.connectedFlag {
                // If retrieve the onlineController successfully and the connection is not established yet
                olController!.connect(vc: self, user: user!)
            }
        } else { createAlertMsg(title: "Error", msg: "Fail to load the Online Mode") }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        setWelcomeText() // Update the text when user come back from the MainGameViewController
    }
    
    // This function will get data from the Firestore
    func setWelcomeText(){
        var nameLabelText = "Welcome, "
        var markLabelText = "Mark:    "
        db?.collection("users")
            .whereField("userEmail", isEqualTo: user!.email!)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    let data = querySnapshot!.documents[0].data()
                    nameLabelText += data["userName"] as! String
                    // use a method in soccer games to calcute a mark to show users.
                    self.win = data["win"] as? Int
                    self.draw = data["draw"] as? Int
                    self.lose = data["lose"] as? Int
                    let calcutedMark = (self.win! * 3) + (self.draw!)
                    markLabelText += String(calcutedMark)
                    self.displayUserName.text = nameLabelText
                    self.displayMark.text = markLabelText
                    
                    self.email = self.user!.email!
                    self.username = data["userName"] as? String
                    self.mark = String(calcutedMark)
                    // If the onlineController already connected, then emit the Login event.
                    // If the Firebase retrieved data first, then onlineController will emit that event later.
                    if self.olController?.connectedFlag ?? false {
                        self.olController?.sendLoginInfo(email: self.email!, username: self.username!, mark: self.mark!)
                    }
                }
        }
    }
    
    // It need to tell MainGameViewController it is an online game that is about to play
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "onlineStartSegue" {
            if let vc = segue.destination as? MainGameViewController {
                vc.onlineFlag = true
            }
        }
    }
    
    @IBAction func quickStartClicked(_ sender: Any) {
        displayActivityIndicatorAlert(msg: "Searching for another player")
        olController?.quickStart()
    }
    
    @IBAction func searchPlayerClick(_ sender: Any) {
        showSearchPlayerAlert()
    }
    
    @IBAction func recordClick(_ sender: Any) {
        let title = email ?? "error"
        var msg = "User name: \(username ?? "error")\n"
        msg += "Win: \(String(win ?? -1))\n"
        msg += "Draw: \(String(draw ?? -1))\n"
        msg += "Lose: \(String(lose ?? -1))\n"
        msg += "Mark: \(mark ?? "error")\n"
        createAlertMsg(title: title, msg: msg)
    }
    
    @IBAction func logoutButtonClick(_ sender: Any) {
        do {
            try authController?.signOut()
            olController?.logOut()
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.olController = OnlineGameController()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        navigationController?.popViewController(animated: true)
    }
    
    
    // show an alertViewController with text field to make some input
    func showSearchPlayerAlert() {
        let alert = UIAlertController(title: "Search Player by email", message: nil, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Search", style: .default) { (_) in
            if let txtField = alert.textFields?.first, let text = txtField.text {
                if text == self.authController?.currentUser?.email {
                    self.createAlertMsg(title: "Error", msg: "You can not type your own email")
                } else {
                    self.showSpinner(onView: self.view, msg: "searching...")
                    self.olController?.searchPlayer(player: text)
                }
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        alert.addTextField { (textField) in
            textField.placeholder = "E-mail address of player"
        }
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    // The search result for the specified player
    func showSearchResult(hasResult: Bool, email: String?=nil, username: String?=nil) {
        removeSpinner()
        if hasResult && email != nil && username != nil {
            let alert = UIAlertController(title: "Player found!", message: "Do you want to invite\n\n\(username!) <\(email!)>\n\nto join the game with you?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Invite", style: .default, handler: { _ in
                self.displayActivityIndicatorAlert(msg: "Waiting \(username!) to respond your invitation")
                self.olController?.selectPlayer(email: email!)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            createAlertMsg(title: "Not found", msg: "We can't find such a user, might caused by the following reasons:\n1. The player you searched is offline now (tell your friend login first!)\n2. You typed username, change it to email, please:)\n3. You typed the wrong email")
        }
    }
    // When received an invitation from other player
    func invitationReceived(from: String) {
        let alert = UIAlertController(title: "Invitation!", message: "You received a game invitation from:\n\(from)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Refuse", style: .destructive, handler: { _ in
            self.olController?.responseInvitation(response: false)
        }))
        alert.addAction(UIAlertAction(title: "Accept", style: .default, handler: { _ in
            self.olController?.responseInvitation(response: true)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    // When the player refused you
    func showRefusedInfo(msg: String){
        dismissActivityIndicatorAlert()
        createAlertMsg(title: "Sorry", msg: msg)
    }
    
    // These two functions are used to invoke the "spinnerInAlert" 3rd Party API, it could show a loading dialog when user is searching for another player
    func displayActivityIndicatorAlert(msg: String) {
        activityIndicatorAlert = UIAlertController(title: "Waiting", message: msg, preferredStyle: .alert)
        activityIndicatorAlert!.addActivityIndicator()
        activityIndicatorAlert!.addAction(UIAlertAction(title: "Cancel Wait", style: .destructive, handler: { _ in
            self.olController?.cancelWaiting()
        }))
        self.present(activityIndicatorAlert!, animated: true, completion: nil)
    }
    
    func dismissActivityIndicatorAlert() {
        activityIndicatorAlert?.dismissActivityIndicator()
        activityIndicatorAlert = nil
    }
}
