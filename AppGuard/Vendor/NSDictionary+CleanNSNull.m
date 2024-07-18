//
//  NSDictionary+CleanNSNull.m
//  MakeMoney
//
//  Created by 周和生 on 2016/12/13.
//  Copyright © 2016年 zhouhs. All rights reserved.
//

#import "NSDictionary+CleanNSNull.h"

@implementation NSDictionary (CleanNSNull)

-(NSDictionary *)cleanNull {
    return [self dictionaryWithValuesForKeys:[[self keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
        return ![obj isEqual:[NSNull null]];
    }] allObjects]];
}

@end
