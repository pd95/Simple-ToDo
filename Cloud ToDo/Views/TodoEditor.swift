//
//  TodoEditor.swift
//  Cloud ToDo
//
//  Created by Philipp on 13.05.20.
//  Copyright © 2020 Philipp. All rights reserved.
//

import SwiftUI

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


struct TodoEditor_Previews: PreviewProvider {
    static var previews: some View {
        TodoEditor(todo: .constant(TodoItem()))
    }
}
