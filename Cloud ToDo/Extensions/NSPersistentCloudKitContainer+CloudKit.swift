//
//  NSPersistentCloudKitContainer+CloudKit.swift
//  Cloud ToDo
//
//  Created by Philipp on 10.05.20.
//  Copyright © 2020 Philipp. All rights reserved.
//

import CoreData
import CloudKit

extension NSPersistentCloudKitContainer {

    enum ManageCKError: Error {
        case managedObjectHasNoCKRecord
        case publishFailed(Error)
        case unpublishFailed(Error)
    }

    enum ManageCKResult {
        case missing(Error)
        case found(CKRecord)
        case new(CKRecord)
        case deleted
    }

    var appContainer : CKContainer {
        CKContainer(identifier: "iCloud.com.yourcompany.Cloud-ToDo.todo")
    }

    func fetchPublicCKRecord(of object: NSManagedObject, createIfMissing: Bool = true, completion: @escaping (Result<ManageCKResult, ManageCKError>)->Void) {
        guard let record = self.record(for: object.objectID) else {
            completion(.failure(.managedObjectHasNoCKRecord))
            return
        }
        print("record=\(record.recordID.recordName)")
        print("record zone=\(record.recordID.zoneID.zoneName)")


        let publicRecordId = CKRecord.ID(recordName: record.recordID.recordName, zoneID: CKRecordZone.default().zoneID)

        appContainer.publicCloudDatabase.fetch(withRecordID: publicRecordId) { (existingRecord, error) in
            if let error = error {
                print("Error \(error.localizedDescription) occured")
                if createIfMissing {
                    let newRecord = CKRecord(recordType: record.recordType, recordID: publicRecordId)
                    print("Creating record")
                    completion(.success(.new(newRecord)))
                }
                print("Missing record")
                completion(.success(.missing(error)))
            }
            else {
                print("Record \(existingRecord!.recordID.recordName) fetched")
                completion(.success(.found(existingRecord!)))
            }
        }
    }

    func isRecordPublished(of object: NSManagedObject, completion: @escaping (Result<Bool, ManageCKError>)->Void) {
        fetchPublicCKRecord(of: object, createIfMissing: false) { (result) in
            switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let result):
                    if case .found(_) = result {
                        print("isRecordPublished: Record found")
                        completion(.success(true))
                    }
                    else if case .missing(_) = result {
                        print("isRecordPublished: Record missing")
                        completion(.success(false))
                    }
            }
        }
    }

    func publishRecord(of object: NSManagedObject, completion: @escaping (Result<CKRecord, ManageCKError>)->Void) {
        guard let record = self.record(for: object.objectID) else {
            completion(.failure(.managedObjectHasNoCKRecord))
            return
        }
        print("record=\(record.recordID.recordName)")
        print("record zone=\(record.recordID.zoneID.zoneName)")

        fetchPublicCKRecord(of: object) { result in
            switch result {
                case .failure(let error):
                    print("publishRecord: error: \(error)")
                    completion(.failure(error))

                case .success(let result):

                    let publicRecord: CKRecord
                    switch result {
                        case .found(let record):
                            publicRecord = record
                        case .new(let record):
                            publicRecord = record
                        case .missing(let error):
                            print("publishRecord: Record missing")
                            completion(.failure(.publishFailed(error)))
                            return
                        default:
                            fatalError("Unexpected result \(result)")
                    }

                    // Updating content of record
                    for key in record.allKeys() {
                        publicRecord[key] = record[key]
                    }

                    // Storing public record
                    self.appContainer.publicCloudDatabase.save(publicRecord) { (record, error) in
                        if let error = error {
                            print("publishRecord: error: \(error)")
                            completion(.failure(.publishFailed(error)))
                        }
                        else {
                            print("publishRecord: Record \(record!.recordID.recordName) saved")
                            completion(.success(record!))
                        }
                    }
            }
        }
    }

    func unpublishRecord(of object: NSManagedObject, completion: @escaping (Result<Bool, ManageCKError>)->Void) {
        guard let record = self.record(for: object.objectID) else {
            completion(.failure(.managedObjectHasNoCKRecord))
            return
        }
        print("record=\(record.recordID.recordName)")
        print("record zone=\(record.recordID.zoneID.zoneName)")

        let publicRecordId = CKRecord.ID(recordName: record.recordID.recordName, zoneID: CKRecordZone.default().zoneID)

        appContainer.publicCloudDatabase.delete(withRecordID: publicRecordId) { (record, error) in
            if let error = error {
                print("Error \(error.localizedDescription) occured")
                completion(.failure(.unpublishFailed(error)))
            }
            else {
                completion(.success(true))
            }
        }
    }

}
