//
//  BackupPanelController.swift
//  SLC
//
//  Created at Sarah Lawrence College on 04/12/21.
//

import Cocoa

class BackupPanelController: NSViewController {

    @IBOutlet private var progress: NSProgressIndicator!
    
    override func viewDidAppear() {
        super.viewDidAppear()

        progress.startAnimation(self)
    }
}
