//
//  CKUserIdentity+Ext.swift
//  ToDo
//
//  Created by Philipp on 19.05.20.
//  Copyright © 2020 Philipp. All rights reserved.
//

import CloudKit

extension CKUserIdentity {
    static let nameFormatter = PersonNameComponentsFormatter()

    var personName: String {
        CKUserIdentity.nameFormatter.string(from: self.nameComponents!)
    }
}
