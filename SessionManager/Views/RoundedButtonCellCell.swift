//
//  RoundedButtonCellCell.swift
//  Sarah Lawrence College Manager
//
//  Created at Sarah Lawrence College on 04/12/21.
//

import Cocoa
class RoundedPopUpButtonCellCell: NSPopUpButtonCell {
    
    var bgPassiveColor: NSColor = NSColor.init(red: 0.119, green: 0.251, blue: 0.487, alpha: 1.0)
    var bgActiveColor: NSColor = NSColor.init(red: 0.011, green: 0.117, blue: 0.267, alpha: 1.0)
    @IBInspectable var borderColor: NSColor = .gray
    @IBInspectable var bgColor: NSColor = .gray
    @IBInspectable var cornerRadius: CGFloat = 30
    @IBInspectable var strokeWidth: CGFloat = 0

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        self.bgColor = self.bgPassiveColor
        cornerRadius = (self.controlView?.frame.size.height)! * 0.5
    }
    override func highlight(_ flag: Bool, withFrame cellFrame: NSRect, in controlView: NSView) {
        super.highlight(flag, withFrame: cellFrame, in: controlView)
        if flag {
            self.bgColor = bgActiveColor
        } else {
            self.bgColor = bgPassiveColor
        }
    }
    override func drawTitle(_ title: NSAttributedString, withFrame frame: NSRect, in controlView: NSView) -> NSRect {
            let attrTitle = NSMutableAttributedString.init(attributedString: title)
            let range = NSMakeRange(0, attrTitle.length)
        attrTitle.addAttributes([NSAttributedString.Key.foregroundColor : NSColor.white], range: range)
            return super.drawTitle(attrTitle, withFrame: frame, in: controlView)
        }
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        let bounds = NSBezierPath(roundedRect: cellFrame, xRadius: cornerRadius, yRadius: cornerRadius)
        bounds.addClip()
        if borderColor != .clear {
            bounds.lineWidth = strokeWidth
            borderColor.setStroke()
            bgColor.setFill()
            bounds.fill()
            bounds.stroke()
        }
        super.draw(withFrame: cellFrame, in: controlView)
    }
}

class RoundedButtonCellCell: NSButtonCell {

    var bgPassiveColor: NSColor = NSColor.init(red: 0.119, green: 0.251, blue: 0.487, alpha: 1.0)
    var bgActiveColor: NSColor = NSColor.init(red: 0.011, green: 0.117, blue: 0.267, alpha: 1.0)
    @IBInspectable var borderColor: NSColor = .gray
    @IBInspectable var bgColor: NSColor = .gray
    @IBInspectable var cornerRadius: CGFloat = 30
    @IBInspectable var strokeWidth: CGFloat = 0

    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        self.bgColor = self.bgPassiveColor
        cornerRadius = (self.controlView?.frame.size.height)! * 0.5

    }
    override func highlight(_ flag: Bool, withFrame cellFrame: NSRect, in controlView: NSView) {
        super.highlight(flag, withFrame: cellFrame, in: controlView)
        if flag {
            self.bgColor = bgActiveColor
        } else {
            self.bgColor = bgPassiveColor
        }

    }
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        let frame = cellFrame.insetBy(dx: 2.0, dy: 2.0)
        let bounds = NSBezierPath(roundedRect: frame, xRadius: cornerRadius, yRadius: cornerRadius)
        bounds.addClip()
        if borderColor != .clear {
            bounds.lineWidth = strokeWidth
            borderColor.setStroke()
            bgColor.setFill()
            bounds.fill()
            bounds.stroke()
        }
        super.draw(withFrame: cellFrame, in: controlView)
    }
}
