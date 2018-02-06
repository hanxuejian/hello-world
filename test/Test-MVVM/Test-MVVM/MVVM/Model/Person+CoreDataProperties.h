//
//  Person+CoreDataProperties.h
//  Test-MVVM
//
//  Created by HanXueJian on 2018/2/6.
//  Copyright © 2018年 Spring Air Lines. All rights reserved.
//

#import "Person+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Person (CoreDataProperties)

+ (NSFetchRequest<Person *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSString *sex;
@property (nullable, nonatomic, copy) NSString *age;
@property (nullable, nonatomic, copy) NSString *job;

@end

NS_ASSUME_NONNULL_END
