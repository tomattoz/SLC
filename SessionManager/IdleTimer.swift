//
//  IdleTimer.swift
//  Sarah Lawrence College Manager
//
//  Created at Sarah Lawrence College on 04/12/21.
//

import Cocoa

class IdleTimer: NSObject {
    var testingTimeMultiplier: Int = 1

    var idleTimeoutManager: Timer?

    let defaultTimeout: TimeInterval = 60
    lazy var idleTimeout = defaultTimeout
    @objc dynamic var secIdle = NSNumber(integerLiteral: 0)

    override init() {
        super.init()
        start()
    }
    
    func start() {
        secIdle = 0
        idleTimeoutManager = Timer.scheduledTimer(withTimeInterval: 1.0 / Double(testingTimeMultiplier > 10 ? testingTimeMultiplier : 10), repeats: true, block: { timer in
            // fire
            if self.secIdle.doubleValue < self.idleTimeout {
                let idle = CGEventSource.secondsSinceLastEventType(CGEventSourceStateID.hidSystemState, eventType: CGEventType(rawValue: ~0)!) * Double(self.testingTimeMultiplier)
                                
                self.secIdle = NSNumber.init(value: idle < self.idleTimeout ? CFTimeInterval(idle) : self.idleTimeout )
                //print(idle.description + " : " + self.secIdle.description + " : " + self.idleTimeout.description + " mult: " + self.testingTimeMultiplier.description)

            } else {
                self.secIdle = NSNumber(value: self.idleTimeout)
                (NSApplication.shared.delegate as! AppDelegate).openWelcomePanel()
                timer.invalidate()
            }
        })
    }
    
    func stop() {
        idleTimeoutManager?.invalidate()
    }
    
    func reset() {
        stop()
        idleTimeout = defaultTimeout
        start()
    }
}
