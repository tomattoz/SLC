//
//  AppDelegate.swift
//  Sarah Lawrence College manager
//
//  Created at Sarah Lawrence College on 04/12/21.
//

import Cocoa
import LaunchAtLogin

class ExtendMenuItem: NSMenuItem {
    var secVal:Int = 120
}

struct Processes {

    static func printPIDSInfo(pids:[Int32]) {
        for pid in pids {
            if pid == 0 {
                continue
            }

            let cpath = UnsafeMutablePointer<CChar>.allocate(capacity: Int(MAXPATHLEN))
            _ = UnsafeMutablePointer<CChar>.allocate(capacity: Int(MAXPATHLEN))
            proc_pidpath(pid, cpath, UInt32(MAXPATHLEN))
            
            guard strlen(cpath) > 0 else {
                continue
            }

            let path = String(cString: cpath)
            _ = URL(fileURLWithPath: path)

            
            //proc_pidinfo(pid, Int32, UInt64, UnsafeMutableRawPointer!, Int32)
            let pidInfo = UnsafeMutablePointer<proc_bsdinfo>.allocate(capacity: 1)
            let InfoSize = Int32(MemoryLayout<proc_bsdinfo>.stride)

            _ = proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, pidInfo, InfoSize)
            if  InfoSize > 0 {
                _ = Date(timeIntervalSince1970: TimeInterval(pidInfo.pointee.pbi_start_tvsec))
                let nm = pidInfo.pointee.pbi_uid
                print ("\(getpid() == pid ? "******" : "")\(nm) : \(pid) \(path)")
            }

        }
    }
    
    static func listAllPids() -> [Int32] {
        let uid = getuid()
        print("uid: \(String(describing: getuid))")
        let pnum = proc_listpids(UInt32(PROC_UID_ONLY), uid, nil, 0)
        //let pnum = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        var pids = [pid_t](repeating: 0, count: Int(pnum))
        
        _ = pids.withUnsafeMutableBufferPointer { ptr in
            proc_listpids(UInt32(PROC_UID_ONLY), uid, ptr.baseAddress, pnum * Int32(MemoryLayout<pid_t>.size))
            //proc_listpids(UInt32(PROC_ALL_PIDS), 0, ptr.baseAddress, pnum * Int32(MemoryLayout<pid_t>.size))
        }

        return pids
    }
}

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow!

    var isAdmin = false
    
    #if DEBUG
    let disableScriptInstall: Bool = CommandLine.arguments.contains("disableScriptInstall")
    #else
    let disableScriptInstall: Bool = false
    #endif

    // Time out interval in sec
    var welcomeTimeout:CFTimeInterval = 120
    var welcomeTimer:Timer?
    
    var idleTimer = IdleTimer()

    // DISABLE TESTING WINDOW
    // orange window box
    let testingSetup = false
    
    let showCurtain = false

    var statusBarItem: NSStatusItem!
    
    var aboutController:AboutPanelController?
    var loginController:LoginPanelController?
    var welcomController:WelcomePanelController?
    var testingController:TestingPanelController?
    var backupController:BackupPanelController?

    var curtainView:CurtainViewController?

    let extendText = """
You have successfully login.
This option should only be used for film students and faculty where an extend period of time is needed after "Extend" is chosen and time is done.
If you don't use the computer the computer will log you off.
Click "extend" to Accept the terms or click "Log Off"
"""
 
    let welcomeText = """
Welcome to Sarah Lawrence College.
This computer will log you off if not in use and we do not save your work. You have 120 seconds to accept terms.
"""

    let timeoutText = """
The Computer has detected that is not in use. Click "Log Off" or click "Okay" to confirm it is in use.
"""
    func stopAllprocesses() {
        let pid = getpid()
        print("getpid(): \(pid))\n\n\n")
        print("Processes.listAllPids: \(String(describing: Processes.listAllPids()))\n\n\n")

        
    }
    
    func doBackup() {

        do {
            try "\(NSUserName())\n".write(toFile: "/tmp/trigger", atomically: true, encoding: .utf8)
        }
        catch let error {
            errorPopup(message: "Can't logout for \(NSUserName()): \(error.localizedDescription)")
            return
        }
    }
    
    func updateIdleTime() {

    }

    //Popup with error
    private func errorPopup(message:String) {
        
        // to hide any errors in UI uncomment this
        // return
        let process = Process()
        let string = message.replacingOccurrences(of: "\"", with: "\\\"")
        let args = ["-e", "display alert \"Sarah Lawrence College Manager\" message \"\(string)\" "]; //buttons {\"OK\"} default button \"OK\""]
        process.launchPath = "/usr/bin/osascript"
        process.arguments = args
        process.launch()
        process.waitUntilExit()
    }
    
    
    func installPriveledgedTool() {
        
        let process = Process()

        let useInstallerApp = false
        //let toolInstallerLocation = "/tmp"
        let toolIFolder = "/Library/Management/.tool"
        let usrDirIFolder = "/Library/Management/userDirBkups"
        let usrTemplateIFolder = "/Library/Management/userTemplate"
        let backupToolName = "backupScript-1.1.2.sh"
        let backupToolLocation = "\(toolIFolder)/\(backupToolName)"
        let toolPlistPath = "/Library/LaunchDaemons/edu.slc.gm.SarahLawrenceCollegeService.plist"
        let tempToolPlistPath = "/tmp/edu.slc.gm.SarahLawrenceCollegeService.plist"

        
        let fm = FileManager.default

        if fm.fileExists(atPath: backupToolLocation) && fm.fileExists(atPath: toolPlistPath) {
            print("Sarah Lawrence College Manager installed properly")
            return
        }
        

        let installerPath = "/tmp/installer.sh"
        guard let backupToolPath = Bundle.main.path(forResource: "backupScript.sh", ofType: "") else {
            
            errorPopup(message: "\"backupScript.sh\" is missing")
            return
        }


        let daemonScript = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>edu.slc.gm.SarahLawrenceCollegeService</string>
    <key>KeepAlive</key>
    <false/>
    <key>WatchPaths</key>
    <array>
       <string>/tmp/trigger</string>
    </array>
    <key>ProgramArguments</key>
    <array>
        <string>\(backupToolLocation)</string>
    </array>
</dict>
</plist>
"""
        let installerScript = """
#!/bin/bash

launchctl unload \(toolPlistPath)
launchctl unload edu.psu.PennSessionManagerService.plist
rm  /Library/LaunchDaemons/edu.psu.PennSessionManagerService.plist

[ -d \(usrTemplateIFolder) ] || install -d \(usrTemplateIFolder)
chmod a=rwx \(usrTemplateIFolder)
[ -d \(usrDirIFolder) ] || install -d \(usrDirIFolder)
chmod a=rwx \(usrDirIFolder)
[ -d \(toolIFolder) ] || install -d \(toolIFolder)
chmod a=rwx \(toolIFolder)
cp -f "\(backupToolPath)" \(backupToolLocation)
chown -R root:wheel \(backupToolLocation)
chmod ug=rwx,o= \(backupToolLocation)

mv -f "\(tempToolPlistPath)" \(toolPlistPath)
chown -R root:wheel \(toolPlistPath)

launchctl load \(toolPlistPath)

rm /tmp/installer.sh
"""

        do {
                try installerScript.write(toFile: installerPath, atomically: true, encoding: .utf8)
            }
            catch let error {
                errorPopup(message: "Can't run installer: \(error.localizedDescription)")
                return
            }
        do {
                try daemonScript.write(toFile: tempToolPlistPath, atomically: true, encoding: .utf8)
            }
            catch let error {
                errorPopup(message: "Can't write intermediate launch daemon: \(error.localizedDescription)")
                return
            }

        var attributes = [FileAttributeKey : Any]()
        attributes[.posixPermissions] = 0o777
        do {
            try fm.setAttributes(attributes, ofItemAtPath: installerPath)
        }catch let error {
            errorPopup(message: "Can't install. Permissions error: \(error.localizedDescription)")
            print("Permissions error: ", error)
        }

        if useInstallerApp {
            guard let installerAppURL = Bundle.main.url(forResource: "Sarah Lawrence College Installer", withExtension: "app") else {
                
                errorPopup(message: "\"Sarah Lawrence College Installer\" is missing")
                return
            }

            do {
                try NSWorkspace.shared.launchApplication(at: installerAppURL, options: [], configuration: [:])

            } catch let error {
                errorPopup(message: "error running Sarah Lawrence College Installer: \(error.localizedDescription)")
                print("error running Sarah Lawrence College Installer: \(error.localizedDescription)")
            }
        } else {
            process.launchPath = "/usr/bin/osascript"
            process.arguments = ["-e", "do shell script \"/tmp/installer.sh\" with administrator privileges"]
            process.launch()
            process.waitUntilExit()
            let status = process.terminationStatus
            if status != 0 {
                errorPopup(message: "error running \(installerPath) with status: \(status)")
                print("error running \(installerPath) with status: \(status)")
            }
        }


    }
    
    func moveWelcomeWindowDown() {
        if self.welcomController == nil {
            return
        }
        DispatchQueue.main.async {
            self.welcomController?.window?.center()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                var frameOrigin = self.welcomController?.window?.frame.origin
                frameOrigin?.y -= 260.0
                self.welcomController?.window?.setFrameOrigin(frameOrigin!)
            })
        }
    }
    func cancelLogin(_ warning:Bool) {
        
        if warning {
            moveWelcomeWindowDown()
        }
        
        if loginController != nil {
            loginController?.window?.close()
            loginController = nil
        }

    }
    @IBAction func presentExtendPopUpMenu(_ sender: NSButton?) {
        
        let menu = NSMenu.init()

        let fontArttribute = sender?.attributedTitle.fontAttributes(in: NSRange.init(location: 0, length: 1))
        for rec in [1, 2, 4, 6] {
            let string = ("\(rec) hour\(rec > 1 ? "s" : "")")
            let itm = ExtendMenuItem.init(title: string, action: #selector(AppDelegate.selectExtendTime(_:)), keyEquivalent: "")
            itm.secVal = rec * 60 * 60
            let attributes = [NSAttributedString.Key.font: fontArttribute![NSAttributedString.Key.font]]
            itm.attributedTitle = NSAttributedString.init(string: itm.title, attributes: attributes as [NSAttributedString.Key : Any])
            menu.addItem(itm)
        }
        
        //menu.addItem(rootItem)
        
        let p = NSPoint(x: sender!.frame.origin.x, y: sender!.frame.origin.y - (sender!.frame.height / 2))
        menu.popUp(positioning: nil, at: p, in: sender?.superview)
    }
    
    @IBAction func selectExtendTime(_ sender: ExtendMenuItem!) {

        idleTimer.idleTimeout = CFTimeInterval(sender.secVal)
        
        acceptTermsLogin()
    }
    
    @IBAction func presentmultiplierPopUpMenu(_ sender: NSButton?) {
        
        let menu = NSMenu.init()

        let fontArttribute = sender?.attributedTitle.fontAttributes(in: NSRange.init(location: 0, length: 1))
        for rec in [1, 5, 10, 50, 100, 1000, 10000] {
            let string = ("Multiplier: \(rec)x")
            let itm = MultiplierMenuItem.init(title: string, action: #selector(AppDelegate.setMultiplierTime(_:)), keyEquivalent: "")
            itm.multiplierVal = rec
            let attributes = [NSAttributedString.Key.font: fontArttribute![NSAttributedString.Key.font]]
            itm.attributedTitle = NSAttributedString.init(string: itm.title, attributes: attributes as [NSAttributedString.Key : Any])
            menu.addItem(itm)
        }
        
        let p = NSPoint(x: sender!.frame.origin.x, y: sender!.frame.origin.y - (sender!.frame.height / 2))
        menu.popUp(positioning: nil, at: p, in: sender?.superview)
        sender?.title = "Multiplier: 1x"
    }

    @IBAction func setMultiplierTime(_ sender: MultiplierMenuItem!) {

        let extendTimeout = idleTimer.idleTimeout
        
        resetIdleTimer()
        idleTimer.idleTimeout = extendTimeout
        
        idleTimer.testingTimeMultiplier = sender.multiplierVal


        DispatchQueue.main.async{
            let string = ("Multiplier: \(sender.multiplierVal)x")
            self.testingController?.multiplierButton.title = string
        }
    }

    @IBAction func pressOkayButton(_ sender: MultiplierMenuItem!) {

        self.welcomController?.window?.close()
        
        if welcomeTimer != nil {
            welcomeTimer?.invalidate()
            welcomeTimer = nil
            welcomeTimeout = 120
        }
        resetIdleTimer()
    }

    func resetIdleTimer() {
        
        idleTimer.idleTimeoutManager?.invalidate()
        if testingController != nil {
            testingController?.stopObserving()
        }

        idleTimer = IdleTimer()
        idleTimer.idleTimeout = 1800

        if testingController != nil {
            testingController?.multiplierButton.title = "Multiplier: 1x"
        }
        idleTimer.startIdleTimer()
        
        if testingController != nil {
            testingController?.startObserving()
        }
    }
    
    func completeLogin() {
        
        if welcomController == nil {
            welcomController = WelcomePanelController.init(windowNibName:"WelcomePanel")
            welcomController!.window?.makeKeyAndOrderFront(self)
            welcomController!.window?.level = .mainMenu + 1
            welcomController!.window?.center()

        }

        self.presentExtendPanel()
    }
    
    func acceptTermsLogin() {

        self.removeWelcomeTimeout()

        if self.welcomController != nil {
                self.welcomController?.window?.close()
                self.welcomController = nil
            }
    }
    
    let backupTimer = 7.0
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {

        if isAdmin {
            return .terminateNow
        }
        print("applicationShouldTerminate")
        DispatchQueue.global().asyncAfter(deadline: .now() + backupTimer) {
            sender.reply(toApplicationShouldTerminate: true)
        }
        if isSystemLogout {
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) { [self] in
                let pids = Processes.listAllPids()
                Processes.printPIDSInfo(pids: pids)
                for pid in pids {
                    if pid == 0 {
                        continue
                    } else if pid == getpid(){
                        continue
                    }
                    kill(pid, 0)
                }
                
                //Start backup
                self.doBackup()
            }
        }

        DispatchQueue.main.async { [self] in
            
            self.acceptTermsLogin()
            
            if self.backupController == nil {
                self.backupController = BackupPanelController.init(windowNibName:"BackupPanel")
            }
            self.backupController!.window?.makeKeyAndOrderFront(self)
            self.backupController!.window?.level = .mainMenu + 1
            self.backupController!.window?.center()
            self.backupController?.progress.startAnimation(self)

            //printPIDSInfo(pids: pids)
        }
        
        return.terminateLater
    }
    var isSystemLogout = true
    func doLogout() {
        //Start backup
        DispatchQueue.global().sync {
            self.doBackup()
        }

        isSystemLogout = false
        if welcomController != nil && welcomController?.window != nil {
            welcomController?.window?.close()
        }
        //acceptTermsLogin()
        
        self.removeWelcomeTimeout()
        print("logging out ...")
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0, execute: {
            self.doStandardLogout() // fix
        })

        //stopAllprocesses()
        
        //self.doHardLogout()

    }
    
    func setupLoginPanel() {
        
        loginController!.window?.makeKeyAndOrderFront(self)
        loginController!.window?.level = .mainMenu + 1
        if welcomController != nil {
            let welcomeFrame = (welcomController!.window?.frame)!
            loginController!.window?.setFrameOrigin(NSPoint.init(x: welcomeFrame.origin.x + (welcomeFrame.size.width * 1.0 + 20.0), y: welcomeFrame.origin.y + welcomeFrame.height - (loginController!.window?.frame.height)!))
        } else {
            loginController!.window?.center()
        }

        loginController?.setup()

    }
    func openLoginPanel() {
        
        if loginController == nil {
            loginController = LoginPanelController.init(windowNibName:"LoginPanel")
            
            loginController?.awakeFromNib()
        }

        DispatchQueue.main.async {
            self.setupLoginPanel()
        }
    }

    func openWelcomePanel() {
        
        if welcomController == nil {
            welcomController = WelcomePanelController.init(windowNibName:"WelcomePanel")
        }
        
        if welcomeTimer != nil {
            welcomeTimer?.invalidate()
            welcomeTimer = nil
            welcomeTimeout = 120
        }
        
        welcomController?.awakeFromNib()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
            if self.welcomController == nil {
                return
            }
            self.welcomController?.textView.string = self.timeoutText
            self.welcomController?.timerView.isHidden = false
            self.welcomController?.secView.isHidden = false
            self.welcomController?.LoginButton.isHidden = false
            
            self.welcomController?.AcceptButton.title = "Okay"
            self.welcomController?.AcceptButton.target = self
            self.welcomController?.AcceptButton.action = #selector(AppDelegate.pressOkayButton(_:))

            self.welcomController!.window?.makeKeyAndOrderFront(self)
            self.welcomController!.window?.level = .mainMenu + 1
            self.welcomController!.window?.center()

            self.resetWelcomeTimeout()
        })
    }

    func resetWelcomeTimeout() {
        if welcomeTimer != nil {
            welcomeTimeout = 120
        } else {
            let multiplier = 1.0 //0.075 fix
            welcomeTimer = Timer.scheduledTimer(withTimeInterval: multiplier, repeats: true, block: { timer in
                self.welcomeTimeoutUpdate() // fire
            })
        }
    }
    func removeWelcomeTimeout() {
       
        if welcomeTimer != nil {

            welcomeTimer?.invalidate()
            welcomeTimer = nil
            welcomeTimeout = 120
        }

        if self.loginController != nil {
            self.loginController?.window?.close()
            self.loginController = nil
        }

        welcomController?.LoginButton.isHidden = true
        
    }
    
    func presentExtendPanel() {

        welcomController?.textView.string = extendText
        welcomController?.AcceptButton.title = "Extend"
        welcomController?.AcceptButton.target = self
        welcomController?.AcceptButton.action = #selector(AppDelegate.presentExtendPopUpMenu(_:))
        welcomController!.window?.makeKeyAndOrderFront(self)
        welcomController!.window?.level = .mainMenu + 1

        resetWelcomeTimeout()
    }

    func welcomeTimeoutUpdate() {
        let timeout = welcomeTimeout
        if welcomeTimeout < 0 {
            doLogout()
            return
        }
        DispatchQueue.main.async {
            self.welcomController?.timeoutLabel.stringValue = "\(Int(timeout+0.1))"
        }
        welcomeTimeout -= 1.0
    }
    
    @IBAction func presendAbout(_ sender: Any?) {
        //NSApp.setActivationPolicy(.regular)
        
        //moveWelcomeWindowDown()
        if aboutController != nil {
            if aboutController?.window == nil {
                aboutController = nil
            }
        }
        if aboutController == nil {
            aboutController = AboutPanelController.init(windowNibName:"AboutPanel")

        }
        aboutController!.window?.makeKeyAndOrderFront(self)
        aboutController!.window?.level = .mainMenu + 2
        aboutController!.window?.center()
        var frameOrigin = aboutController!.window?.frame.origin
        frameOrigin?.y += 180.0
        aboutController!.window?.setFrameOrigin(frameOrigin!)

//        NSApp.activate(ignoringOtherApps: true)
//        NSApp.orderFrontStandardAboutPanel(options: [:])
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        if !disableScriptInstall {
            installPriveledgedTool()
        }
        
        LaunchAtLogin.isEnabled = true
        
        let username = NSUserName()
        let path = Bundle.main.path(forResource: "Admins", ofType: "plist")
        if path == nil {
            let process = Process()
            process.launchPath = "/usr/bin/osascript"
            process.arguments = ["-e", "display dialog \"Cant find Admins plist\"  giving up after 3"]
            process.launch()
            NSApp.terminate(self)

        } else {
            let plistDictionary = NSDictionary(contentsOfFile: path!) as? Dictionary<String, String>
            if plistDictionary == nil {
                
                let process = Process()
                process.launchPath = "/usr/bin/osascript"
                process.arguments = ["-e", "display dialog \"Error reading Admins plist\"  giving up after 3"]
                process.launch()
                NSApp.terminate(self)
            } else {
                for record in  plistDictionary!.keys {
                    if username.localizedCaseInsensitiveContains(record) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            let process = Process()
                            process.launchPath = "/usr/bin/osascript"
                            process.arguments = ["-e", "display dialog \"User '\(username)' is in Admins plist\"  giving up after 3"]
                            process.launch()
                            self.isAdmin = true
                            NSApp.terminate(self)
                        }
                        return
                    }
                }
            }
        }

        
        let statusBar = NSStatusBar.system
        statusBarItem = statusBar.statusItem(
            withLength: NSStatusItem.squareLength)
        statusBarItem.button?.title = "PSU"
        let img = NSImage.init(named: "MenuBarIcon")
        if img != nil {
            statusBarItem.button?.image = img
        }
        let statusBarMenu = NSMenu(title: "App")
        statusBarItem.menu = statusBarMenu

        statusBarMenu.addItem(
            withTitle: "About",
            action: #selector(AppDelegate.presendAbout(_:)),
            keyEquivalent: "")


        welcomController = WelcomePanelController.init(windowNibName:"WelcomePanel")
        welcomController!.window?.makeKeyAndOrderFront(self)
        welcomController!.window?.level = .mainMenu + 1
        welcomController!.window?.center()
        //NSApp.runModal(for: welcomController!.window!)
        
        if testingSetup {
            testingController = TestingPanelController.init(windowNibName:"TestingPanel")
            testingController!.window?.makeKeyAndOrderFront(self)
            testingController!.window?.level = .mainMenu + 1
            testingController!.window?.setFrameOrigin(NSPoint.init(x: 90.0, y: 90.0))
            testingController!.extendButton.target = self
            testingController!.extendButton.action = #selector(AppDelegate.presentExtendPopUpMenu(_:))
            testingController!.multiplierButton.target = self
            testingController!.multiplierButton.action = #selector(AppDelegate.presentmultiplierPopUpMenu(_:))

        }
        
        resetWelcomeTimeout()

        if showCurtain {
            curtainView = CurtainViewController.init(windowNibName:"Curtain")
            curtainView!.window?.makeKeyAndOrderFront(self)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {

    }
    
    func doStandardLogout() {
        var targetDesc: AEAddressDesc = AEAddressDesc.init()
        var psn = ProcessSerialNumber(highLongOfPSN: UInt32(0), lowLongOfPSN: UInt32(kSystemProcess))
        var eventReply: AppleEvent = AppleEvent(descriptorType: UInt32(typeNull), dataHandle: nil)
        var eventToSend: AppleEvent = AppleEvent(descriptorType: UInt32(typeNull), dataHandle: nil)
        
        _ = AECreateDesc(
            UInt32(typeProcessSerialNumber),
            &psn,
            MemoryLayout<ProcessSerialNumber>.size,
            &targetDesc
        )
        
        _ = AECreateAppleEvent(
            UInt32(kCoreEventClass),
            //kAELogOut,
            kAEReallyLogOut,
            &targetDesc,
            AEReturnID(kAutoGenerateReturnID),
            AETransactionID(kAnyTransactionID),
            &eventToSend
        )
        
        AEDisposeDesc(&targetDesc)
        
        _ = AESendMessage(
            &eventToSend,
            &eventReply,
            AESendMode(kAENormalPriority),
            kAEDefaultTimeout
        )
    }
}
