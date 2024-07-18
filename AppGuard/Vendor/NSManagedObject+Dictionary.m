//
//  NSManagedObject+Dictionary.m
//  AppGuard
//
//  Created by 周和生 on 15/10/27.
//  Copyright © 2015年 GoodDay. All rights reserved.
//

#import "NSManagedObject+Dictionary.h"

@implementation NSManagedObject(Dictionary)

- (NSDictionary *)attributesDictionary {
    NSArray *keys = [[[self entity] attributesByName] allKeys];
    NSDictionary *dict = [self dictionaryWithValuesForKeys:keys];
    return dict;
}

@end
