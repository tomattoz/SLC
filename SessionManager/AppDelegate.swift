//
//  AppDelegate.swift
//  Sarah Lawrence College manager
//
//  Created at Sarah Lawrence College on 04/12/21.
//

import Cocoa
//import LaunchAtLogin

class ExtendMenuItem: NSMenuItem {
    var secVal:Int = 120
}

// Accepted command line arguments:
//
// -install : reinstall scripts, daemons and configuration files.
// -overwrite : overwrite configuration files when installing.
//
// The app can be run with sudo from the command line (remotely) to do the
// first install by running: sudo /Applications/SLC.app/Contents/MacOS/SLC -install

// Time Extend
//
// -enableUsers enable ability to login by pressing application icon in About dialog
// -disableUsers disable ability to login
// -usersEnabled returns true if the aaility to login is enabled

// Other command lines useful for debugging:
//
// -disableScriptInstall : won't install script when running.
// -testing : show an orange testing window.
// -fakeLogout : do not really logout.

// Config.plist
// - allowExtend (enable ability to extend hours for regular users)
// - UsersEnabled (enable ability to login by pressing application icon in About dialog)
// - AppIcon (path is relative to plist directory)

// Hours.plist
// Array of hours to give user a choice for time extension

// Dialogs.plist
// The following dialogs can be customized:
//
// 1. Extend (extend time dialog)
//      - text
//
// 2. Idle (appears when no events occured during some time)
//      - text
//
// 3. Backup (appears while application perform backup of user data)
//      - text1
//      - text2
//      - text3
//      - text4
//      - image (background image with aspect fit from the center, path is relative to plist directory)
//
// 4. Welcome
//      - text
//      - image (background image with aspect fit from the center, path is relative to plist directory)
//
// 5. About
//      - text1
//      - text2


@main
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet var window: NSWindow!

    var isAdmin = false
    var isSystemLogout = true
    
    #if DEBUG
    let disableScriptInstall: Bool = CommandLine.arguments.contains("-disableScriptInstall")
    #else
    let disableScriptInstall: Bool = false
    #endif
    
    let install: Bool = CommandLine.arguments.contains("-install")
    let overwrite: Bool = CommandLine.arguments.contains("-overwrite")

    // Time out interval in sec
    var welcomeTimeout: TimeInterval = 120
    var welcomeTimer: Timer?
    
    var idleTimer = IdleTimer()
    
    let monitoredURL = URL(fileURLWithPath: "/tmp/slc-finished")
    let backupTriggerURL = URL(fileURLWithPath: "/tmp/trigger")
    var directoryMonitor: DirectoryMonitor?
    
    lazy var adminsPlistURL = URL(fileURLWithPath: "\(plistsFolder)/Admins.plist")
    lazy var usersPlistURL = URL(fileURLWithPath: "\(plistsFolder)/Users.plist")

    // DISABLE TESTING WINDOW
    // orange window box
    #if DEBUG
    let testingSetup: Bool = CommandLine.arguments.contains("-testing")
    #else
    let testingSetup: Bool = false
    #endif

//    #if DEBUG
    let fakeLogout: Bool = CommandLine.arguments.contains("-fakeLogout")
