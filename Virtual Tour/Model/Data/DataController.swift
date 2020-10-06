//
//  DataController.swift
//  Virtual Tour
//
//  Created by Binyamin Alfassi on 06/10/2020.
//

import Foundation
import CoreData

class DataController {
    enum VTUserDefaults: String {
        case hasLaunchedBefore = "Has Launched Before"
        case mapLastLocationLatitude = "Map Last Location Latitute"
        case mapLastLocationLongitude = "Map Last Location Longitude"
        case mapLastLocationLatitudeDelta = "Map Last Location Latitude Delta"
        case mapLastLocationLongitudeDelta = "Map Last Location Longitude Delta"
        case initialLocationHasSet = "Initial Location Has Set"
    }
    
    static let shared = DataController(modelName: "VirtualTourDB")
    
    let persistentContainer: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    var backgroundContext: NSManagedObjectContext
    
    init(modelName: String) {
        persistentContainer = NSPersistentContainer(name: modelName)
        backgroundContext = persistentContainer.newBackgroundContext()
        checkIfFirstLaunch()
    }
    
    func checkIfFirstLaunch() {
        if UserDefaults.standard.bool(forKey: VTUserDefaults.hasLaunchedBefore.rawValue) {
            print("App has launched before")
        } else {
            print("This is the first launch ever!!!")
            UserDefaults.standard.setValue(true, forKey: VTUserDefaults.hasLaunchedBefore.rawValue)
            UserDefaults.standard.setValue(false, forKey: VTUserDefaults.initialLocationHasSet.rawValue)
            
            UserDefaults.standard.synchronize()
        }
    }
    
    func configureContexts() {
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        // We consider the work done on the background thread to be the authoroty of versioni nof data
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump // --> It will prefer its own data in case of a conflict
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump //It will prefer the data from persistent store in case of a conflict
    }
    
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            self.autosaveViewContexts()
            self.configureContexts()
            completion?()
        }
    }
}

extension DataController {
    func autosaveViewContexts(interval: TimeInterval = 30) {
        print("Autosaving Contexts...")
        guard interval > 0 else {
            print("Cannot set negativev interval")
            return
        }
        if viewContext.hasChanges {
            try? viewContext.save()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autosaveViewContexts(interval: interval)
        }
    }
}
