//
//  Person.h
//  Test-CoreData
//
//  Created by han on 2017/6/2.
//  Copyright © 2017年 han. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface Person : NSManagedObject

@property (nonatomic, strong) NSString *name;

@property (nonatomic, strong) NSNumber *age;

@property (nonatomic, assign) Boolean sex;




@end
