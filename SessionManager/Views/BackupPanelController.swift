//
//  BackupPanelController.swift
//  SLC
//
//  Created at Sarah Lawrence College on 04/12/21.
//

import Cocoa

class BackupPanelController: NSViewController {
    @IBOutlet private var progress: NSProgressIndicator!
    
    private let timeout: TimeInterval = 5 * 60 // 5 minutes
    private var timer: Timer?
    
    override func viewDidAppear() {
        super.viewDidAppear()

        progress.startAnimation(self)
        
        // Timeout in case the backup script failed to complete.
        timer = Timer(fire: Date(timeIntervalSinceNow: timeout), interval: 0.1, repeats: false, block: { timer in
            NSApp.reply(toApplicationShouldTerminate: true)
            timer.invalidate()
        })
        RunLoop.current.add(timer!, forMode: .default)
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        timer?.invalidate()
    }
}
