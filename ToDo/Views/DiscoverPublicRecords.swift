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
        .navigationBarTitle("Public records")
    }

    private func refreshData() {
        let fetchRequest : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CKTodoItem")
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs

        do {
            try moc.execute(batchDeleteRequest)
            self.moc.mySave("DiscoverPublicRecords: refreshData after delete")

            DispatchQueue.global().async {

                self.cloudKitManager.fetchPublicCKRecords(completion: { result in
                    guard case Result.success(let records) = result else {
                        print("Error fetching records for selected user")
                        self.finishLoading()
                        return
                    }
                    print("fetched records: \(records)")
                    let todoItems : [CKTodoItem] = records.map {
                        CKTodoItem(record: $0, context: self.moc)
                    }
                    print("fetched items: \(todoItems)")
                    self.moc.mySave("DiscoverPublicRecords: refreshData after add")
                    //                changes[NSInsertedObjectsKey] = todoItems.map(\.objectID)
                    //                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.moc])

                    let userIDs = todoItems.map(\.ckUserID)
                    self.cloudKitManager.fetchUserIdentityRecords(for: userIDs, completion: { result in
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
        } catch {
            fatalError("Failed to perform batch update: \(error)")
        }
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
