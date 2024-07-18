//
//  StringsOrderOperation.m
//  AppGuard
//
//  Created by 周和生 on 15/11/5.
//  Copyright © 2015年 GoodDay. All rights reserved.
//
#import "NSString+Utils.h"
#import "NSString+RemovingComments.h"
#import "StringsOrderOperation.h"
#import "RegExCategories.h"

@implementation StringsOrderOperation

- (void)main {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    for (NSDictionary *projectFile in self.projectFiles) {
        if (self.isCancelled) {
            MYLog(@"operation cancelled");
            break;
        }
        // Only support "Localizable.strings"
        if ([projectFile[@"extension"] isEqualToString:@"strings"] && [projectFile[@"filename"] isEqualToString:@"Localizable"]) {
            NSString *path = projectFile[@"path"];
            NSArray *pathComponents = [path pathComponents];
            if (pathComponents.count>1) {
                NSString *language = [pathComponents[pathComponents.count-2] stringByDeletingPathExtension];
                // todo: handle Base
                // if ([language isEqualToString:@"Base"]) {
                //     language = @"en";
                // }
                NSDictionary *dict = [self covertStrings:projectFile save:NO];
                NSMutableDictionary *languageDict = result[language];
                if (languageDict==nil) {
                    languageDict = [NSMutableDictionary dictionary];
                }
                [languageDict addEntriesFromDictionary:dict];
                result[language] = languageDict;
            }
        }
    }
    
    NSLog(@"StringsOrderOperation finished");
    if (self.delegate && [self.delegate respondsToSelector:@selector(didCollectStrings:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate didCollectStrings:result];
        });
    }
}

- (NSDictionary *)covertStrings:(NSDictionary *)dict save:(BOOL)save {
    NSMutableDictionary *mdict = [NSMutableDictionary dictionary];
    NSString *path = dict[@"path"];
    
    if ([path isBackupPath] && save) {
        MYLog(@"not convert BACKUP string %@", path);
        return mdict;
    }
    
    NSString *bakPath = [path backupPath];

    NSStringEncoding encoding;
    NSError *error;
    NSString *_fileContent;
    if ([[NSFileManager defaultManager]fileExistsAtPath:bakPath]) {
        _fileContent = [[NSString alloc] initWithContentsOfFile:bakPath
                                                   usedEncoding:&encoding
                                                          error:&error];
    } else {
        _fileContent = [[NSString alloc] initWithContentsOfFile:path
                                                   usedEncoding:&encoding
                                                          error:&error];
    }
    
    NSString *fileContent = [_fileContent stringByRemovingComments];
    
    if (fileContent) {
        NSArray *_lines = [fileContent componentsSeparatedByString:@"\n"];
        MYLog(@"file %@ line count %ld, encoding %ld", path ,_lines.count, (long)encoding);
        NSMutableArray *lines = [NSMutableArray array];
        NSUInteger lineNo = 0;
        for (NSString *line in _lines) {
            lineNo++;
            NSString *lineContent = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (lineContent.length) {
                NSString *pattern = @"^\".*\"\\s*=\\s*\".*\"\\s*;";
                NSArray* matches = [RX(pattern) matches:lineContent];
                if (matches.count) {
                    [lines addObjectsFromArray:matches];
                } else {
                    NSLog(@"badline `%@`, file %@, line %@", line, path, @(lineNo));
                    NSAssert(NO, @"fix badline and run");
                }
            } else {
                NSLog(@"skip line = `%@`", lineContent);
            }
        }
        
        NSUInteger count = [lines count];
        if (count) {
            if (save) {
                for (NSUInteger i = 0; i < count; ++i) {
                    NSUInteger nElements = count - i;
                    NSUInteger n = (arc4random() % nElements) + i;
                    [lines exchangeObjectAtIndex:i withObjectAtIndex:n];
                }
                
                NSString *result = [lines componentsJoinedByString:@"\n"];
                
                // 只保存最原始版本
                if (![[NSFileManager defaultManager]fileExistsAtPath:bakPath isDirectory:nil]) {
                    [[NSFileManager defaultManager]moveItemAtPath:path toPath:bakPath error:nil];
                }
                [result writeToFile:path atomically:YES encoding:encoding error:nil];
            } else {
                // 保存到字典中
                for (NSString *_line in lines) {
                    NSString *pattern = @"\"(\\\\[\\s\\S]|[^\"])*\"";
                    NSArray* matches = [RX(pattern) matches:_line];
                    if (matches.count==2) {
                        NSString *key = matches.firstObject;
                        NSString *value = matches.lastObject;
                        mdict[[key substringWithRange:NSMakeRange(1, key.length-2)]] = [value substringWithRange:NSMakeRange(1, value.length-2)];
                    }
                }
            }
        }
    } else {
        NSLog(@"not read %@", path);
    }
    
    return mdict;
}




@end
