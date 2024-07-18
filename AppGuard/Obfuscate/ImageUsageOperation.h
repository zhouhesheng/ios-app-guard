//
//  ImageUsageOperation.h
//  AppGuard
//
//  Created by 周和生 on 15/12/1.
//  Copyright © 2015年 GoodDay. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageUsageOperation : NSOperation

@property (nonatomic, strong) NSArray *projectFiles;
@property (nonatomic, strong) NSString *workingFolder;

@end
