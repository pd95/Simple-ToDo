//
//  CloudKitManager.swift
//  Cloud ToDo
//
//  Created by Philipp on 18.05.20.
//  Copyright © 2020 Philipp. All rights reserved.
//

import Foundation
import CloudKit

class CloudKitManager {

    // Singleton accessor
    static let shared = CloudKitManager()
    

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



    lazy var appContainer : CKContainer = {
        CKContainer(identifier: "iCloud.com.yourcompany.Cloud-ToDo.todo")
    }()


    // Private initializer to ensure Singleton
    private init() {
    }


    func fetchPublicCKRecord(of record: CKRecord?, createIfMissing: Bool = true, completion: @escaping (Result<ManageCKResult, ManageCKError>)->Void) {
        guard let record = record else {
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

    func isRecordPublished(of record: CKRecord?, completion: @escaping (Result<Bool, ManageCKError>)->Void) {
        fetchPublicCKRecord(of: record, createIfMissing: false) { (result) in
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

    func publishRecord(of record: CKRecord?, completion: @escaping (Result<Bool, ManageCKError>)->Void) {
        guard let record = record else {
            completion(.failure(.managedObjectHasNoCKRecord))
            return
        }
        print("record=\(record.recordID.recordName)")
        print("record zone=\(record.recordID.zoneID.zoneName)")

        fetchPublicCKRecord(of: record) { result in
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
                            completion(.success(true))
                        }
                    }
            }
        }
    }

    func unpublishRecord(of record: CKRecord?, completion: @escaping (Result<Bool, ManageCKError>)->Void) {
        guard let record = record else {
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
