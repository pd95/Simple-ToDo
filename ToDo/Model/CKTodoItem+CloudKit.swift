//
//  CKTodoItem+CloudKit.swift
//  ToDo
//
//  Created by Philipp on 19.05.20.
//  Copyright © 2020 Philipp. All rights reserved.
//

import CoreData
import CloudKit


extension CKTodoItem {
    convenience init(record: CKRecord, context: NSManagedObjectContext) {
        self.init(context: context)
        for attribute in self.entity.attributesByName {
            let key = attribute.key
            let type = attribute.value.attributeType

            let ckAttributeKey = "CD_\(attribute.key)"
            if let ckValue = record.value(forKey: ckAttributeKey) {
                switch type {
                    case .stringAttributeType:
                        self.setValue(ckValue as! String, forKey: key)
                        break
                    case .booleanAttributeType:
                        self.setValue(ckValue as! Bool, forKey: key)
                        break
                    case .dateAttributeType:
                        self.setValue(ckValue as! Date, forKey: key)
                        break
                    default:
                        print("unsupported type \(type)")
                }
            }
        }
        self.ckRecordID = record.recordID.recordName
        if CloudKitManager.shared.isOwnUserRecord(record.creatorUserRecordID!) {
            self.ckUserID = CKCurrentUserDefaultName
        }
        else {
            self.ckUserID = record.creatorUserRecordID!.recordName
        }
    }

    var isOwnRecord: Bool {
        return self.ckUserID == CKCurrentUserDefaultName
    }
}
