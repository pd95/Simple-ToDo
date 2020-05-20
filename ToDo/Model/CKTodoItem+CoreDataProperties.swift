//
//  CKTodoItem+CoreDataProperties.swift
//  ToDo
//
//  Created by Philipp on 19.05.20.
//  Copyright © 2020 Philipp. All rights reserved.
//
//

import Foundation
import CoreData


extension CKTodoItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CKTodoItem> {
        return NSFetchRequest<CKTodoItem>(entityName: "CKTodoItem")
    }

    @NSManaged public var ckRecordID: String
    @NSManaged public var ckUserID: String

}
