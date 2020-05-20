//
//  TodoList.swift
//  ToDo
//
//  Created by Philipp on 21.05.20.
//  Copyright © 2020 Philipp. All rights reserved.
//

import SwiftUI
import CoreData
import CloudKit

enum Sheet {
    case addItem
    case discoverFriends
}

extension Sheet: Identifiable {
    var id: Int {
        self.hashValue
    }
}

struct TodoList: View {
    @Environment(\.managedObjectContext) var moc

    @FetchRequest(entity: TodoItem.entity(),
                  sortDescriptors: [
                    NSSortDescriptor(keyPath: \TodoItem.createDate, ascending: false)
                  ],
                  predicate: NSPredicate(format: "self.entity == %@", TodoItem.entity())
    )
    var todos: FetchedResults<TodoItem>

    @State private var sheet: Sheet?
    @State private var addedItem: TodoItem?
    @State private var showPublic: Bool = false
    @State private var selectedUser: CKUserIdentity?

    var body: some View {
        List {
            NavigationLink(destination: DiscoverPublicRecords(), isActive: self.$showPublic) {
                Text("Public")
                    .font(.headline)
            }
            if self.selectedUser != nil {
                NavigationLink(destination: DiscoverUserRecords(user: self.selectedUser!), tag: self.selectedUser!, selection: self.$selectedUser) {
                    Text("People")
                        .font(.headline)
                }
            }
            ForEach(self.todos) { (todo: TodoItem) in
                NavigationLink(destination: TodoItemDetail(todo: todo)) {
                    VStack(alignment: .leading){
                        Text(todo.title)
                            .font(.headline)
                        Text(String(describing: todo.objectID).suffix(20))
                            .font(.body)
                    }
                }
            }
            .onDelete(perform: deleteItems)
        }
        .sheet(item: $sheet, onDismiss: save, content: sheetContent)
        .navigationBarTitle("To Do")
        .navigationBarItems(
            leading: Button(action: { self.sheet = .discoverFriends }) {
                Image(systemName: "person.icloud")
                    .padding(6)
            },
            trailing: Button(action: showAddItem) {
                Image(systemName: "plus")
                    .padding(6)
        })
    }

    func sheetContent(sheet: Sheet) -> some View {
        switch sheet {
            case .addItem:
                return AnyView(
                    TodoEditor(todo: Binding<TodoItem>(
                        get: {
                            self.addedItem!
                        },
                        set: {
                            self.addedItem = $0
                        })
                ))
            case .discoverFriends:
                return AnyView(DiscoverPeopleView(selectedPerson: { (selectedUser) in
                    print("Selected User: \(selectedUser)")
                    self.selectedUser = selectedUser
                    self.sheet = nil
                })
                .environment(\.managedObjectContext, moc)
                .environmentObject(CloudKitManager.shared)
            )
        }
    }

    func showAddItem() {
        let addedItem = TodoItem(context: self.moc)
        addedItem.title = ""
        addedItem.details = ""
        addedItem.done = false
        addedItem.createDate = Date()

        self.addedItem = addedItem
        self.sheet = .addItem
    }

    func deleteItems(at offsets: IndexSet) {
        for offset in offsets {
            // find this book in our fetch request
            let item = todos[offset]

            // delete it from the context
            moc.delete(item)
        }

        // save the context
        save()
    }

    func save() {
        moc.mySave("TodoList")
    }
}

struct TodoList_Previews: PreviewProvider {
    static var previews: some View {
        TodoList()
            .environment(\.managedObjectContext, AppDelegate.shared.persistentContainer.viewContext)
    }
}
