//
//  PersistenceProvider.swift
//  Vapor-Sockets
//
//  Created by Filipe Ilunga on 05/09/23.
//

import Foundation
import CoreData

final class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
   
    let container: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Vapor-Sockets")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func save() {
        do {
            try viewContext.save()
            print("salvou")
        } catch {
            print("Error on saving to CoreData: \(error.localizedDescription)")
        }
    }
}
