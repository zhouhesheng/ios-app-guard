//
//  PDFConvertingOperation.h
//  AppGuard
//
//  Created by 周和生 on 16/1/15.
//  Copyright © 2016年 GoodDay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PDFConvertingOperation : NSOperation

@property (nonatomic, strong) NSArray *projectFiles;
@property (nonatomic, strong) NSString *workingFolder;

@end
