//
//  NSPersistentCloudKitContainer+CloudKit.swift
//  ToDo
//
//  Created by Philipp on 10.05.20.
//  Copyright © 2020 Philipp. All rights reserved.
//

import CoreData

extension NSPersistentCloudKitContainer {

    func publishRecord(of object: NSManagedObject,
                       completion: ((Result<Bool, CloudKitManager.ManageCKError>)->Void)? = nil) {
        let record = self.record(for: object.objectID)
        CloudKitManager.shared.publishRecord(of: record, completion: completion)
    }

    func unpublishRecord(of object: NSManagedObject,
                         completion: ((Result<Bool, CloudKitManager.ManageCKError>)->Void)? = nil) {
        let record = self.record(for: object.objectID)
        CloudKitManager.shared.unpublishRecord(of: record, completion: completion)
    }

}
