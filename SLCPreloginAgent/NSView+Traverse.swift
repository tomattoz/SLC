//
//  NSView+Traverse.swift
//
//  Created by Sebastián Benítez on 21/11/2019.
//  Copyright © 2019 DS9 Software. All rights reserved.
//

import Cocoa

public extension NSView {
    func traverse(unless condition: ((_ view: NSView) -> Bool)? = nil,
                  executing block: (_ view: NSView) -> Void) {
        if condition != nil && condition!(self) { return }

        for subview in subviews {
            block(subview)
            subview.traverse(unless: condition, executing: block)
        }
    }
}
