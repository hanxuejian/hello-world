//
//  SACoreDataManage.h
//  CoreDataDemo
//
//  Created by HanXueJian on 15-11-20.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface SACoreDataManage : NSObject

//get the core data manage
+ (SACoreDataManage *)sharedCoreDataManage;

//insert a new data method
- (id)insertObjectForEntityName:(NSString *)entityName;

//save inserted data method
- (NSError *)saveInsertedObject;

//search data method
- (NSArray *)searchDataByEntityName:(NSString *)entityName andPredicateFormat:(NSString *)format;

//remove data method
- (void)removeDataByEntityName:(NSString *)entityName andPredicateFormat:(NSString *)format;

//get the object with objectID
- (id)objectWithID:(NSManagedObjectID *)objectID;

@end
