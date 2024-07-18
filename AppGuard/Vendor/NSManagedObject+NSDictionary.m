//
//  NSManagedObject-Dict.m
//  AdBlocker
//
//  Created by 周和生 on 2016/11/4.
//  Copyright © 2016年 zhouhs. All rights reserved.
//

#import "NSManagedObject+NSDictionary.h"

@implementation NSManagedObject(NSDictionary)


- (NSDictionary *)dictionary {
    NSArray *keys = [[[self entity] attributesByName] allKeys];
    NSDictionary *dict = [self dictionaryWithValuesForKeys:keys];
    return dict;
}


- (NSMutableDictionary *)mutableDictionary {
    NSArray *keys = [[[self entity] attributesByName] allKeys];
    NSMutableDictionary *mdict = [[self dictionaryWithValuesForKeys:keys] mutableCopy];
    NSArray *keysForNullValues = [mdict allKeysForObject:[NSNull null]];
    [mdict removeObjectsForKeys:keysForNullValues];
    mdict[@"objectID"] = self.objectID;
    return mdict;
}

@end
