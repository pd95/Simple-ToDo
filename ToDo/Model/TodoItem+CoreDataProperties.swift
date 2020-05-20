//
//  TodoItem+CoreDataProperties.swift
//  ToDo
//
//  Created by Philipp on 08.05.20.
//  Copyright © 2020 Philipp. All rights reserved.
//
//

import Foundation
import CoreData


extension TodoItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TodoItem> {
        return NSFetchRequest<TodoItem>(entityName: "TodoItem")
    }

    @NSManaged public var createDate: Date
    @NSManaged public var details: String
    @NSManaged public var done: Bool
    @NSManaged public var title: String
    @NSManaged public var isPublic: Bool
    @NSManaged public var isShared: Bool

}
