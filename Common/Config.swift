//
//  Config.swift
//  SLC
//
//  Created by Test on 23.03.2023.
//

import Foundation

let plistsFolder = "/Library/Management/plists"

final class Config {
    static let shared = Config()
    private let url = URL(fileURLWithPath: "\(plistsFolder)/Config.plist")
    private let hoursUrl = URL(fileURLWithPath: "\(plistsFolder)/Hours.plist")
    private let dialogsUrl = URL(fileURLWithPath: "\(plistsFolder)/Dialogs.plist")

    var preLoginAgentDelay: TimeInterval {
        read(key: "PreLoginAgentDelay", defaultValue: 10)
    }
    
    var idleTimeout: TimeInterval {
        read(key: "IdleTimeout", defaultValue: 1800)
    }
    
    var usersEnabled: Bool {
        read(key: "UsersEnabled", defaultValue: true)
    }

    var extendHours: [Int] {
        guard
            let array = try? NSArray(contentsOf: hoursUrl, error: ()),
            let result = array as? [Int]
        else { return [1, 2, 4, 6] }
        
        return result
    }
    
    var allowExtend: Bool {
        read(key: "allowExtend", defaultValue: false)
    }
    
    var applicationIcon: URL? {
        let name = read(key: "AppIcon", defaultValue: "")
        guard name.count > 0 else { return nil }
        return URL(fileURLWithPath: plistsFolder).appendingPathComponent(name)
    }

    private init() {}

    private func read<T>(key: String, defaultValue: T) -> T {
        guard let dict = try? NSDictionary(contentsOf: url, error: ()) else { assertionFailure(); return defaultValue }
        guard let result = dict[key] as? T else { return defaultValue }
        return result
    }
    
    private func write(callback: (NSMutableDictionary) -> Void) {
        do {
            guard let dict = try? NSMutableDictionary(contentsOf: url, error: ()) else { assertionFailure(); return }
            callback(dict)
            try dict.write(to: url)
            print("Done")
        }
        catch {
            print("Error:\n")
            print(error)
        }
    }

    func enableUsers() {
        write { dict in
            dict["UsersEnabled"] = true
        }
    }

    func disableUsers() {
        write { dict in
            dict["UsersEnabled"] = false
        }
    }
}

extension Config {
    var dialogExtendText: String {
        return dialog(name: "Extend", prop: "text", default:
        """
        You have successfully login.
        This option should only be used for film students and faculty where an extend period of time is needed after "Extend" is chosen and time is done.
        If you don't use the computer the computer will log you off.
        Click "extend" to Accept the terms or click "Log Off"
        """)
    }
    
    var dialogIdleText: String {
        return dialog(name: "Idle", prop: "text", default:
        """
        The Computer has detected that is not in use. Click "Log Off" or click "Okay" to confirm it is in use.
        """)
    }
    
    var dialogBackupText1: String {
        return dialog(name: "Backup", prop: "text1", default:
        """
        System maintenance
        """)
    }
    
    var dialogBackupText2: String {
        return dialog(name: "Backup", prop: "text2", default:
        """
        help desk
        """)
    }
    
    var dialogBackupText3: String {
        return dialog(name: "Backup", prop: "text3", default:
        """
        SARAH • LAWRENCE • COLLEGE
        """)
    }
    
    var dialogBackupText4: String {
        return dialog(name: "Backup", prop: "text4", default:
        """
        The system is cleaning up. Please do not power the computer down.
        """)
    }
    
    var dialogBackupImage: URL? {
        dialog(name: "Backup", prop: "image")
    }

    var dialogWelcomeText: String {
        return dialog(name: "Welcome", prop: "text", default:
        """
        Welcome to Sarah Lawrence College.
        
        This computer will log you off if not in use and we do not save your work.  
        You have 120 seconds to the accept terms.
        """)
    }
    
    var dialogWelcomeImage: URL? {
        dialog(name: "Welcome", prop: "image")
    }
    
    var dialogAboutText1: String {
        return dialog(name: "About", prop: "text1", default: Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "")
    }
    
    var dialogAboutText2: String {
        return dialog(name: "About", prop: "text2", default: Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String ?? "")
    }
    
    private func dialog(name: String, prop: String, default defaultText: String) -> String {
        guard
            let root = try? NSDictionary(contentsOf: dialogsUrl, error: ()),
            let dialog = root[name] as? NSDictionary,
            let result = dialog[prop] as? String
        else { return defaultText }
        
        return result
    }
    
    private func dialog(name: String, prop: String) -> URL? {
        guard
            let root = try? NSDictionary(contentsOf: dialogsUrl, error: ()),
            let dialog = root[name] as? NSDictionary,
            let name = dialog[prop] as? String
        else { return nil }
        
        return URL(fileURLWithPath: plistsFolder).appendingPathComponent(name)
    }
}
