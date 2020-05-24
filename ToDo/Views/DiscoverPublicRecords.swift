//
//  DiscoverPublicRecords.swift
//  ToDo
//
//  Created by Philipp on 19.05.20.
//  Copyright © 2020 Philipp. All rights reserved.
//

import SwiftUI
import CoreData
import CloudKit

struct DiscoverPublicRecords: View {
    @Environment(\.managedObjectContext) var moc

    @EnvironmentObject var cloudKitManager: CloudKitManager

    @FetchRequest(entity: CKTodoItem.entity(),
                  sortDescriptors: [
                    NSSortDescriptor(keyPath: \CKTodoItem.ckUserID, ascending: false),
                    NSSortDescriptor(keyPath: \CKTodoItem.createDate, ascending: false)
                  ],
                  predicate: NSPredicate(format: "self.entity == %@", CKTodoItem.entity())
    )
    var todos: FetchedResults<CKTodoItem>
    @State private var isLoading: Bool = true
    @State private var userID2NameMap = [String:CKUserIdentity]()

    var body: some View {
        List {
            ForEach(self.todos) { (todo: CKTodoItem) in
                NavigationLink(destination: TodoItemDetail(todo: todo, isReadOnly: true)) {
                    VStack(alignment: .leading){
                        Text(todo.title)
                            .font(.headline)
                        Text(self.userID2NameMap[todo.ckUserID]?.personName ?? todo.ckUserID)
                            .lineLimit(1)
                            .font(.body)
                    }
                }
            }
        }
        .loading(self.isLoading)
        .onAppear() {
            if self.isLoading {
                self.refreshData()
            }
        }
        .navigationBarItems(trailing: Button(action: refreshData) {
            Image(systemName: "arrow.clockwise.icloud")
                .imageScale(.large)
        })
        .navigationBarTitle("Public records")
    }

    private func refreshData() {
        isLoading = true
        self.cloudKitManager.fetchPublicCKRecords(completion: { result in
            guard case Result.success(let records) = result else {
                print("Error fetching records for selected user")
                self.finishLoading()
                return
            }

            var recordsByID = [String : CKRecord]()
            records.forEach {
                recordsByID[$0.recordID.recordName] = $0
            }
            print("recordsByID.count = \(recordsByID.count)")

            var userIDs = Set<String>()

            AppDelegate.shared.persistentContainer.performBackgroundTask { (moc) in
                do {
                    let fetchRequest : NSFetchRequest<CKTodoItem> = CKTodoItem.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "self.entity == %@", CKTodoItem.entity())
                    let result = try moc.fetch(fetchRequest)

                    print("result.count = \(result.count)")

                    result.forEach { (item) in
                        if let record = recordsByID[item.ckRecordID] {
                            print("Updating \(item.ckRecordID)")
                            item.importFields(from: record)
                            recordsByID.removeValue(forKey: item.ckRecordID)
                            userIDs.insert(item.ckUserID)
                        }
                        else {
                            print("Deleting \(item.ckRecordID)")
                            moc.delete(item)
                        }
                    }

                    for (key,value) in recordsByID {
                        print("Creating \(key)")
                        let item = CKTodoItem(record: value, context: moc)
                        userIDs.insert(item.ckUserID)
                    }

                    try moc.save()
                } catch {
                    fatalError("Failed to perform batch delete: \(error)")
                }
            }

            self.cloudKitManager.fetchUserIdentityRecords(for: Array(userIDs), completion: { result in
                guard case Result.success(let userMap) = result else {
                    print("Error fetching user records")
                    self.finishLoading()
                    return
                }
                print("userRecords=\(userMap)")
                self.finishLoading(userMap)
            })
        })
    }

    private func finishLoading(_ userMap: [String:CKUserIdentity] = [:]) {
        DispatchQueue.main.async {
            self.userID2NameMap = userMap
            self.isLoading = false
        }
    }
}


struct DiscoverPublicRecords_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverPublicRecords()
    }
}
