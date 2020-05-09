//
//  ContentView.swift
//  Cloud ToDo
//
//  Created by Philipp on 08.05.20.
//  Copyright © 2020 Philipp. All rights reserved.
//

import SwiftUI
import CoreData

extension NSManagedObjectContext {
    func mySave(_ source: String = "mySave") {
        if self.hasChanges {
            do {
                try self.save()
                print("\(source): saved changes")
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                print("\(source): Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
        else {
            print("\(source): no changes")
        }
    }
}

struct TodoEditor: View {
    @Environment(\.managedObjectContext) var moc
    @Environment(\.presentationMode) var presentationMode

    @Binding var todo: TodoItem

    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $todo.title)
                TextField("Details", text: $todo.details)
                //            Toggle("Done", isOn: $todo.done)
                //            .toggleStyle(SwitchToggleStyle())
            }
            .onDisappear(perform: {
                self.moc.mySave("TodoEditor")
            })
            .navigationBarTitle(todo.title.isEmpty ? "New item" : todo.title)
            .navigationBarItems(trailing: Button("Done", action: {
                self.presentationMode.wrappedValue.dismiss()
            }))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct TodoItemDetail: View {
    @Environment(\.managedObjectContext) var moc
    @ObservedObject var todo: TodoItem

    var body: some View {
        Form {
            Section(header: Text("Details")) {
                TextField("Details", text: $todo.details)
                    .frame(height: 180)

//                Text(todo.)
            }
        }
        .onDisappear(perform: {
            self.moc.mySave("TodoItemDetail")
        })
        .navigationBarTitle(todo.title)
    }
}

struct TodoList: View {
    @Environment(\.managedObjectContext) var moc

    @FetchRequest(entity: TodoItem.entity(), sortDescriptors: [
        NSSortDescriptor(keyPath: \TodoItem.createDate, ascending: false),
    ]) var todos: FetchedResults<TodoItem>

    @State private var addedItem: TodoItem?

    var body: some View {
        List {
            ForEach(self.todos) { todo in
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
        .sheet(item: $addedItem, onDismiss: save) { (item) -> TodoEditor in
            var editedItem = item
            return TodoEditor(todo: Binding<TodoItem>(get: { editedItem }, set: { editedItem = $0 }))
        }
        .navigationBarTitle("To Do")
        .navigationBarItems(trailing: Button(action: addItem) {
            Image(systemName: "plus")
                .padding(6)
                .background(Color.red)
        })
    }

    func addItem() {
        let addedItem = TodoItem(context: self.moc)
        addedItem.title = ""
        addedItem.details = ""
        addedItem.done = false
        addedItem.createDate = Date()

        self.addedItem = addedItem
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

struct ContentView: View {
    var body: some View {
        NavigationView {
            TodoList()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
