//
//  IdleTimer.swift
//  Sarah Lawrence College Manager
//
//  Created at Sarah Lawrence College on 04/12/21.
//

import Cocoa

class IdleTimer:NSObject {

    var testingTimeMultiplier:Int = 1

    var idleTimeoutManager:Timer?

    var idleTimeout = CFTimeInterval(1800)
    @objc dynamic var secIdle = NSNumber(integerLiteral: 0)

    override init() {
        super.init()
        startIdleTimer()
    }
    
    func startIdleTimer() {
        secIdle = 0
        idleTimeoutManager = Timer.scheduledTimer(withTimeInterval: 1.0 / Double(testingTimeMultiplier > 10 ? testingTimeMultiplier : 10), repeats: true, block: { timer in
            // fire
            if self.secIdle.doubleValue < self.idleTimeout {
                let idle = CGEventSource.secondsSinceLastEventType(CGEventSourceStateID.hidSystemState, eventType: CGEventType(rawValue: ~0)!) * Double(self.testingTimeMultiplier)
                                
                self.secIdle = NSNumber.init(value: idle < self.idleTimeout ? CFTimeInterval(idle) : self.idleTimeout )
                // print(idle.description + " : " + self.secIdle.description + " : " + self.idleTimeout.description + " mult: " + self.testingTimeMultiplier.description)

            } else {
                self.secIdle = NSNumber(value: self.idleTimeout)
                (NSApplication.shared.delegate as! AppDelegate).openWelcomePanel()
                timer.invalidate()
            }
        })
    }
}
