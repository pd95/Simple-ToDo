//
//  TodoItemDetail.swift
//  Cloud ToDo
//
//  Created by Philipp on 13.05.20.
//  Copyright © 2020 Philipp. All rights reserved.
//

import SwiftUI

struct TodoItemDetail: View {
    @Environment(\.managedObjectContext) var moc
    @ObservedObject var todo: TodoItem
    @State var wasPublic: Bool = false

    var body: some View {
        Form {
            Section(header: Text("Details")) {
                TextField("Details", text: $todo.details)
                    .frame(height: 180)

                Toggle(isOn: $todo.isPublic, label: { Text("Is public") })
            }
        }
        .onAppear {
            self.wasPublic = self.todo.isPublic
        }
        .onDisappear(perform: {
            self.moc.mySave("TodoItemDetail")

            // Public state has changed: update iCloud record
            if self.todo.isPublic {
                AppDelegate.shared.persistentContainer.publishRecord(of: self.todo, completion: { _ in })
            }
            if self.wasPublic && !self.todo.isPublic {
                AppDelegate.shared.persistentContainer.unpublishRecord(of: self.todo, completion: { _ in })
            }
        })
        .navigationBarTitle(todo.title)
    }
}


struct TodoItemDetail_Previews: PreviewProvider {
    static var previews: some View {
        TodoItemDetail(todo: TodoItem())
    }
}
