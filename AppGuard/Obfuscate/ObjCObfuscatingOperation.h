//
//  ObfuscatingOperation.h
//  AppGuard
//
//  Created by 周和生 on 15/10/27.
//  Copyright © 2015年 GoodDay. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    obfuscatingLevelHard,
    obfuscatingLevelSimple
} ObfuscatingLevel;

@interface ObjCObfuscatingOperation : NSOperation

@property (nonatomic, strong) NSArray *projectFiles;
@property (nonatomic, strong) NSString *workingFolder;

@property (nonatomic, assign) BOOL shouldProcessStoryboard;

@property (nonatomic, assign) ObfuscatingLevel obfuscatingLevel;
@end
