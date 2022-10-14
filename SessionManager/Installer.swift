//
//  Installer.swift
//  SLC
//
//  Created by Sebastián Benítez on 13/10/2022.
//

import Cocoa

enum InstallerError: Error {
    case fileWatcherDaemonMissing
    case backupScriptMissing
    case cleanupDaemonMissing
    case cleanupScriptMissing
    case preloginAgentMissing
    case bundledPlistsMissing
    case permissionsError
    case installerFailed(path: String)
}

struct Installer {
    private static let installerPath = "/tmp/installer.sh"
    let plistsFolder: String

    func installPriviledgedTool(reinstall: Bool = false, overwrite: Bool = false) throws {
        func plist(for name: String) -> String? {
            return Bundle.main.path(forResource: name, ofType: "plist")
        }
        
        let overwrite = overwrite ? "overwrite" : ""
                
        let toolIFolder = "/Library/Management/.tool"
        let usrDirIFolder = "/Library/Management/userDirBkups"
        let usrTemplateIFolder = "/Library/Management/userTemplate"
        
        // Backup script and daemon.
        let backupToolName = "backupScript-1.1.2.sh"
        let backupToolLocation = "\(toolIFolder)/\(backupToolName)"
        let backupToolPlistPath = "/Library/LaunchDaemons/edu.slc.gm.SarahLawrenceCollegeService.plist"
        let backupTempToolPlistPath = "/tmp/edu.slc.gm.SarahLawrenceCollegeService.plist"
        
        // Cleanup script and daemon.
        let cleanupToolName = "cleanup.sh"
        let cleanupToolLocation = "\(toolIFolder)/\(cleanupToolName)"
        let cleanupToolPlistPath = "/Library/LaunchDaemons/edu.slc.gm.SarahLawrenceCollegeCleanupDaemon.plist"
        let cleanupTempToolPlistPath = "/tmp/edu.slc.gm.SarahLawrenceCollegeCleanupDaemon.plist"
        
        // Prelogin agent.
        let preloginAgentName = "SLCPreloginAgent.app"
        let preloginAgentLocation = "/Library/PrivilegedHelperTools/\(preloginAgentName)"
        let preloginAgentPListPath = "/Library/LaunchAgents/edu.slc.gm.SLCPreloginAgent.plist"
        let preloginAgentTempToolPlistPath = "/tmp/edu.slc.gm.SLCPreloginAgent.plist"
        
        guard let cleanerPlist = plist(for: "edu.slc.logoutcleaner"),
              let adminsPlist = plist(for: "Admins"),
              let configPlist = plist(for: "Config"),
              let usersPlist = plist(for: "Users") else {
                  throw InstallerError.bundledPlistsMissing
              }
        
        let fm = FileManager.default
        
        if !reinstall && fm.fileExists(atPath: backupToolLocation) && fm.fileExists(atPath: backupToolPlistPath) {
            print("Sarah Lawrence College Manager installed properly")
            return
        }
        
        guard let backupToolPath = Bundle.main.path(forResource: "backupScript.sh", ofType: "") else {
            throw InstallerError.backupScriptMissing
        }
        
        guard let cleanupToolPath = Bundle.main.path(forResource: "cleanupScript.sh", ofType: "") else {
            throw InstallerError.cleanupScriptMissing
        }
        
        guard let preloginAgentPath = Bundle.main.path(forResource: "SLCPreloginAgent", ofType: "app") else {
            throw InstallerError.preloginAgentMissing
        }
        
        let installerScript = """
#!/bin/bash

launchctl unload \(cleanupToolPlistPath)
launchctl unload edu.psu.SarahLawrenceCollegeCleanupDaemon.plist
rm /Library/LaunchDaemons/edu.psu.SarahLawrenceCollegeCleanupDaemon.plist

launchctl unload \(backupToolPlistPath)
launchctl unload edu.slc.gm.SarahLawrenceCollegeService.plist
rm /Library/LaunchDaemons/edu.slc.gm.SarahLawrenceCollegeService.plist

launchctl unload \(preloginAgentPListPath)
launchctl unload edu.slc.gm.SLCPreloginAgent.plist
rm /Library/LaunchAgents/edu.slc.gm.SLCPreloginAgent.plist

[ -d \(usrTemplateIFolder) ] || install -d \(usrTemplateIFolder)
chmod a=rwx \(usrTemplateIFolder)
[ -d \(usrDirIFolder) ] || install -d \(usrDirIFolder)
chmod a=rwx \(usrDirIFolder)
[ -d \(toolIFolder) ] || install -d \(toolIFolder)
chmod a=rwx \(toolIFolder)
[ -d \(plistsFolder) ] || install -d \(plistsFolder)
chmod a=rwx \(plistsFolder)

cp -f "\(backupToolPath)" \(backupToolLocation)
chown -R root:wheel \(backupToolLocation)
chmod ug=rwx,o= \(backupToolLocation)

cp -f "\(cleanupToolPath)" \(cleanupToolLocation)
chown -R root:wheel \(cleanupToolLocation)
chmod ug=rwx,o= \(cleanupToolLocation)

cp -f "\(preloginAgentPath)" \(preloginAgentLocation)
chown -R root:wheel \(preloginAgentLocation)
chmod ug=rwx,o= \(preloginAgentLocation)

if [ "\(overwrite)" -eq "overwrite" ]
then
    cp -f "\(cleanerPlist)" \(plistsFolder)
    cp -f "\(adminsPlist)" \(plistsFolder)
    cp -f "\(usersPlist)" \(plistsFolder)
    cp -f "\(configPlist)" \(plistsFolder)
fi

mv -f "\(backupTempToolPlistPath)" \(backupToolPlistPath)
chown -R root:wheel \(backupToolPlistPath)
launchctl load \(backupToolPlistPath)

mv -f "\(cleanupTempToolPlistPath)" \(cleanupToolPlistPath)
chown -R root:wheel \(cleanupToolPlistPath)
launchctl load \(cleanupToolPlistPath)

mv -f "\(preloginAgentTempToolPlistPath)" \(preloginAgentPListPath)
chown -R root:wheel \(preloginAgentPListPath)
launchctl load \(preloginAgentPListPath)


rm /tmp/installer.sh
"""
        
        // Write installer script.
        try installerScript.write(toFile: Self.installerPath, atomically: true, encoding: .utf8)
        
        // Read the file watcher daemon plist and copy to a temp path for later install.
        try copyFileWatcherDaemon(backupToolLocation, backupTempToolPlistPath)
        
        // Read the cleanup daemon plist and copy to a temp path for later install.
        try copyCleanupDaemon(cleanupToolLocation, cleanupTempToolPlistPath)
        
        // Read the prelogin agent plist and copy to a temp path for later install.
        try copyPreloginAgent(preloginAgentPListPath)
        
        var attributes = [FileAttributeKey : Any]()
        attributes[.posixPermissions] = 0o777
        do {
            try fm.setAttributes(attributes, ofItemAtPath: Self.installerPath)
        } catch {
            throw InstallerError.permissionsError
        }
        
        // Check if we are running as sudo, so we don't need to run the installer
        // with osascript.
        let process = Process()

        if getuid() == 0 {
            // We are root, so we run the install normally.
            print("Running installer as root")
            process.launchPath  = "/tmp/installer.sh"
        } else {
            // Run installer with admin privileges.
            print("Running installer with elevated privileges")
            process.launchPath = "/usr/bin/osascript"
            process.arguments = ["-e", "do shell script \"/tmp/installer.sh\" with administrator privileges"]
        }

        process.launch()
        process.waitUntilExit()

        let status = process.terminationStatus
        if status != 0 {
            throw InstallerError.installerFailed(path: Self.installerPath)
        }
    }
    // MARK: - Private Functions
    
