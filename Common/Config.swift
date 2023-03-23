//
//  Config.swift
//  SLC
//
//  Created by Test on 23.03.2023.
//

import Foundation

final class Config {
    static let shared = Config()
    private let url = URL(fileURLWithPath: "/Library/Management/plists/Config.plist")
    private let hoursUrl = URL(fileURLWithPath: "/Library/Management/plists/Hours.plist")

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
