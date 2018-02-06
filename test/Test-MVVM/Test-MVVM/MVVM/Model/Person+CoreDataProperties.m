//
//  Person+CoreDataProperties.m
//  Test-MVVM
//
//  Created by HanXueJian on 2018/2/6.
//  Copyright © 2018年 Spring Air Lines. All rights reserved.
//

#import "Person+CoreDataProperties.h"

@implementation Person (CoreDataProperties)

+ (NSFetchRequest<Person *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Person"];
}

@dynamic name;
@dynamic sex;
@dynamic age;
@dynamic job;

@end
