//
//  DataController.swift
//  Virtual Tour
//
//  Created by Binyamin Alfassi on 06/10/2020.
//

import Foundation
import CoreData
//MARK: Implementing Data Clontroller module which in charge of persisting data
class DataController {
    //MARK: Enum & variables
    // This enum defines the strings for UserDefults keys
    enum VTUserDefaults: String {
        case hasLaunchedBefore = "Has Launched Before"
        case mapLastLocationLatitude = "Map Last Location Latitute"
        case mapLastLocationLongitude = "Map Last Location Longitude"
        case mapLastLocationLatitudeDelta = "Map Last Location Latitude Delta"
        case mapLastLocationLongitudeDelta = "Map Last Location Longitude Delta"
        case initialLocationHasSet = "Initial Location Has Set"
    }
    
    // Making sure DataController will be singletone by setting a shared instance
    static let shared = DataController(modelName: "VirtualTourDB")
    
    // Setting persistentContainer
    let persistentContainer: NSPersistentContainer
    // Setting view-context
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    // setting background context
    var backgroundContext: NSManagedObjectContext
    
    //MARK: Methods
    //Init
    init(modelName: String) {
        // Setting persistent container
        persistentContainer = NSPersistentContainer(name: modelName)
        // getting the background context
        backgroundContext = persistentContainer.newBackgroundContext()
        // Check if this is the first time that this app has launched
        checkIfFirstLaunch()
    }
    // This method sets UserDefaults values according to state of app - first launch or not
    func checkIfFirstLaunch() {
        if UserDefaults.standard.bool(forKey: VTUserDefaults.hasLaunchedBefore.rawValue) {
            print("App has launched before")
        } else {
            print("This is the first launch ever!!!")
            // Setting parameters to indicate first time launch
            UserDefaults.standard.setValue(true, forKey: VTUserDefaults.hasLaunchedBefore.rawValue)
            UserDefaults.standard.setValue(false, forKey: VTUserDefaults.initialLocationHasSet.rawValue)
            // Saving the params to UserDefaults
            UserDefaults.standard.synchronize()
        }
    }
    // Configuring the data contexts for the use of the app
    func configureContexts() {
        // setting both of the context to automaticly merge changes from parent
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        // We consider the work done on the background thread to be the authoroty of versioni nof data
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump // --> It will prefer its own data in case of a conflict
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump //It will prefer the data from persistent store in case of a conflict
    }
    // Loading Data Controller to a working state
    func load(completion: (() -> Void)? = nil) {
        // Loading persistent stores
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            // starting autosave of view context
            self.autosaveViewContexts()
            // Configuring data contexts
            self.configureContexts()
            // Calling completion method
            completion?()
        }
    }
}

//MARK: Extension implements Autosaving abilities
extension DataController {
    func autosaveViewContexts(interval: TimeInterval = 30) {
        print("Autosaving Contexts...")
        guard interval > 0 else {
            print("Cannot set negativev interval")
            return
        }
        // Checking if view context has changes and saving the changes
        if viewContext.hasChanges {
            try? viewContext.save()
        }
        // Recursivly calling the autosaving method
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autosaveViewContexts(interval: interval)
        }
    }
}
