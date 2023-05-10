//
//  BackupPanelController.swift
//  SLC
//
//  Created at Sarah Lawrence College on 04/12/21.
//

import Cocoa

class BackupPanelController: NSViewController {
    @IBOutlet private var progress: NSProgressIndicator!
    @IBOutlet private var text1: NSTextField!
    @IBOutlet private var text2: NSTextField!
    @IBOutlet private var text3: NSTextField!
    @IBOutlet private var text4: NSTextField!

    private lazy var timeout: TimeInterval = {
        #if DEBUG
        50 // 5 seconds
        #else
        5 * 60 // 5 minutes
        #endif
    }()
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        text1.stringValue = Config.shared.dialogBackupText1
        text2.stringValue = Config.shared.dialogBackupText2
        text3.stringValue = Config.shared.dialogBackupText3
        text4.stringValue = Config.shared.dialogBackupText4
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()

        progress.startAnimation(self)
        
        // Timeout in case the backup script failed to complete.
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            NSApp.reply(toApplicationShouldTerminate: true)
        }
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
    }
}
