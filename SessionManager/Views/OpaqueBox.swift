//
//  OpaqueBox.swift
//  SLC
//
//  Created by Sebastián Benítez on 1/4/22.
//

import Cocoa

class OpaqueBox: NSBox {
    
    override var allowsVibrancy: Bool {
        return false
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
