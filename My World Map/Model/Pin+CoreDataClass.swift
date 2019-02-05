//
//  Pin+CoreDataClass.swift
//  My World Map
//
//  Created by Norah Al Ibrahim on 2/3/19.
//  Copyright © 2019 Udacity. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Pin)
public class Pin: NSManagedObject {
    
    static let name = "Pin"
    
    convenience init(latitude: String, longitude: String, isVisited: Bool, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: Pin.name, in: context) {
            self.init(entity: ent, insertInto: context)
            self.latitude = latitude
            self.longitude = longitude
            self.isVisited = isVisited
        } else {
            fatalError("Unable to find Entity name!")
        }
    }

}
