//
//  AppDelegate.swift
//  SLCPreloginAgent
//
//  Created by Sebastián Benítez on 14/10/2022.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet private var window: NSWindow!
    
    private var timer: Timer!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        window.canBecomeVisibleWithoutLogin = true
        window.hidesOnDeactivate = false
        window.orderFrontRegardless()
        
        // Read preferences.
        var timeout: TimeInterval = 10 // 10 seconds
        let url = URL(fileURLWithPath: "/Library/Management/plists/Config.plist")
        if let dict = try? NSDictionary(contentsOf: url, error: ()) {
            timeout = (dict["PreLoginAgentDelay"] as? NSNumber)?.doubleValue ?? timeout
        }
        
        // Set timer to kill the app after a timeout.
        timer = Timer(fire: Date().addingTimeInterval(timeout),
                      interval: 0,
                      repeats: false,
                      block: { timer in
            NSApp.terminate(self)
        })
        RunLoop.main.add(timer, forMode: .default)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

