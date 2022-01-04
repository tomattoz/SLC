//
//  TestingPanelController.swift
//  Sarah Lawrence College Manager
//
//  Created at Sarah Lawrence College on 04/12/21.
//

import Cocoa
class TestingView: NSView {

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor.orange.setFill()
        dirtyRect.fill()
    }
}


class MultiplierMenuItem: NSMenuItem {

    var multiplierVal:Int = 1

}
class TestingPanelController: NSWindowController {

    weak var appDelegate:AppDelegate!

    @IBOutlet weak var doLogoutBtn: NSButton!
    @IBOutlet weak var extendButton: NSButton!
    @IBOutlet weak var doHardLogoutBtn: NSButton!
    
    @IBOutlet weak var idleTimeLabel: NSTextField!

    @IBOutlet weak var multiplierButton: NSButton!
    
    @IBAction func updateMultiplier(_ sender: MultiplierMenuItem!) {
        print("\(sender.title)")
        print("\(sender.multiplierVal)")
    }
    
    @IBAction func doSoftLogout(_ sender: NSButton) {
        sender.isEnabled = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {

            sender.isEnabled = true
        })

        (NSApplication.shared.delegate as! AppDelegate).doLogout()
    }
    @IBAction func doLogout(_ sender: NSButton) {
        sender.isEnabled = false

        (NSApplication.shared.delegate as! AppDelegate).doBackup()
    }

    override func awakeFromNib() {

        super.awakeFromNib()

        doHardLogoutBtn.isHidden = true
        
        appDelegate = NSApplication.shared.delegate as? AppDelegate
        if appDelegate == nil {
            print("Error: no app delegate")
        }

        startObserving() 
    }

    private var observerContext = 0

    func startObserving() {
        appDelegate.idleTimer.addObserver(self, forKeyPath: #keyPath(IdleTimer.secIdle), options: [.new, .old], context: &observerContext)
    }
    
    func stopObserving() {
        appDelegate.idleTimer.removeObserver(self, forKeyPath: #keyPath(IdleTimer.secIdle), context: &observerContext)
    }

    deinit {
        stopObserving()
    }
    
    func getTimeFormat(_ timeLeft:Double) -> (Int,Int,Int) {
        let hours = (Int(timeLeft) / (60 * 60)) % 60
        let minutes = (Int(timeLeft) / 60) % 60
        let seconds = Int(timeLeft) % 60
        return (seconds, minutes, hours)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &observerContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        let secIdle = (change![.newKey] as! NSNumber).doubleValue - 0.25
        let timeout = self.appDelegate.idleTimer.idleTimeout
        let timeLeft = timeout - secIdle

        DispatchQueue.main.asyncAfter(deadline: .now() - 0.1, execute: {

            let time = self.getTimeFormat(Double(timeLeft))

            let timeString = String(format: "%02d:%02d:%02d", time.2, time.1, time.0)
            //print(timeString)
            self.idleTimeLabel.stringValue = "\(timeString)"

        })

    }

    
    override func windowDidLoad() {

        super.windowDidLoad()

    }
}
