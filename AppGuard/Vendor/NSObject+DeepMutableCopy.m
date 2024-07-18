//
//  NSObject+DeepMutableCopy.m
//  AddFriends
//
//  Created by 周和生 on 2017/3/1.
//  Copyright © 2017年 FM. All rights reserved.
//

#import "NSObject+DeepMutableCopy.h"


@implementation NSString (DeepMutableCopy)

- (id)deepMutableCopy
{
    return [self mutableCopy];
}

@end

@implementation NSDate (DeepMutableCopy)

- (id)deepMutableCopy
{
    return [self copy];
}

@end

@implementation NSData (DeepMutableCopy)

- (id)deepMutableCopy
{
    return [self mutableCopy];
}

@end

@implementation NSNumber (DeepMutableCopy)

- (id)deepMutableCopy
{
    return [self copy];
}

@end

@implementation NSNull (DeepMutableCopy)

- (id)deepMutableCopy
{
    return [NSNull null];
}
@end

@implementation NSDictionary (DeepMutableCopy)

- (id)deepMutableCopy
{
    NSMutableDictionary* rv = [[NSMutableDictionary alloc] initWithCapacity:[self count]];
    NSArray* keys = [self allKeys];
    
    for (id k in keys)
    {
        id value = [self valueForKey:k];
        if (value!=[NSNull null]) {
            if ([value respondsToSelector:@selector(deepMutableCopy)]) {
                [rv setObject:[value deepMutableCopy]
                       forKey:k];
            } else {
                [rv setObject:[value copy]
                       forKey:k];
            }
        }
    }
    
    
    return rv;
}

@end

@implementation NSArray (DeepMutableCopy)

- (id)deepMutableCopy
{
    NSUInteger n = [self count];
    NSMutableArray* rv = [[NSMutableArray alloc] initWithCapacity:n];
    
    for (int i = 0; i < n; i++)
    {
        id value = [self objectAtIndex:i];
        if (value!=[NSNull null]) {
            if ([rv respondsToSelector:@selector(deepMutableCopy)]) {
                [rv insertObject:[value deepMutableCopy]
                         atIndex:i];
            } else {
                [rv insertObject:[value copy]
                         atIndex:i];
            }
        }
    }
    
    return rv;
}

@end


