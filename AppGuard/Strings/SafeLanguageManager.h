//
//  SafeLanguageManager.h
//  AppGuard
//
//  Created by 周和生 on 2018/3/6.
//  Copyright © 2018年 GoodDay. All rights reserved.
//

#define SFActive                                YES                         // 更换为 ilsconnect 参数
#define SFLanguageVersion                       @"1.0"                      // 多语言版本
#define SFLanguageKey                           @"get_repost_three"         // 密码
#define SFLanguageFilename                      @"language.bin"             // 加密文件名
#define SFLocalizedString(key, comment)         (SFActive ? [SafeLanguageManager stringForKey:key] : key)

#import <Foundation/Foundation.h>

@interface SafeLanguageManager : NSObject

+ (instancetype)sharedManager;
+ (NSString *)stringForKey:(NSString *)key;
+ (void)clearCache;

+ (NSData *)encryptString:(NSString *)getString;
+ (NSString *)decryptData:(NSData *)source;

@end
