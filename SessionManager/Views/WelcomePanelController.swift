//
//  WelcomePanelController.swift
//  Sarah Lawrence College Manager
//
//  Created at Sarah Lawrence College on 04/12/21.
//

import Cocoa
class Curtain: NSWindow {
    override var acceptsFirstResponder: Bool {
        return false
    }
    func ignoresMouseEvents() -> Bool {
        return true
    }
}

class WelcomePanelController: NSWindowController {

    weak var appDelegate:AppDelegate!
    var curtain : Curtain?
    
    @IBOutlet weak var LoginButton: NSButton!
    @IBOutlet weak var AcceptButton: NSButton!
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var timerView: NSTextField!
    @IBOutlet weak var secView: NSTextField!
    @IBOutlet weak var timeoutLabel: NSTextField!

    @IBAction func openLoginPanel(_ sender: Any) {
        appDelegate.openLoginPanel()
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()

        appDelegate = NSApplication.shared.delegate as? AppDelegate
        if appDelegate == nil {
            print("Error: no app delegate")
        }
        self.window?.isMovable = true
        
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

    override func windowDidLoad() {

        curtain = Curtain.init(contentRect: NSScreen.main?.visibleFrame ?? NSRect.init(x: 0.0, y: 0.0, width: 800.0, height: 600.0), styleMask: [], backing: .buffered, defer: false)
        //curtain!.window?.makeKeyAndOrderFront(self)
        curtain!.level = .mainMenu

        super.windowDidLoad()
    }
}
