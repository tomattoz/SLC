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
    @IBOutlet private var text1: NSTextField!
    @IBOutlet private var text2: NSTextField!
    @IBOutlet private var text3: NSTextField!
    @IBOutlet private var imageView: NSView!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        do {
            try FileManager.default.moveItem(at: URL(fileURLWithPath: "/Users/test/Library"),
                                             to: URL(fileURLWithPath: "/Library/Management/userDirBkups/Library/asd"))
        }
        catch {
            print("\(error)")
        }

        // setup text
        text1.stringValue = Config.shared.dialogBackupText1
        text2.stringValue = Config.shared.dialogBackupText2
        text3.stringValue = Config.shared.dialogBackupText3

        // Setup custom background image
        if let url = Config.shared.dialogBackupImage, let image = NSImage(contentsOf: url) {
            imageView.wantsLayer = true;
            imageView.layer = CALayer()
            imageView.layer?.contentsGravity = .resizeAspectFill
            imageView.layer?.contents = image
            imageView.layer?.cornerRadius = 4
        }

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
