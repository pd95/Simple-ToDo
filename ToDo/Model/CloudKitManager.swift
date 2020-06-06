//
//  CloudKitManager.swift
//  ToDo
//
//  Created by Philipp on 18.05.20.
//  Copyright © 2020 Philipp. All rights reserved.
//

import Foundation
import os.log
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

    // MARK: - CloudKit stuff

    private func fetchAccountStatus() {
        os_log(.info, log: .ckmanager, "fetchAccountStatus")
        appContainer.accountStatus { status, error in
            if let error = error {
                os_log(.error, log: .ckmanager, "Fetching accoung status: %{PUBLIC}@", error.localizedDescription)
            } else {
                DispatchQueue.main.async {
                    self.accountStatus = status
                }
                if status == .available {
                    // the user is logged in, so fetch the user record
                    self.fetchUserRecord()
                }
                else {
                    os_log(.error, log: .ckmanager, "unexpected CKAccountStatus: %{PUBLIC}@", status.rawValue)
                }
            }
        }
    }

    private func fetchUserRecord() {
        // Fetch the users personal record ID
        appContainer.fetchUserRecordID { (userRecordID, error) in
            if let error = error {
                os_log(.error, log: .ckmanager, "Fetching user record: %{PUBLIC}@", error.localizedDescription)
            }
            else {
                os_log(.info, log: .ckmanager, "User record fetched: %{PUBLIC}@", userRecordID!.recordName)

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

    func publishRecord(of record: CKRecord?, completion: ((Result<Bool, ManageCKError>)->Void)? = nil) {
        guard let record = record else {
            completion?(.failure(.managedObjectHasNoCKRecord))
            return
        }
        os_log(.debug, log: .ckmanager, "record: %{PUBLIC}@", record.recordID.recordName)

        let publicRecordId = CKRecord.ID(recordName: record.recordID.recordName, zoneID: CKRecordZone.default().zoneID)

        appContainer.publicCloudDatabase.fetch(withRecordID: publicRecordId) { (existingRecord, error) in
            let publicRecord: CKRecord
            if let _ = error {
                publicRecord = CKRecord(recordType: record.recordType, recordID: publicRecordId)
            }
            else {
                publicRecord = existingRecord!
            }

            // Updating content of record
            for key in record.allKeys() {
                publicRecord[key] = record[key]
            }

            // Storing public record
            self.appContainer.publicCloudDatabase.save(publicRecord) { (record, error) in
                if let error = error {
                    os_log(.error, log: .ckmanager, "Storing public record: %{PUBLIC}@", error.localizedDescription)
                    completion?(.failure(.publishFailed(error)))
                }
                else {
                    os_log(.info, log: .ckmanager, "Record saved: %{PUBLIC}@", record!.recordID.recordName)
                    completion?(.success(true))
                }
            }
        }
    }

    func unpublishRecord(of record: CKRecord?, completion: ((Result<Bool, ManageCKError>)->Void)? = nil) {
        guard let record = record else {
            completion?(.failure(.managedObjectHasNoCKRecord))
            return
        }
        os_log(.debug, "record: %{PUBLIC}@", record.recordID.recordName)

        let publicRecordId = CKRecord.ID(recordName: record.recordID.recordName, zoneID: CKRecordZone.default().zoneID)

        appContainer.publicCloudDatabase.delete(withRecordID: publicRecordId) { (record, error) in
            if let error = error {
                os_log(.error, log: .ckmanager, "Deleting public record: %{PUBLIC}@", error.localizedDescription)
                completion?(.failure(.unpublishFailed(error)))
            }
            else {
                completion?(.success(true))
            }
        }
    }

    func fetchPublicCKRecord(for user: CKUserIdentity, completion: @escaping (Result<[CKRecord], ManageCKError>)->Void)  {
        guard let userRecordID = user.userRecordID else {
            os_log(.error, log: .ckmanager, "User record ID not available")
            return
        }
        let searchPredicate = NSPredicate(format: "creatorUserRecordID == %@", userRecordID)
        let query = CKQuery(recordType: "CD_TodoItem", predicate: searchPredicate)
        appContainer.publicCloudDatabase.perform(query, inZoneWith: .default) { (records, error) in
            if let error = error {
                os_log(.error, log: .ckmanager, "fetching public record: %{PUBLIC}@", error.localizedDescription)
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
                os_log(.error, log: .ckmanager, "Fetching public records: %{PUBLIC}@", error.localizedDescription)
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
                os_log(.error, log: .ckmanager, "Discovering user identities: %{PUBLIC}@", error.localizedDescription)
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
                os_log(.error, log: .ckmanager, "Discovering all user identities: %{PUBLIC}@", error!.localizedDescription)
                completion(.failure(.discoverUsersFailed(error!)))
                return
            }
            completion(.success(userIdentities))
        })
    }
}
