//
//  PDFConvertingOperation.m
//  AppGuard
//
//  Created by 周和生 on 16/1/15.
//  Copyright © 2016年 GoodDay. All rights reserved.
//

#import "PDFConvertingOperation.h"
#import "ObfuscatingManager.h"

@implementation PDFConvertingOperation

- (void)main {
    
    
    for (NSDictionary *projectFile in self.projectFiles) {
        if (self.isCancelled) {
            MYLog(@"operation cancelled");
            break;
        }
        
        [self convertPDF:projectFile];
    }
    
    NSLog(@"PDFConvertingOperation finished");
}

- (void)convertPDF: (NSDictionary *)projectFile {
    MYLog(@"convertPDF %@", projectFile);
    NSString *pdfPath = projectFile[@"path"];
    NSString *pdfName = [pdfPath lastPathComponent];
    
    // check if is imageset and has Contents.json
    NSString *imagesetPath = [pdfPath stringByDeletingLastPathComponent];
    NSString *contentsJsonPath = [imagesetPath stringByAppendingPathComponent:@"Contents.json"];
    if ([imagesetPath.pathExtension isEqualToString:@"imageset"] && [[NSFileManager defaultManager] fileExistsAtPath:contentsJsonPath]) {
        NSString *jsonString = [NSString stringWithContentsOfFile:contentsJsonPath encoding:NSUTF8StringEncoding error:nil];
        NSDictionary *dict = JSON_OBJECT_WITH_STRING(jsonString);
        if ([[dict valueForKeyPath:@"images.filename"] containsObject:pdfName]) {
            MYLog(@"PDF used in %@", jsonString);
            
            NSMutableDictionary *mDict = [dict mutableCopy];
            NSMutableArray *mArray = [NSMutableArray array];
            for (NSDictionary *fdict in dict[@"images"]) {
                NSString *filename = fdict[@"filename"];
                NSString *df = nil;
                if ([filename.pathExtension isEqualToString:@"pdf"]) {
                    NSString *source = [imagesetPath stringByAppendingPathComponent:filename];
                    df = [[filename stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"];
                    NSString *dest = [imagesetPath stringByAppendingPathComponent: df];
                    [[ObfuscatingManager shareManager]convertPDF:source toPNG:dest pages:1];
                }
                
                if (df) {
                    NSMutableDictionary *mfdict2 = [fdict mutableCopy];
                    mfdict2[@"filename"] = [NSString stringWithFormat:@"%@@2x.png", [df stringByDeletingPathExtension]];
                    mfdict2[@"scale"] = @"2x";
                    [mArray addObject:mfdict2];

                    NSMutableDictionary *mfdict3 = [fdict mutableCopy];
                    mfdict3[@"filename"] = [NSString stringWithFormat:@"%@@3x.png", [df stringByDeletingPathExtension]];
                    mfdict3[@"scale"] = @"3x";
                    [mArray addObject:mfdict3];
                } else {
                    [mArray addObject:fdict];
                }
            }
            mDict[@"images"] = mArray;
            
            // now save converted Contents.json
            jsonString = JSON_STRING_WITH_OBJ(mDict);
            [jsonString writeToFile:contentsJsonPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
            MYLog(@"writing %@, contents %@", contentsJsonPath, jsonString);
        } else {
            MYLog(@"PDF in imageset but not used!");
        }
    } else {
        MYLog(@"PDF not in imageset");
    }
}

@end
