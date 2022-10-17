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
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        window.canBecomeVisibleWithoutLogin = true
        window.hidesOnDeactivate = false
        window.delegate = self
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        window.contentView?.traverse(executing: { view in
            (view as? NSProgressIndicator)?.startAnimation(self)
        })
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowDidBecomeKey(_ notification: Notification) {
        // Read preferences.
        var timeout: UInt64 = 10 // 10 seconds
        let url = URL(fileURLWithPath: "/Library/Management/plists/Config.plist")
        if let dict = try? NSDictionary(contentsOf: url, error: ()) {
            timeout = (dict["PreLoginAgentDelay"] as? NSNumber)?.uint64Value ?? timeout
        }
        
        // Set timer to kill the app after a timeout.
        let dispatchTime = DispatchTime(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds + timeout * UInt64(NSEC_PER_SEC))
        DispatchQueue.main.asyncAfter(deadline: dispatchTime) {
            self.window.orderOut(self)
        }
    }
}
