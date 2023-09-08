//
//  DataController.swift
//  VirtualTourist
//
//  Created by Guido Roos on 16/08/2023.
//

import CoreData
import Foundation

class DataController {
    private let persistentContainer: NSPersistentContainer
    static let shared = DataController(modelName: "VirtualTourist")

    @MainActor
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    @MainActor(unsafe)
    private let backgroundContext: NSManagedObjectContext

    init(modelName: String) {
        self.persistentContainer = NSPersistentContainer(name: modelName)
        self.backgroundContext = persistentContainer.newBackgroundContext()
    }

    @MainActor func configureContexts() {
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true

        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }

    @MainActor func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { _, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            Task {
                await self.autoSaveViewContext()
            }

            self.configureContexts()
            completion?()
        }
    }
}

// MARK: - Autosaving

extension DataController {
    private func autoSaveViewContext(interval: TimeInterval = 30) async {
        print("autosaving")

        guard interval > 0 else {
            print("cannot set negative autosave interval")
            return
        }

        while true {
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            if await viewContext.hasChanges {
                do {
                    try await viewContext.save()
                } catch {
                    print("failed to autosave view context: \(error)")
                }
            }
        }
    }
}

// MARK: - CRUD Operations

extension DataController {
    func create<T: NSManagedObject>(_: T.Type) async throws -> T {
        let object = T(context: backgroundContext)
        return try await save(object)
    }

    @MainActor
    func read<T: NSManagedObject>(_: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) async throws -> [T] {
        let request = T.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        var objects: [T] = []
        try await backgroundContext.perform {
            objects = try self.backgroundContext.fetch(request) as! [T]
        }
        return objects
    }

    func update<T: NSManagedObject>(_ object: T) async throws -> T {
        return try await save(object)
    }

    func delete<T: NSManagedObject>(_ object: T) async throws {
        try await backgroundContext.perform {
            self.backgroundContext.delete(object)
            try self.backgroundContext.save()
        }
    }

    @MainActor
    func deleteObjects<T: NSManagedObject>(_ entityType: T.Type, predicate: NSPredicate? = nil) async throws {
        let entityName = String(describing: entityType)
        
        try await backgroundContext.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            fetchRequest.predicate = predicate

            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            try self.backgroundContext.execute(deleteRequest)
            try self.backgroundContext.save()
        }
    }

    @MainActor
    func save<T: NSManagedObject>(_ object: T) async throws -> T {
        do {
            try await backgroundContext.perform {
                try self.backgroundContext.save()
            }

            // Create a notification object with the changed objects
            let notification = Notification(
                name: .NSManagedObjectContextDidSave,
                object: backgroundContext,
                userInfo: [
                    NSInsertedObjectsKey: backgroundContext.insertedObjects,
                    NSUpdatedObjectsKey: backgroundContext.updatedObjects,
                    NSDeletedObjectsKey: backgroundContext.deletedObjects
                ]
            )

            await viewContext.perform {
                self.viewContext.mergeChanges(fromContextDidSave: notification)
            }

            return object
        } catch {
            backgroundContext.rollback()
            throw error
        }
    }
}
