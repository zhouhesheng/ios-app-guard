//
//  NSManagedObject-Dict.h
//  AdBlocker
//
//  Created by 周和生 on 2016/11/4.
//  Copyright © 2016年 zhouhs. All rights reserved.
//
@import CoreData;
#import <Foundation/Foundation.h>

@interface NSManagedObject(NSDictionary)

- (NSDictionary *)dictionary;
- (NSMutableDictionary *)mutableDictionary;

@end
