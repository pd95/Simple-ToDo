//
//  CKTodoItem+CloudKit.swift
//  Cloud ToDo
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
        self.ckUserID = record.creatorUserRecordID!.recordName
        print(record)
        print(self)
    }

    var isOwnRecord: Bool {
        if let userID = CloudKitManager.shared.userRecordID {
            print("ckUserID=\(self.ckUserID)")
            print("userID.recordName=\(userID.recordName)")
            print("CKCurrentUserDefaultName=\(CKCurrentUserDefaultName)")
            return self.ckUserID == userID.recordName || self.ckUserID == CKCurrentUserDefaultName
        }
        return false
    }
}
