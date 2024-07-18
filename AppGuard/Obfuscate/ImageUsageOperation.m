//
//  ImageUsageOperation.m
//  AppGuard
//
//  Created by 周和生 on 15/12/1.
//  Copyright © 2015年 GoodDay. All rights reserved.
//

#import "ImageUsageOperation.h"
#import "NSString+Utils.h"
#import "NSString+RemovingComments.h"

@interface ImageUsageOperation ()
@property (nonatomic, strong) NSMutableArray *imageNames;

@property (nonatomic, strong) NSMutableArray *imageUsages;
@property (nonatomic, strong) NSMutableArray *simplifiedImageUsages;

@end

@implementation ImageUsageOperation


- (void)main {
    self.imageNames = [NSMutableArray new];
    self.imageUsages = [NSMutableArray new];
    
    for (NSDictionary *projectFile in self.projectFiles) {
        if (self.isCancelled) {
            MYLog(@"operation cancelled");
            break;
        }
        
        [self scanImageNameOrUsage:projectFile];
    }

    
    [self simplifiedImageUsage];
    [self searchAndAlertUnusedImages];
    [self searchAndAlertAbsentImages];
    NSLog(@"ImageUsageOperation finished");
}

- (void)scanImageNameOrUsage:(NSDictionary *)projectFile {
    NSString *path = projectFile[@"path"];
    
    NSString *imageName = [self extractImageName: path];
    if (imageName) {
        if (![self.imageNames containsObject:imageName]) {
            [self.imageNames addObject:imageName];
            MYLog(@"find image, name %@", imageName);
        }
    } else {
        [self scanImageUsage:path];
    }
    

}

- (void)simplifiedImageUsage {
    self.simplifiedImageUsages = [NSMutableArray new];
    [self.imageUsages enumerateObjectsUsingBlock:^(NSString *imageUsage, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *regStr = @"(?<=@\").*?(?=\")";
        NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regStr
                                                                                    options:0
                                                                                      error:nil];
        
        NSArray *matches = [expression matchesInString:imageUsage
                                               options:0
                                                 range:NSMakeRange(0, [imageUsage length])];
        for (NSTextCheckingResult *match in matches) {
            NSRange matchRange = [match range];
            NSString *matchString = [[[imageUsage substringWithRange:matchRange] lastPathComponent] stringByDeletingPathExtension];
            if (![self.simplifiedImageUsages containsObject:matchString]) {
                [self.simplifiedImageUsages addObject:matchString];
                MYLog(@"simplifiedImageUsage %@", matchString);
            }
        }
    }];
}

- (void)searchAndAlertUnusedImages {
    __block NSUInteger counter = 0;
    [self.imageNames enumerateObjectsUsingBlock:^(NSString *  _Nonnull imageName, NSUInteger idx, BOOL * _Nonnull stop) {

        if (![self.simplifiedImageUsages containsObject:imageName]) {
            counter++;
            NSLog(@"%ld, MAY UNUSED IMAGE: %@  ",(long)counter, imageName);
        }
    }];
}

- (void)searchAndAlertAbsentImages {
    __block NSUInteger counter = 0;
    [self.simplifiedImageUsages enumerateObjectsUsingBlock:^(NSString *  _Nonnull imageUsage, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (![self.imageNames containsObject:imageUsage]) {
            counter++;
            NSLog(@"* %ld, IMAGE NOT EXISTS: %@  ",(long)counter, imageUsage);
        }
    }];
}

- (void)scanImageUsage: (NSString *)path {
    NSURL *fileUrl = [NSURL fileURLWithPath:path];
    
    NSStringEncoding encoding;
    NSError *error;
    NSString *_fileContent = [[NSString alloc] initWithContentsOfURL:fileUrl
                                                        usedEncoding:&encoding
                                                               error:&error];
    NSAssert(_fileContent != nil, @"file content nil");
    NSString *fileContent = [_fileContent stringByRemovingComments];
    
    NSString *regStr = @"\\[\\s*UIImage\\s+\\w+\\s*:\\s*@\".*?\"\\s*\\]";  // RAWREG \[\s*UIImage\s+\w+\s*:\s*@".*?"\s*\]
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regStr
                                                                                options:0
                                                                                  error:nil];
    
    NSArray *matches = [expression matchesInString:fileContent
                                           options:0
                                             range:NSMakeRange(0, [fileContent length])];
    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = [match range];
        NSString *matchString = [fileContent substringWithRange:matchRange];
        if (![self.imageUsages containsObject:matchString]) {
            [self.imageUsages addObject:matchString];
            MYLog(@"find usage, string %@ ------- %@", matchString, path);
        }
    }
}

- (NSString *)extractImageName:(NSString *)path {
    NSArray *components = [path pathComponents];
    for (NSString *component in components) {
        NSString *ext = [component pathExtension];
        if ([ext isEqualToString:@"imageset"]) {
            NSString *fn = [component stringByDeletingPathExtension];
            return fn;
        }
    }
    
    NSString *lastComponent = [path lastPathComponent];
    NSString *ext = [lastComponent pathExtension];
    NSArray *imageExts = @[@"png", @"jpg"];
    if ([imageExts containsObject:ext.lowercaseString]) {
        NSString *fn = [lastComponent stringByDeletingPathExtension];
        fn = [fn stringByReplacingOccurrencesOfString:@"~ipad" withString:@""];
        fn = [fn stringByReplacingOccurrencesOfString:@"@2x" withString:@""];
        fn = [fn stringByReplacingOccurrencesOfString:@"@3x" withString:@""];
        return fn;
    }
    
    return nil;
}

@end
