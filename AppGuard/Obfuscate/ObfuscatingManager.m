//
//  ObfuscatingManager.m
//  AppGuard
//
//  Created by 周和生 on 16/1/11.
//  Copyright © 2016年 GoodDay. All rights reserved.
//

#import "ObfuscatingManager.h"

@implementation ObfuscatingManager

+ (ObfuscatingManager*) shareManager
{
    static ObfuscatingManager* _shared;
    static dispatch_once_t _token;
    dispatch_once(&_token, ^{
        _shared = [[ObfuscatingManager alloc]init];
    });
    return _shared;
}

- (NSUInteger)convertPDF: (NSString *)pdfPath toPNG: (NSString *)pngPath pages:(NSUInteger)pages {
    NSData *pdfData = [NSData dataWithContentsOfFile:pdfPath];
    NSPDFImageRep *pdfImageRep = [NSPDFImageRep imageRepWithData:pdfData];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSInteger pageCount = [pdfImageRep pageCount];
    
    NSUInteger page = 0;
    
    for( ; page < MIN(pageCount, pages) ; page++) {
        [pdfImageRep setCurrentPage:page];

        for (int factor=2; factor<=3; factor++) {
            NSSize newSize = NSMakeSize(pdfImageRep.size.width * factor,pdfImageRep.size.height * factor);
            NSImage* scaledImage = [NSImage imageWithSize:newSize flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
                [pdfImageRep drawInRect:dstRect];
                return YES;
            }];
            ILSLogImage(@"PDFImage", scaledImage);
            
            NSBitmapImageRep* pngImageRep = [NSBitmapImageRep imageRepWithData:[scaledImage TIFFRepresentation]];
            NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
            NSData *finalData = [pngImageRep representationUsingType:NSPNGFileType properties:imageProps];
            
            NSString *path = [NSString stringWithFormat:@"%@@%ldx.png", [pngPath stringByDeletingPathExtension], (long)factor] ;
            [fileManager createFileAtPath:path contents:finalData attributes:nil];
            ILSLogInfo(@"PDFImage", @"saved to %@", path);
        }
    }
    
    return page;
}

- (void)scanFolder: (NSURL *)directoryUrl {
    
    self.workingFolder = directoryUrl.path;
    
    NSArray *extensions = @[@"png", @"jpg", @"pdf", @"strings", @"m", @"h", @"xib", @"storyboard", @"classdump"];
    
    self.projectFiles = [[NSMutableArray alloc]init];
    self.assets = [[NSMutableArray alloc]init];
    NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:directoryUrl
                                                                      includingPropertiesForKeys:@[]
                                                                                         options:0
                                                                                    errorHandler:^BOOL(NSURL * _Nonnull url, NSError * _Nonnull error) {
                                                                                        NSLog(@"NSDirectoryEnumerator error %@", error);
                                                                                        return YES;
                                                                                    }];
    
    NSURL *fileOrDirectory = nil;
    while ((fileOrDirectory = [directoryEnumerator nextObject])) {
        // use file or directory
        NSArray *components = [fileOrDirectory pathComponents];
        if (![components containsObject:@"build"]) {
            NSString *extension = [fileOrDirectory pathExtension];
           
            if ([extensions containsObject:extension]) {
                
                NSMutableDictionary *mDict = [[NSMutableDictionary alloc]init];
                mDict[@"path"] = fileOrDirectory.path;
                mDict[@"folder"] = directoryUrl.path;
                mDict[@"relativepath"] = [fileOrDirectory.path substringFromIndex:directoryUrl.path.length];
                mDict[@"filename"] = [fileOrDirectory.lastPathComponent stringByDeletingPathExtension];
                mDict[@"extension"] = extension;
                mDict[@"modified"] = [NSNumber numberWithBool:NO];
                mDict[@"selected"] = [NSNumber numberWithBool:YES];
                
                [self.projectFiles addObject:mDict];
            }
            if ([extension isEqualToString:@"xcassets"]) {
                [self.assets addObject:fileOrDirectory.lastPathComponent];
            }
        } else {
            MYLog(@"====== discard building folder ====== %@", fileOrDirectory);
        }
        
    }
    
}

@end
