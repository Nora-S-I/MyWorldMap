//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Norah Al Ibrahim on 1/29/19.
//  Copyright © 2019 Udacity. All rights reserved.
//
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var image: NSData?
    @NSManaged public var imageUrl: String?
    @NSManaged public var title: String?
    @NSManaged public var pin: Pin?

}
