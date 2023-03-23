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
        window.canBecomeVisibleWithoutLogin = true
        window.hidesOnDeactivate = false
        window.delegate = self
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        window.contentView?.traverse(executing: { view in
            (view as? NSProgressIndicator)?.startAnimation(self)
        })
        closeAfterDelay()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        closeAfterDelay()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    private func closeAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Config.shared.preLoginAgentDelay) {
            self.window.close()
        }
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowDidBecomeKey(_ notification: Notification) {
        closeAfterDelay()
    }
}
