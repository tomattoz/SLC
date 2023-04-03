//
//  BackupPanelController.swift
//  SLC
//
//  Created at Sarah Lawrence College on 04/12/21.
//

import Cocoa

class BackupPanelController: NSViewController {
    @IBOutlet private var progress: NSProgressIndicator!

    private lazy var timeout: TimeInterval = {
        #if DEBUG
        50 // 5 seconds
        #else
        5 * 60 // 5 minutes
        #endif
    }()
    
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
