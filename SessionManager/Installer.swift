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
    case bundledPlistsMissing
    case permissionsError
    case installerFailed(path: String)
}

struct Installer {
    private static let installerPath = "/tmp/installer.sh"
    let plistsFolder: String
    let cleanupInterval: Int

    func installPriviledgedTool() throws {
        func plist(for name: String) -> String? {
            return Bundle.main.path(forResource: name, ofType: "plist")
        }
                
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
        
        guard let cleanerPlist = plist(for: "edu.slc.logoutcleaner"),
              let adminsPlist = plist(for: "Admins"),
              let usersPlist = plist(for: "Users") else {
                  throw InstallerError.bundledPlistsMissing
              }
        
        let fm = FileManager.default
        
        if fm.fileExists(atPath: backupToolLocation) && fm.fileExists(atPath: backupToolPlistPath) {
            print("Sarah Lawrence College Manager installed properly")
            return
        }
        
        guard let backupToolPath = Bundle.main.path(forResource: "backupScript.sh", ofType: "") else {
            throw InstallerError.backupScriptMissing
        }
        
        guard let cleanupToolPath = Bundle.main.path(forResource: "cleanupScript.sh", ofType: "") else {
            throw InstallerError.cleanupScriptMissing
        }
        
        let installerScript = """
#!/bin/bash

launchctl unload \(backupToolPlistPath)
launchctl unload edu.psu.PennSessionManagerService.plist
rm  /Library/LaunchDaemons/edu.psu.PennSessionManagerService.plist

launchctl unload \(cleanupToolPlistPath)
launchctl unload edu.psu.SarahLawrenceCollegeCleanupDaemon.plist
rm  /Library/LaunchDaemons/edu.psu.SarahLawrenceCollegeCleanupDaemon.plist

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

cp -f "\(cleanerPlist)" \(plistsFolder)
cp -f "\(adminsPlist)" \(plistsFolder)
cp -f "\(usersPlist)" \(plistsFolder)

mv -f "\(backupTempToolPlistPath)" \(backupToolPlistPath)
chown -R root:wheel \(backupToolPlistPath)

launchctl load \(backupToolPlistPath)

mv -f "\(cleanupTempToolPlistPath)" \(cleanupToolPlistPath)
chown -R root:wheel \(cleanupToolPlistPath)

launchctl load \(cleanupToolPlistPath)

rm /tmp/installer.sh
"""
        
        // Write installer script.
        try installerScript.write(toFile: Self.installerPath, atomically: true, encoding: .utf8)
        
        // Read the file watcher daemon plist and copy to a temp path for later install.
        try copyFileWatcherDaemon(backupToolLocation, backupTempToolPlistPath)
        
        // Read the cleanup daemon plist and copy to a temp path for later install.
        try copyCleanupDaemon(cleanupToolLocation, cleanupTempToolPlistPath)
        
        var attributes = [FileAttributeKey : Any]()
        attributes[.posixPermissions] = 0o777
        do {
            try fm.setAttributes(attributes, ofItemAtPath: Self.installerPath)
        } catch {
            throw InstallerError.permissionsError
        }
        
        // Run installer with admin privileges.
        let process = Process()
        process.launchPath = "/usr/bin/osascript"
        process.arguments = ["-e", "do shell script \"/tmp/installer.sh\" with administrator privileges"]
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
            .replacingOccurrences(of: "$interval", with: cleanupInterval.description)
        try cleanupDaemon.write(toFile: tempToolPlistPath, atomically: true, encoding: .utf8)
    }
}
