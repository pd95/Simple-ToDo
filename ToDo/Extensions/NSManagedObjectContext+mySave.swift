//
//  NSManagedObjectContext+mySave.swift
//  ToDo
//
//  Created by Philipp on 20.05.20.
//  Copyright © 2020 Philipp. All rights reserved.
//

import CoreData

extension NSManagedObjectContext {
    func mySave(_ source: String = #function) {
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
