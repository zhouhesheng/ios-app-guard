//
//  ObfuscatingManager.h
//  AppGuard
//
//  Created by 周和生 on 16/1/11.
//  Copyright © 2016年 GoodDay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ObfuscatingManager : NSObject

+ (ObfuscatingManager*) shareManager;

@property (nonatomic, strong) NSMutableArray *projectFiles;
@property (nonatomic, strong) NSMutableArray *assets;
@property (nonatomic, strong) NSString *workingFolder;

- (void)scanFolder: (NSURL *)directoryUrl;
- (NSUInteger)convertPDF: (NSString *)pdfPath toPNG: (NSString *)pngPath pages:(NSUInteger)pages;

@end
