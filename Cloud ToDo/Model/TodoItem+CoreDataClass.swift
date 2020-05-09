//
//  TodoItem+CoreDataClass.swift
//  Cloud ToDo
//
//  Created by Philipp on 08.05.20.
//  Copyright © 2020 Philipp. All rights reserved.
//
//

import Foundation
import CoreData

@objc(TodoItem)
public class TodoItem: NSManagedObject {

}

extension TodoItem: Identifiable {
    public var id : NSManagedObjectID { self.objectID }
}
