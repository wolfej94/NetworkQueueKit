//
//  QueueData.swift
//
//  Created by James Wolfe on 12/01/2024.
//

import CoreData

/// A class for managing Core Data operations for the 'Queue' entity.
internal final class QueueData: NSObject {

    // MARK: - Variables
    /// Shared instance of the QueueData class.
    static let shared: QueueData = .init()

    /// Background context for Core Data operations.
    private var backgroundContext: NSManagedObjectContext!

    /// Main context for Core Data operations.
    private(set) var mainContext: NSManagedObjectContext!

    // MARK: - Core Data Container
    /// The persistent container for Core Data operations.
    lazy var container: NSPersistentContainer = {
        guard let modelURL = Bundle.module.url(forResource: "Queue", withExtension:"momd") else {
                fatalError("Error loading model from bundle")
        }

        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }

        let container = NSPersistentContainer(name: "Queue", managedObjectModel: mom)
        let dataBaseUrl = URL.applicationSupportDirectory.appendingPathComponent("Queue.sqlite")
        
        // Set file protection attributes
        if FileManager.default.fileExists(atPath: dataBaseUrl.path) {
            do {
                try FileManager.default.setAttributes(
                    [FileAttributeKey.protectionKey: FileProtectionType.complete],
                    ofItemAtPath: dataBaseUrl.path
                )
            } catch {
                fatalError("Failed to protect existing database file: \(error) at: \(dataBaseUrl)")
            }
        }

        let description = NSPersistentStoreDescription(url: dataBaseUrl)
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true
        description.setOption(FileProtectionType.complete as NSObject, forKey: NSPersistentStoreFileProtectionKey)
        container.persistentStoreDescriptions = [description]

        // Load persistent stores
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Error loading persistent store: \(error), \(error.userInfo)")
            }
        }

        return container
    }()
    
    // MARK: - Initializers
    /// Private initializer to enforce singleton pattern.
    private override init() {
        super.init()

        // Initialize contexts
        backgroundContext = container.newBackgroundContext()
        mainContext = container.viewContext

        // Merge changes from background to main context
        NotificationCenter.default.addObserver(forName: NSManagedObjectContext.didSaveObjectsNotification, object: nil, queue: .main) { notification in
            switch notification.object as? NSManagedObjectContext {
            case self.backgroundContext:
                self.mainContext.mergeChanges(fromContextDidSave: notification)
            default:
                break
            }
        }
    }

    // MARK: - CRUD Operations
    /// Creates a new object of the specified type in Core Data.
    internal func createObject<T>() async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            mainContext.perform { [weak self] in
                do {
                    guard let self = self else { fatalError("Reference lost for core data service singleton") }
                    let entityName = String(describing: T.self)
                    let object = NSEntityDescription.insertNewObject(forEntityName: entityName, into: self.mainContext) as! T
                    try self.mainContext.save()
                    continuation.resume(returning: object)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Fetches objects of the specified type from Core Data based on the provided predicate and sort descriptors.
    func fetchObjects<T: NSManagedObject>(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor] = []) async throws -> [T] {
        return try await withCheckedThrowingContinuation { continuation in
            let fetchRequest = NSFetchRequest<T>(entityName: String(describing: T.self))
            fetchRequest.predicate = predicate
            fetchRequest.sortDescriptors = sortDescriptors
            do {
                let objects = try mainContext.fetch(fetchRequest)
                continuation.resume(returning: objects)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Updates the specified object in Core Data using the provided actions block.
    func updateObject<T: NSManagedObject>(object: T, actions: (T?) -> Void) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            backgroundContext.performAndWait {
                let backgroundObject = self.backgroundContext.object(with: object.objectID) as? T
                do {
                    actions(backgroundObject)
                    try self.backgroundContext.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Deletes the specified object from Core Data.
    func deleteObject<T: NSManagedObject>(_ object: T) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            mainContext.perform {
                self.mainContext.delete(object)
                do {
                    try self.mainContext.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
}
