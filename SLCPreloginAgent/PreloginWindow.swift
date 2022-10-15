//
//  PreloginWindow.swift
//  SLCPreloginAgent
//
//  Created by Sebastián Benítez on 15/10/2022.
//

import Cocoa

class PreloginWindow: NSWindow {
    @IBOutlet private var progress: NSProgressIndicator!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        progress.startAnimation(self)
    }
}
