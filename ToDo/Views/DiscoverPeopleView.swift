//
//  DiscoverPeopleView.swift
//  ToDo
//
//  Created by Philipp on 13.05.20.
//  Copyright © 2020 Philipp. All rights reserved.
//

import SwiftUI
import CoreData
import CloudKit

struct DiscoverUserRecords: View {
    let user: CKUserIdentity

    @Environment(\.managedObjectContext) var moc

    @EnvironmentObject var cloudKitManager: CloudKitManager

    var fetchRequest: FetchRequest<CKTodoItem>
    var todos: FetchedResults<CKTodoItem> {
        fetchRequest.wrappedValue
    }

    @State private var isLoading: Bool = true

    init(user: CKUserIdentity) {
        self.user = user

        let entity = CKTodoItem.entity()
        let userRecordId = user.userRecordID?.recordName ?? ""

        fetchRequest = FetchRequest<CKTodoItem>(
            entity: entity,
            sortDescriptors: [NSSortDescriptor(keyPath: \CKTodoItem.createDate, ascending: false)],
            predicate: NSPredicate(format: "self.entity == %@ and ckUserID == %@", entity, userRecordId))
    }

    var body: some View {
        List {
            ForEach(self.todos) { (todo: CKTodoItem) in
                NavigationLink(destination: TodoItemDetail(todo: todo, isReadOnly: true)) {
                    VStack(alignment: .leading){
                        Text(todo.title)
                            .font(.headline)
                        Text(String(describing: todo.objectID).suffix(20))
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
        .navigationBarTitle(user.personName)
    }

    private func refreshData() {
        guard let userRecordId = user.userRecordID?.recordName else {
            fatalError("User record ID not defined")
        }

        let fetchRequest : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CKTodoItem")
        fetchRequest.predicate = NSPredicate(format: "ckUserID == %@", userRecordId)
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs

        do {
            let result = try moc.execute(batchDeleteRequest) as! NSBatchDeleteResult
            let changes: [AnyHashable: Any] = [
                NSDeletedObjectsKey: result.result as! [NSManagedObjectID]
            ]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [moc])

            cloudKitManager.fetchPublicCKRecord(for: self.user, completion: { result in
                guard case Result.success(let records) = result else {
                    print("Error fetching records for selected user")
                    self.finishLoading()
                    return
                }
                print("fetched records: \(records)")
                let todoItems : [TodoItem] = records.map {
                    CKTodoItem(record: $0, context: self.moc)
                }
                print("fetched items: \(todoItems)")
//                changes[NSInsertedObjectsKey] = todoItems.map(\.objectID)
//                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.moc])

                self.finishLoading()
            })
        } catch {
            fatalError("Failed to perform batch update: \(error)")
        }
    }

    private func finishLoading() {
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }
}

struct DiscoverPeopleView: View {
    typealias IdentityCallBack = (CKUserIdentity)->()
    @Environment(\.presentationMode) var presentationMode

    @EnvironmentObject var cloudKitManager: CloudKitManager

    let selectedPerson: IdentityCallBack?
    
    @State private var identities = [CKUserIdentity]()
    @State private var isLoading: Bool = true

    var body: some View {
        NavigationView {
            List(identities, id: \.userRecordID?.recordName) { identity in
                Button(action: { self.selectedPerson?(identity) }) {
                    Text(identity.personName)
                }
                .foregroundColor(Color.primary)
                .environment(\.isEnabled, self.selectedPerson != nil)
            }
            .navigationBarTitle("Contacts")
            .navigationBarItems(trailing: Button("Done", action: {
                self.presentationMode.wrappedValue.dismiss()
            }))
        }
        .onAppear {
            if self.isLoading {
                self.discoverFriends()
            }
        }
        .withProgressView($isLoading)
    }

    private func discoverFriends() {
        isLoading = true
        cloudKitManager.discoverAllUserIdentities(completion: { result in
            guard case Result.success(var userIdentities) = result else {
                print("Error fetching users")
                self.finishLoading()
                return
            }
            // Remove "own" user
            userIdentities = userIdentities.filter({ !self.cloudKitManager.isOwnUserRecord($0.userRecordID!) })

            print("fetched records: \(userIdentities)")
            self.finishLoading(userIdentities)
        })
    }

    private func finishLoading(_ userIdentities: [CKUserIdentity] = []) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.identities = userIdentities
        }
    }
}

struct DiscoverPeopleView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverPeopleView(selectedPerson: nil)
            .environmentObject(CloudKitManager.shared)
    }
}
