//
//  CloudKitManager.swift
//  ToDo
//
//  Created by Philipp on 18.05.20.
//  Copyright © 2020 Philipp. All rights reserved.
//

import Foundation
import CloudKit
import Combine

class CloudKitManager: ObservableObject {

    // Singleton accessor
    static let shared = CloudKitManager()
    

    enum ManageCKError: Error {
        case managedObjectHasNoCKRecord
        case publishFailed(Error)
        case unpublishFailed(Error)
        case recordQueryFailed(Error)
        case userQueryFailed(Error)
        case discoverUsersFailed(Error)
    }

    enum ManageCKResult {
        case missing(Error)
        case found(CKRecord)
        case new(CKRecord)
        case deleted
    }

    let containerIdentifier = "iCloud.com.yourcompany.Cloud-ToDo.todo"

    lazy var appContainer : CKContainer = {
        CKContainer(identifier: containerIdentifier)
    }()

    @Published var accountStatus: CKAccountStatus?
    var userRecordID: CKRecord.ID?

    var cancellables = Set<AnyCancellable>()

    // Private initializer to ensure Singleton
    private init() {
        // Fetch initial account status
        fetchAccountStatus()

        // Register for iCloud account change notifications
        NotificationCenter.default.publisher(for: .CKAccountChanged)
            .sink { (notification) in
                print("AccountStatus changed: \(notification.description)")
                self.fetchAccountStatus()
            }
            .store(in: &cancellables)
    }

    private func logError(error: Error, caller: String = #function) {
        if let ckerror = error as? CKError {
            print("\(caller): CloudKit Error")
            for key in ckerror.errorUserInfo.keys {
                if let value = ckerror.errorUserInfo[key] {
                    print("    \(key): \(value)")
                }
            }
            print("\(caller): error \(String(describing: ckerror.errorUserInfo[NSLocalizedDescriptionKey]))")
        }
        else {
            print("\(caller): error " + error.localizedDescription)
        }
    }

    private func fetchAccountStatus() {
        appContainer.accountStatus { status, error in
            if let error = error {
                self.logError(error: error)
            } else {
                DispatchQueue.main.async {
                    self.accountStatus = status
                }
                if status == .available {
                    // the user is logged in, so fetch the user record
                    self.fetchUserRecord()
                }
                else {
                    print("fetchAccountStatus: unexpected CKAccountStatus \(status.rawValue)")
                }
            }
        }
    }

    private func fetchUserRecord() {
        // Fetch the users personal record ID
        appContainer.fetchUserRecordID { (userRecordID, error) in
            if let error = error {
                self.logError(error: error)
            }
            else {
                print("User record fetched: \(userRecordID!)")

                self.userRecordID = userRecordID
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            }
        }
    }

    func isCKAvailable() -> Bool {
        return accountStatus == .available
    }

    func isOwnUserRecord(_ userRecordID: CKRecord.ID) -> Bool {
        if let userID = self.userRecordID {
            return userRecordID.recordName == userID.recordName
        }
        return false
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
                if createIfMissing {
                    let newRecord = CKRecord(recordType: record.recordType, recordID: publicRecordId)
                    print("Creating record")
                    completion(.success(.new(newRecord)))
                }
                else {
                    self.logError(error: error)
                    print("Missing record")
                    completion(.success(.missing(error)))
                }
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
                    self.logError(error: error)
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
                    self.logError(error: error)
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
                            self.logError(error: error)
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
                self.logError(error: error)
                completion(.failure(.unpublishFailed(error)))
            }
            else {
                completion(.success(true))
            }
        }
    }

    func fetchPublicCKRecord(for user: CKUserIdentity, completion: @escaping (Result<[CKRecord], ManageCKError>)->Void)  {
        guard let userRecordID = user.userRecordID else {
            print("User record ID not available")
            return
        }
        let searchPredicate = NSPredicate(format: "creatorUserRecordID == %@", userRecordID)
        let query = CKQuery(recordType: "CD_TodoItem", predicate: searchPredicate)
        appContainer.publicCloudDatabase.perform(query, inZoneWith: .default) { (records, error) in
            if let error = error {
                self.logError(error: error)
                completion(.failure(.recordQueryFailed(error)))
            }
            else {
                completion(.success(records!))
            }
        }
    }

    func fetchPublicCKRecords(completion: @escaping (Result<[CKRecord], ManageCKError>)->Void)  {
        let query = CKQuery(recordType: "CD_TodoItem", predicate: NSPredicate(value: true))
        appContainer.publicCloudDatabase.perform(query, inZoneWith: .default) { (records, error) in
            if let error = error {
                self.logError(error: error)
                completion(.failure(.recordQueryFailed(error)))
            }
            else {
                completion(.success(records!))
            }
        }
    }

    func fetchUserIdentityRecords(for userIDs: [String], completion: @escaping (Result<[String:CKUserIdentity], ManageCKError>)->Void)  {
        var userMapResult = [String:CKUserIdentity]()

        guard isCKAvailable() else {
            completion(.success(userMapResult))
            return
        }

        // Make list of users unique and create the lookup data
        let uniqueUsers = Set<String>(userIDs)
        let lookupInfos = uniqueUsers.map { CKUserIdentity.LookupInfo(userRecordID: CKRecord.ID(recordName: $0)) }

        // Create the discover operation and run it on the container
        let discoverOperation = CKDiscoverUserIdentitiesOperation(userIdentityLookupInfos: lookupInfos)
        discoverOperation.userIdentityDiscoveredBlock = { (user: CKUserIdentity, info: CKUserIdentity.LookupInfo)  in
            let userRecordId = info.userRecordID!.recordName
            userMapResult[userRecordId] = user
        }
        discoverOperation.discoverUserIdentitiesCompletionBlock = { (error: Error?) in
            if let error = error {
                self.logError(error: error)
                completion(.failure(.userQueryFailed(error)))
                return
            }
            completion(.success(userMapResult))
        }
        appContainer.add(discoverOperation)
    }

    func discoverAllUserIdentities(completion: @escaping (Result<[CKUserIdentity], ManageCKError>)->Void)  {
        appContainer.discoverAllIdentities(completionHandler: { users, error in
            guard let userIdentities = users, error == nil else {
                self.logError(error: error!)
                completion(.failure(.discoverUsersFailed(error!)))
                return
            }
            completion(.success(userIdentities))
        })
    }
}
