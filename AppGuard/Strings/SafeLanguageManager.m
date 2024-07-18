//
//  SafeLanguageManager.m
//  AppGuard
//
//  Created by 周和生 on 2018/3/6.
//  Copyright © 2018年 GoodDay. All rights reserved.
//
#import "SafeLanguageManager.h"

#if !TARGET_OS_IPHONE
    #import "NSDataAdditional.h"
#else
    #import <ILSApp/NSDataAdditional.h>
#endif


static NSString *languageFilePath()
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = paths[0];
    NSString *filePath = [cacheDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"_s_%@", SFLanguageVersion]];
    return filePath;
}


@interface SafeLanguageManager()

@property (nonatomic, strong) NSDictionary *stringsDict;

@end

@implementation SafeLanguageManager

+ (instancetype)sharedManager {
    static SafeLanguageManager *__manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __manager = [[SafeLanguageManager alloc] init];
    });
    return __manager;
}


+ (NSString *)stringForKey:(NSString *)key {
    return [[SafeLanguageManager sharedManager] stringForKey:key];
}

+ (NSData *)encryptString:(NSString *)getString {
    NSData *encryptedPass = [[getString dataUsingEncoding:NSUTF8StringEncoding] ILSAES256EncryptWithKey:SFLanguageKey];
    return encryptedPass;
}

+ (void)clearCache {
    NSString *cacheFilePath = languageFilePath();
    [[NSFileManager defaultManager] removeItemAtPath:cacheFilePath error:nil];
}



+ (NSString *)decryptData:(NSData *)source {
    NSString *fk = SFLanguageKey;
    NSData *decryptedData = [source ILSAES256DecryptWithKey: fk];
    NSString *result = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    return result;
}


- (instancetype)init {
    if (self = [super init]) {
        NSDictionary *allDict;
        
        // check and load strings file
        NSString *cacheFilePath = languageFilePath();
        if ([[NSFileManager defaultManager] fileExistsAtPath:cacheFilePath]) {
            allDict = [NSKeyedUnarchiver unarchiveObjectWithFile:cacheFilePath];
        } else {
            // decrypt and save
            NSURL *url = [[NSBundle mainBundle] URLForResource:[SFLanguageFilename stringByDeletingPathExtension]
                                                 withExtension:[SFLanguageFilename pathExtension]];
            NSData *source = [NSData dataWithContentsOfURL:url];
            if (source) {
                NSString *json = [SafeLanguageManager decryptData:source];
                allDict = json?[NSJSONSerialization JSONObjectWithData: [json dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil]:nil;
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [NSKeyedArchiver archiveRootObject:allDict toFile:cacheFilePath];
                });
            }
        }
        
        NSArray *languages = allDict.allKeys;

        // check current language
        NSString *language = [NSLocale preferredLanguages].firstObject ?: @"en";
        if (![languages containsObject:language]) {
            for (NSString *_lan in languages) {
                if ([language hasPrefix:_lan]) {
                    language = _lan;
                    break;
                }
            }
        }
        
        if (language) {
            self.stringsDict = allDict[language];
        }
        
    }
    
    return self;
}



- (NSString *)stringForKey:(NSString *)key {
    if (self.stringsDict && key) {
        NSString *value = self.stringsDict[key];
        return value ?: key;
    } else {
        return key;
    }
}

@end
