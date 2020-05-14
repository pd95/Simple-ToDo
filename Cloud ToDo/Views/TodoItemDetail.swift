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
    @State var fetchingState = true
    @State var isPublished = false
    @State var canPublish = true

    var body: some View {
        Form {
            Section(header: Text("Details")) {
                TextField("Details", text: $todo.details)
                    .frame(height: 180)
            }
            .onAppear {
                if self.fetchingState {
                    AppDelegate.shared.persistentContainer.isRecordPublished(of: self.todo, completion: { (result) in
                        switch result {
                            case .failure(let error):
                                print("Can't publish: \(error)")
                                self.canPublish = false
                                break;
                            case .success(let found):
                                self.isPublished = found
                        }
                        self.fetchingState = false
                    })
                }
            }
        }
        .onDisappear(perform: {
            self.moc.mySave("TodoItemDetail")
        })
        .navigationBarItems(trailing: Button(action: togglePublish, label: {
                Image(systemName: cloudButtonName)
                    .padding(4)
            })
            .opacity(canPublish ? 1.0 : 0.0)
            .environment(\.isEnabled, canPublish && !fetchingState)
        )
        .navigationBarTitle(todo.title)
    }

    var cloudButtonName: String {
        print("canPublish=\(canPublish)")
        if !canPublish {
            return "xmark"
        }
        print("fetchingState=\(fetchingState)")
        if fetchingState {
            return "icloud"
        }

        print("isPublished=\(isPublished)")
        return isPublished ? "icloud.slash" : "icloud.and.arrow.up"
    }

    func togglePublish() {
        fetchingState = true
        if isPublished {
            AppDelegate.shared.persistentContainer.unpublishRecord(of: self.todo, completion: { _ in
                self.isPublished = false
                self.fetchingState = false
            })
        }
        else {
            AppDelegate.shared.persistentContainer.publishRecord(of: self.todo, completion: { _ in
                self.isPublished = true
                self.fetchingState = false
            })
        }
    }
}


struct TodoItemDetail_Previews: PreviewProvider {
    static var previews: some View {
        TodoItemDetail(todo: TodoItem())
    }
}
