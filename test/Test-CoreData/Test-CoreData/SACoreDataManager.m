//
//  SACoreDataManager.m
//  CoreDataDemo
//
//  Created by HanXueJian on 15-11-20.
//
//
#import "SACoreDataManager.h"

@interface SACoreDataManager () {
    NSManagedObjectContext *_managedObjectContext;
    NSManagedObjectModel *_managedObjectModel;
    NSPersistentStoreCoordinator *_persistentStoreCoordinator;
}

@end

@implementation SACoreDataManager

#pragma mark - get shared core data manage
+ (SACoreDataManager *)sharedCoreDataManager {
    
    static SACoreDataManager *sharedCoreDataManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCoreDataManager = [[SACoreDataManager alloc] init];
    });
    
    return sharedCoreDataManager;
}

#pragma mark - insert a new data method
- (id)insertObjectForEntityName:(NSString *)entityName {
    return [NSEntityDescription insertNewObjectForEntityForName:entityName
                                  inManagedObjectContext:[self managedObjectContext]];
}

#pragma mark - save data's changes method
- (NSError *)saveChanges {
    NSError *error = nil;
    [[self managedObjectContext] save:&error];
    return error;
}

#pragma mark - search data method
- (NSArray *)searchDataByEntityName:(NSString *)entityName andPredicateFormat:(NSString *)format {
    
    NSFetchRequest* request=[[NSFetchRequest alloc]init];
    NSEntityDescription* entity=[NSEntityDescription entityForName:entityName inManagedObjectContext:[self managedObjectContext]];
    [request setEntity:entity];
    if (format) {
        // 设定查询条件
        NSPredicate* predicate=[NSPredicate predicateWithFormat:format];
        [request setPredicate:predicate];
    }
    
    return [[self managedObjectContext] executeFetchRequest:request error:NULL];
}

#pragma mark - remove data method
- (void)removeDataByEntityName:(NSString *)entityName andPredicateFormat:(NSString *)format {
    NSArray *data = [self searchDataByEntityName:entityName andPredicateFormat:format];
    for(id object in data) {
        [[self managedObjectContext] deleteObject:object];
    }
    [self saveChanges];
}

#pragma mark - get object with object ID
- (id)objectWithID:(NSManagedObjectID *)objectID {
    return [[self managedObjectContext]objectWithID:objectID];
}

#pragma mark - get managed object context
+ (NSManagedObjectContext *)sharedContext {
    return [[self sharedCoreDataManager] managedObjectContext];
}


#pragma mark - Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext {
    
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel {
    
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Model.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSPersistentStore *persistentStore = [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error];
    if (!persistentStore) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


#pragma mark - Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


@end