//    #else
//    let fakeLogout: Bool = false
//    #endif

    let showCurtain = true

    var statusBarItem: NSStatusItem!
    
    var aboutController:AboutPanelController?
    var loginController:LoginPanelController?
    var welcomeController:WelcomePanelController?
    var testingController:TestingPanelController?
    var backupController:BackupPanelController?
    var curtainController:CurtainWindowController?

    func stopAllprocesses() {
        let pid = getpid()
        print("getpid(): \(pid))\n\n\n")
        print("Processes.listAllPids: \(String(describing: Processes.listAllPids()))\n\n\n")
    }
    
    func doBackup() {
        do {
            try "\(NSUserName())\n".write(toFile: backupTriggerURL.path, atomically: true, encoding: .utf8)
        }
        catch  {
            DispatchQueue.main.async {
                NSAlert(error: error).runModal()
            }
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // Start monitoring /tmp for changes.
            self.checkForBackupCompletedMarker()
            self.directoryMonitor = DirectoryMonitor(url: self.monitoredURL.deletingLastPathComponent())
            self.directoryMonitor?.startMonitoring()
            self.directoryMonitor?.delegate = self
        }
    }
    
    func updateIdleTime() {

    }
    
    func moveWelcomeWindowDown() {
        if self.welcomeController == nil {
            return
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
        for rec in Config.shared.extendHours {
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
        idleTimer.idleTimeout = TimeInterval(sender.secVal)
        
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
        
        idleTimer.stop()
        idleTimer.idleTimeout = extendTimeout
        idleTimer.testingTimeMultiplier = sender.multiplierVal
        idleTimer.start()

        DispatchQueue.main.async{
            let string = ("Multiplier: \(sender.multiplierVal)x")
            self.testingController?.multiplierButton.title = string
        }
    }

    @IBAction func pressOkayButton(_ sender: MultiplierMenuItem!) {
        dismissCurtainWindow()
        
        if welcomeTimer != nil {
            welcomeTimer?.invalidate()
            welcomeTimer = nil
            welcomeTimeout = 120
        }
        resetIdleTimer()
    }

    func resetIdleTimer() {
        if testingController != nil {
            testingController?.stopObserving()
        }

        if testingController != nil {
            testingController?.multiplierButton.title = "Multiplier: 1x"
        }
        
        idleTimer.reset()
        
        if testingController != nil {
            testingController?.startObserving()
        }
    }
    
    func completeLogin() {
        openExtendPanel()
    }
    
    func acceptTermsLogin() {
        removeWelcomeTimeout()
        welcomeController = nil
        dismissCurtainWindow()
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if isAdmin {
            return .terminateNow
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
                self.backupController = BackupPanelController(nibName: "BackupPanel",
                                                              bundle: Bundle.main)
            }
            
            self.showCurtainWindow(contentController: self.backupController!,
                                   bgURL: Config.shared.dialogBackupImage)
        }
        
        return .terminateLater
    }

    func doLogout() {
        dismissCurtainWindow()
        welcomeController = nil

        //Start backup
        DispatchQueue.global().sync {
            self.doBackup()
        }

        isSystemLogout = false
                
        //acceptTermsLogin()
        
        self.removeWelcomeTimeout()
        print("logging out ...")
        
        if !self.fakeLogout {
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0, execute: {
                self.doStandardLogout() // fix
            })
        } else {
            print("*** FAKE LOGOUT ***")
            self.isAdmin = true
            NSApp.terminate(self)
        }
    }
    
    func setupLoginPanel() {
        
        loginController!.window?.makeKeyAndOrderFront(self)
        loginController!.window?.level = .mainMenu + 1
        loginController?.window?.center()

        loginController?.setup()

    }
    
    func openLoginPanel() -> Bool {
        guard Config.shared.usersEnabled else {
            return false
        }
        
        if loginController == nil {
            loginController = LoginPanelController.init(windowNibName:"LoginPanel")
            
            loginController?.awakeFromNib()
        }

        DispatchQueue.main.async {
            self.setupLoginPanel()
        }
        
        return true
    }

    func openIdlePanel() {
        
        if welcomeController != nil {
            dismissCurtainWindow()
        }
        
        welcomeController = WelcomePanelController(nibName: "WelcomePanel",
                                                   bundle: Bundle.main)
        
        if welcomeTimer != nil {
            welcomeTimer?.invalidate()
            welcomeTimer = nil
            welcomeTimeout = 120
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
            if self.welcomeController == nil {
                return
            }

            self.showCurtainWindow(contentController: self.welcomeController!,
                                   bgURL: Config.shared.dialogWelcomeImage)

            self.welcomeController?.textView.string = Config.shared.dialogIdleText
            self.welcomeController?.timerView.isHidden = false
            self.welcomeController?.secView.isHidden = false
            self.welcomeController?.LoginButton.isHidden = false
            
            self.welcomeController?.AcceptButton.title = "Okay"
            self.welcomeController?.AcceptButton.target = self
            self.welcomeController?.AcceptButton.action = #selector(AppDelegate.pressOkayButton(_:))

            self.resetWelcomeTimeout()
        })
    }
    
    func openExtendPanel() {
        if welcomeController == nil {
            welcomeController = WelcomePanelController(nibName: "WelcomePanel",
                                                       bundle: Bundle.main)
        }
        
        showCurtainWindow(contentController: welcomeController!,
                          bgURL: Config.shared.dialogWelcomeImage)

        self.presentExtendPanel()
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

        welcomeController?.LoginButton.isHidden = true
        
    }
    
    func presentExtendPanel() {

        welcomeController?.textView.string = Config.shared.dialogExtendText
        welcomeController?.AcceptButton.title = "Extend"
        welcomeController?.AcceptButton.target = self
        welcomeController?.AcceptButton.action = #selector(AppDelegate.presentExtendPopUpMenu(_:))

        resetWelcomeTimeout()
    }

    func welcomeTimeoutUpdate() {
        let timeout = welcomeTimeout
        if welcomeTimeout < 0 {
            doLogout()
            return
        }
        DispatchQueue.main.async {
            self.welcomeController?.timeoutLabel.stringValue = "\(Int(timeout+0.1))"
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

    private func setupApplicationIcon() {
        let statusBar = NSStatusBar.system
        var statusBarIcon = NSImage(named: "MenuBarIcon")
        let statusBarMenu = NSMenu(title: "App")

        if let iconURL = Config.shared.applicationIcon, let iconImage = NSImage(contentsOf: iconURL) {
            NSApplication.shared.applicationIconImage = iconImage
            
            if let resized = iconImage.resized(to: NSSize(width: 16, height: 16)) {
                statusBarIcon = resized
            }
        }

        statusBarMenu.addItem(
            withTitle: "About",
            action: #selector(AppDelegate.presendAbout(_:)),
            keyEquivalent: "")

        statusBarItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        statusBarItem.button?.title = ""
        statusBarItem.button?.image = statusBarIcon
        statusBarItem.button?.imageScaling = .scaleProportionallyDown
        statusBarItem.menu = statusBarMenu
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        setupApplicationIcon()
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Cleanup monitored file.
        deleteMonitoredFile()
        
        if CommandLine.arguments.argUsersEnabled {
            print(Config.shared.usersEnabled ? "Enabled" : "Disabled")
            exit(0)
        }

        if CommandLine.arguments.argEnableUsers {
            Config.shared.enableUsers()
            exit(0)
        }

        if CommandLine.arguments.argDisableUsers {
            Config.shared.disableUsers()
            exit(0)
        }

        // Run installer automatically or when manually specified.
        if !disableScriptInstall || (install && !disableScriptInstall ) {
            do {
                let installer = Installer(plistsFolder: plistsFolder)
                try installer.installPriviledgedTool(reinstall: install, overwrite: overwrite)
                
                // If manual installation was specified (through -install argument)
                // we terminate the app execution after successful install.
                if install {
                    self.isAdmin = true
                    NSApp.terminate(self)
                }
            } catch {
                if install {
                    print(error)
                    self.isAdmin = true
                    NSApp.terminate(self)
                } else {
                    NSAlert(error: error).runModal()
                    return
                }
            }
        }
        
        #if !DEBUG
        // Note: while there's a launch agent that launches the app on login,
        // the following line should be commented out.
        //LaunchAtLogin.isEnabled = true
        #endif
        
        let username = NSUserName()
        let path = adminsPlistURL.path
      
        if !FileManager.default.fileExists(atPath: path) {
            NSAlert(error: "Cant find Admins plist").runModal()
            self.isAdmin = true
            NSApp.terminate(self)

        } else {
            let plistDictionary = NSDictionary(contentsOfFile: path) as? Dictionary<String, String>

            if plistDictionary == nil {
                NSAlert(error: "Error reading Admins plist").runModal()
                self.isAdmin = true
                NSApp.terminate(self)
            } else {
                for record in  plistDictionary!.keys {
                    if username.localizedCaseInsensitiveCompare(record) == .orderedSame {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            self.isAdmin = true
                            NSApp.terminate(self)
                        }
                        return
                    }
                }
            }
        }

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

//        NSApp.presentationOptions = [.disableAppleMenu,
//                                     .disableForceQuit,
//                                     .disableProcessSwitching,
//                                     .hideDock,
//                                     .hideMenuBar]
                        
        if showCurtain {
            welcomeController = WelcomePanelController(nibName: "WelcomePanel", bundle: Bundle.main)
            _ = welcomeController?.view
            welcomeController?.textView.string = Config.shared.dialogWelcomeText
            showCurtainWindow(contentController: welcomeController!,
                              bgURL: Config.shared.dialogWelcomeImage)
        }
    }
    
    func showCurtainWindow(contentController: NSViewController, bgURL: URL?) {
        curtainController = CurtainWindowController(windowNibName:"Curtain")
        curtainController?.setBoxedContentViewController(vc: contentController, bg: bgURL)
        curtainController!.window?.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func dismissCurtainWindow() {
        curtainController?.close()
        curtainController = nil
    }
    
    func deleteMonitoredFile() {
        do {
            try FileManager.default.removeItem(at: monitoredURL)
        } catch {
            // Try to remove by calling "rm -f".
            _ = try? Process.run(URL(fileURLWithPath: "/bin/rm"),
                                 arguments: ["-f",
                                             monitoredURL.path]) { proc in }
            let tempURL = monitoredURL.deletingLastPathComponent().appendingPathComponent(UUID().uuidString)
            _ = try? FileManager.default.moveItem(at: monitoredURL, to: tempURL)
        }
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
    
    // MARK: - Private Functions
    
    private func checkForBackupCompletedMarker() {
        if FileManager.default.fileExists(atPath: monitoredURL.path) && !FileManager.default.fileExists(atPath: backupTriggerURL.path) {
            directoryMonitor?.stopMonitoring()
            deleteMonitoredFile()
            
            DispatchQueue.main.async {
                Thread.sleep(forTimeInterval: 5)
                NSApp.reply(toApplicationShouldTerminate: true)
            }
        }
    }
}

extension AppDelegate: DirectoryMonitorDelegate {
    func directoryMonitorDidObserveChange(directoryMonitor: DirectoryMonitor) {
        checkForBackupCompletedMarker()
    }
}

fileprivate struct Processes {
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


private extension NSImage {
    func resized(to newSize: NSSize) -> NSImage? {
        if let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(newSize.width), pixelsHigh: Int(newSize.height),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
        ) {
            bitmapRep.size = newSize
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
            draw(in: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), from: .zero, operation: .copy, fraction: 1.0)
            NSGraphicsContext.restoreGraphicsState()

            let resizedImage = NSImage(size: newSize)
            resizedImage.addRepresentation(bitmapRep)
            return resizedImage
        }

        return nil
    }
}
