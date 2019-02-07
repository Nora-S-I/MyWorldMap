//
//  CoreDataStack.swift
//  Virtual Tourist
//
//  Created by Norah Al Ibrahim on 1/26/19.
//  Copyright © 2019 Udacity. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack: NSObject {
    let moduleName = "MyWorldMap"
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: moduleName, withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var applicationDocumentsDirectory: NSURL = {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        }() as NSURL
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        
        let persistentStoreURL = self.applicationDocumentsDirectory.appendingPathComponent("\(moduleName).sqlite")
        do{
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: persistentStoreURL, options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true])
        } catch {
            fatalError("Persistent store error \(error)")
        }
        return coordinator
    } ()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        return managedObjectContext
    }()
    
    lazy var managedBackgroundObjectContext: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        return managedObjectContext
    }()
    
    func saveContext() {
        
        managedObjectContext.performAndWait() {
            if self.managedObjectContext.hasChanges {
                do {
                    try self.managedObjectContext.save()
                } catch {
                    fatalError("Error while saving main context: \(error)")
                }
                //background save
                self.managedBackgroundObjectContext.perform() {
                    do {
                        try self.managedBackgroundObjectContext.save()
                    } catch {
                        fatalError("Error while saving persisting context: \(error)")
                    }
                }
            }
        }
    }
    
    func fetchPin(_ predicate: NSPredicate, entityName: String, sortDescriptor: NSSortDescriptor? = nil) throws -> Pin? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = predicate
        if let sortDescriptor = sortDescriptor {
            fetchRequest.sortDescriptors = [sortDescriptor]
        }
        guard let pin = (try managedObjectContext.fetch(fetchRequest) as! [Pin]).first else {
            return nil
        }
        return pin
    }
    
    func fetchAllPins(isVisited: Bool, entityName: String, sortDescriptor: NSSortDescriptor? = nil) throws -> [Pin]? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "isVisited = %@ ", NSNumber(value: isVisited))
        if let sortDescriptor = sortDescriptor {
            fetchRequest.sortDescriptors = [sortDescriptor]
        }
        guard let pin = try managedObjectContext.fetch(fetchRequest) as? [Pin] else {
            return nil
        }
        return pin
    }
    
    func deletePin(latitude: String, longitude: String) throws {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        fetchRequest.includesPropertyValues = false 
        fetchRequest.predicate = NSPredicate (format: "latitude == %@ AND longitude == %@", latitude, longitude)
        guard let fetchResults = try managedObjectContext.fetch(fetchRequest) as? [Pin] else {
            fatalError("Pin is not found")
        }
        for result in fetchResults {
            
            //delete photos assosiated with the pin before deleting the pin
            let photosFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
            photosFetchRequest.includesPropertyValues = false
            photosFetchRequest.predicate = NSPredicate (format: "pin = %@", result)
            guard let photoFetchResults = try managedObjectContext.fetch(photosFetchRequest) as? [Photo] else {
                fatalError("Pin is not found")
            }
            
            for photo in photoFetchResults {
                managedObjectContext.delete(photo)
            }
            
            managedObjectContext.delete(result)
        }
        
        saveContext()
        
    }
    
    
    func fetchPhotos(_ predicate: NSPredicate? = nil, entityName: String, sortDescriptor: NSSortDescriptor? = nil) throws -> [Photo]? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = predicate
        if let sortDescriptor = sortDescriptor {
            fetchRequest.sortDescriptors = [sortDescriptor]
        }
        guard let photos = try managedObjectContext.fetch(fetchRequest) as? [Photo] else {
            return nil
        }
        return photos
    }
    
    func addStoreCoordinator(_ storeType: String, configuration: String?, storeURL: URL, options : [NSObject:AnyObject]?) throws {
        let persistentStoreURL = self.applicationDocumentsDirectory.appendingPathComponent("\(moduleName).sqlite")
        try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: persistentStoreURL, options: nil)
    }
}

