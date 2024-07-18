//
//  ImageColorOperation.m
//  AppGuard
//
//  Created by 周和生 on 15/11/4.
//  Copyright © 2015年 GoodDay. All rights reserved.
//

#import "ImageColorOperation.h"
#import "NSImage+Utils.h"
#import "NSString+Utils.h"
#import "NSString+RemovingComments.h"

@implementation ImageColorOperation

- (void)main {
    if (self.pixColor) {
        NSLog(@"ImageColorOperation main start with color %@", self.pixColor);
    } else {
        NSLog(@"ImageColorOperation main start without color");
    }
    
    for (NSDictionary *projectFile in self.projectFiles) {
        if (self.isCancelled) {
            MYLog(@"operation cancelled");
            break;
        }
        
        [self covertAndSaveImage:projectFile];
    }
    NSString *savingPath = [self.workingFolder stringByAppendingPathComponent:@"obfuscated.image"];
    NSString *imageInfoContents = [NSString stringWithFormat:@"Method: %ld\nPIX color: %@\nSBC values %f %f %f\n",
                                   (long)self.obfuscatingMethod,
                                   self.pixColor.description,self.obfuscatingValueSaturation, self.obfuscatingValueBrightness,self.obfuscatingValueContrast];
    [imageInfoContents writeToFile:savingPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"ImageColorOperation finished");
}

- (void)covertAndSaveImage:(NSDictionary *)dict {
    NSString *path = dict[@"path"];
    if ([path isBackupPath]) {
        MYLog(@"not convert BACKUP image %@", path);
        return;
    }
    
    NSString *bakPath = [path backupPath];
    // 优先读取最原始版本
    NSImage *image = [[NSImage alloc]initWithContentsOfFile:bakPath] ?: [[NSImage alloc]initWithContentsOfFile:path];
    // ILSLogImage(@"source", image);
    MYLog(@"obf: %@", path);
    NSImage *result = [self covertImage:image];
    
    if (result) {
        // ILSLogImage(@"converted", result);
        // 只保存最原始版本
        if (![[NSFileManager defaultManager]fileExistsAtPath:bakPath isDirectory:nil]) {
            NSError *error = nil;
            NSString *pathDir = [bakPath stringByDeletingLastPathComponent];
            [[NSFileManager defaultManager]createDirectoryAtPath:pathDir withIntermediateDirectories:YES attributes:nil error:&error];
            
            BOOL success = [[NSFileManager defaultManager]moveItemAtPath:path toPath:bakPath error:&error];
            if (!success) {
                NSLog(@"moveItemAtPath %@", error);
            }
        }
        
        [result saveWithName:path];
    } else {
        NSLog(@"convert image error for %@", path);
    }
    

}

- (NSImage *)covertImage: (NSImage *)source {
//
//    original image
//    result = [source imageWithSaturationValue:1 brightnessValue:0 contrastValue:1];
//
    
    NSImage *result = nil;
    
    switch (self.obfuscatingMethod) {
        case ImageObfuscatingMethodPixel:
            if (self.pixColor) {
                result = [source imageByAddingImage:[NSImage imageWithColor:self.pixColor size:NSMakeSize(1, 1)]
                                            atPoint:NSMakePoint(0, 0)];
            } else {
                MYLog(@"covertImage without pixColor");
            }
            break;
            
        case ImageObfuscatingMethodColor:
            result = [source imageWithSaturationValue:self.obfuscatingValueSaturation
                                      brightnessValue:self.obfuscatingValueBrightness
                                        contrastValue:self.obfuscatingValueContrast];
            break;
            
            
        default:
            break;
    }
    
    
    
    return result;
}

@end
