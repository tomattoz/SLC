//
//  WelcomePanelController.swift
//  Sarah Lawrence College Manager
//
//  Created at Sarah Lawrence College on 04/12/21.
//

import Cocoa

class WelcomePanelController: NSViewController {
    weak var appDelegate: AppDelegate!
    
    @IBOutlet weak var LoginButton: NSButton!
    @IBOutlet weak var AcceptButton: NSButton!
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var timerView: NSTextField!
    @IBOutlet weak var secView: NSTextField!
    @IBOutlet weak var timeoutLabel: NSTextField!

    @IBAction func openLoginPanel(_ sender: Any) {
        _ = appDelegate.openLoginPanel()
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()

        appDelegate = NSApplication.shared.delegate as? AppDelegate
        if appDelegate == nil {
            print("Error: no app delegate")
        }
        
        self.AcceptButton.title = "Accept"
        self.AcceptButton.target = self
        self.AcceptButton.action = #selector(WelcomePanelController.acceptWelcome(_:))
    }

    @IBAction func doLogout(_ sender: NSButton) {
        
        sender.isEnabled = false

        appDelegate.doLogout()

    }
    
    @IBAction func acceptWelcome(_ sender: NSButton) {

        sender.isEnabled = false

        self.appDelegate.acceptTermsLogin()

    }
}