    fileprivate func copyFileWatcherDaemon(_ backupToolLocation: String,
                                           _ tempToolPlistPath: String) throws {
        guard let fileWatcherDaemonURL = Bundle.main.url(forResource: "FileWatcherDaemon",
                                                         withExtension: "plist") else {
            throw InstallerError.fileWatcherDaemonMissing
        }
        
        let fileWatcherDaemon = try String(contentsOf: fileWatcherDaemonURL)
            .replacingOccurrences(of: "$backupToolLocation", with: "\(backupToolLocation)")
        try fileWatcherDaemon.write(toFile: tempToolPlistPath, atomically: true, encoding: .utf8)
    }
    
    fileprivate func copyCleanupDaemon(_ cleanupToolLocation: String,
                                       _ tempToolPlistPath: String) throws {
        guard let cleanupDaemonURL = Bundle.main.url(forResource: "CleanupDaemon",
                                                     withExtension: "plist") else {
            throw InstallerError.cleanupDaemonMissing
        }
        
        let cleanupDaemon = try String(contentsOf: cleanupDaemonURL)
            .replacingOccurrences(of: "$cleanupToolLocation", with: "\(cleanupToolLocation)")
        try cleanupDaemon.write(toFile: tempToolPlistPath, atomically: true, encoding: .utf8)
    }
    
    fileprivate func copyPreloginAgent(_ tempToolPlistPath: String) throws {
        guard let preloginAgentURL = Bundle.main.url(forResource: "PreloginAgent",
                                                     withExtension: "plist") else {
            throw InstallerError.preloginAgentMissing
        }
        
        let preloginAgent = try String(contentsOf: preloginAgentURL)
        try preloginAgent.write(toFile: tempToolPlistPath, atomically: true, encoding: .utf8)
    }
}
