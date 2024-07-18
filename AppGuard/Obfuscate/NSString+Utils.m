//
//  NSString+Utils.m
//  AppGuard
//
//  Created by 周和生 on 15/11/4.
//  Copyright © 2015年 GoodDay. All rights reserved.
//


#import "NSString+Utils.h"

@implementation NSString(Utils)


- (NSString *)backupPath {
 
    NSAssert(![self isBackupPath], @"you cannot create backup path for a backup path");
    
    BOOL isBundleFile = NO;
    
    NSArray *components = [self pathComponents];
    NSMutableArray *backupComponents = [NSMutableArray array];
    for (NSString *component in components) {
        
        NSString *extension = [component pathExtension];
        if ([extension isEqualToString:@"bundle"]) {
            isBundleFile = YES;
            NSString *bc = [[[component stringByDeletingPathExtension] stringByAppendingString:@"_"] stringByAppendingPathExtension:extension];
            [backupComponents addObject: bc];
            MYLog(@"bundle: %@", component);
        } else {
            [backupComponents addObject:component];
        }
    }
    
    if (isBundleFile) {
        return [NSString pathWithComponents:backupComponents];
    } else {
        return [self stringByAppendingString:@"_"];
    }
}

- (BOOL)isBackupPath {
    BOOL isBundleFile = NO;
    
    NSArray *components = [self pathComponents];
    for (NSString *component in components) {
        
        NSString *extension = [component pathExtension];
        if ([extension isEqualToString:@"bundle"]) {
            isBundleFile = YES;
            NSString *bc = [component stringByDeletingPathExtension];
            if ([bc hasSuffix:@"_"]) {
                return YES;
            }
        }
    }
    
    if (isBundleFile) {
        return NO;
    } else {
        return [self hasSuffix:@"_"];
    }
}


@end


