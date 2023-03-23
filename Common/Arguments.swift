//
//  CommandLine.swift
//  SLC
//
//  Created by Test on 23.03.2023.
//

import Foundation

extension Array where Element == String {
    var argEnableUsers: Bool { contains("-enableUsers") }
    var argDisableUsers: Bool { contains("-disableUsers") }
    var argUsersEnabled: Bool { contains("-usersEnabled") }
}
