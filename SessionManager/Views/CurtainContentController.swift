//
//  CurtainContentController.swift
//  SLC
//
//  Created by Sebastián Benítez on 1/4/22.
//

import Cocoa

class CurtainContentController: NSViewController {
    @IBOutlet private var boxedView: NSView!
    @IBOutlet private var imageView: NSImageView!

    private var subviewController: NSViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func setContentViewController(vc: NSViewController, bg: URL?) {
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        
        subviewController = vc
        boxedView.addSubview(vc.view)

        // Setup custom background image
        if let bg, let image = NSImage(contentsOf: bg) {
            self.imageView.wantsLayer = true;
            self.imageView.layer = CALayer()
            self.imageView.layer?.contentsGravity = .resizeAspectFill
            self.imageView.layer?.contents = image
            self.imageView.layer?.cornerRadius = 4
        }

        // Add constraints
        let views = ["subview": vc.view]
        boxedView.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-[subview]-|", options: [],
            metrics: nil, views: views))
        boxedView.addConstraints(NSLayoutConstraint.constraints(
            withVisualFormat: "V:|-[subview]-|", options: [],
            metrics: nil, views: views))
    }
}
