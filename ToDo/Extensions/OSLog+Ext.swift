//
//  OSLog+Ext.swift
//  ToDo
//
//  Created by Philipp on 06.06.20.
//  Copyright © 2020 Philipp. All rights reserved.
//

import Foundation
import os.log

extension OSLog {
    private static var subsystem = Bundle.main.bundleIdentifier!

    static let lifecycle = OSLog(subsystem: subsystem, category: "Lifecycle")
    static let ckmanager = OSLog(subsystem: subsystem, category: "CKManager")
}
