//
//  CurtainWindowController.swift
//  Sarah Lawrence College Manager
//
//  Created at Sarah Lawrence College on 04/12/21.
//

import Cocoa

class CurtainWindowController: NSWindowController, NSWindowDelegate {
    @IBOutlet var curtainWindow: NSWindow!
    
    private var curtainContentController: CurtainContentController!
    
    override func awakeFromNib() {
        createContentViewController()
        
        super.awakeFromNib()
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()

        window?.level = .screenSaver
        
        window?.contentViewController = curtainContentController
        
        if let screenSize = NSScreen.main?.frame.size {
            window?.setFrame(NSMakeRect(0, 0, screenSize.width, screenSize.height),
                             display: true)
            curtainContentController.view.setFrameSize(screenSize)
        }
    }
    
    func setBoxedContentViewController(_ vc: NSViewController) {
        createContentViewController()
        
        curtainContentController.setContentViewController(vc)
    }
    
    private func createContentViewController() {
        if curtainContentController == nil {
            curtainContentController = CurtainContentController(nibName: "CurtainContentController",
                                                                bundle: Bundle.main)
            if !curtainContentController.isViewLoaded {
                // Force view to load.
                curtainContentController.view.translatesAutoresizingMaskIntoConstraints = false
            }
        }
    }
}
