//
//  CurtainViewController.swift
//  Sarah Lawrence College Manager
//
//  Created at Sarah Lawrence College on 04/12/21.
//

import Cocoa
class CurtainView: NSWindow {
    override class func awakeFromNib() {
        
        super.awakeFromNib()
        
        super.standardWindowButton(.miniaturizeButton, for: .texturedBackground)?.isHidden = true
        super.standardWindowButton(.zoomButton, for: .texturedBackground)?.isHidden = true
    }
}
class CurtainViewController: NSWindowController, NSWindowDelegate {

    @IBOutlet var curtainView:CurtainView?
    
    override class func awakeFromNib() {
        super.awakeFromNib()
        NSWindow.standardWindowButton(.miniaturizeButton, for: .texturedBackground)?.isHidden = true
        
    }
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
}
