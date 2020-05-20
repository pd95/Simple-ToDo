//
//  ContentView.swift
//  ToDo
//
//  Created by Philipp on 08.05.20.
//  Copyright © 2020 Philipp. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State private var showProgressView: Bool = false

    var body: some View {
        NavigationView {
            TodoList()
        }
        .withProgressView($showProgressView)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, AppDelegate.shared.persistentContainer.viewContext)
    }
}
