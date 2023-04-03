//
//  Swift.Error.swift
//  SLC
//
//  Created by Test on 03.04.2023.
//

import Foundation

extension String: LocalizedError {
    public var errorDescription: String? { self }
}
