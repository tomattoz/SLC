//
//  CurtainContentController.swift
//  SLC
//
//  Created by Sebastián Benítez on 1/4/22.
//

import Cocoa

class CurtainContentController: NSViewController {
    @IBOutlet private var boxedView: NSView!
    
    private var subviewController: NSViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func setContentViewController(_ vc: NSViewController) {
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        
        subviewController = vc
        boxedView.addSubview(vc.view)
        
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
