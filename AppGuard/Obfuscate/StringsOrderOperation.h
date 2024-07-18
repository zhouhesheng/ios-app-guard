//
//  StringsOrderOperation.h
//  AppGuard
//
//  Created by 周和生 on 15/11/5.
//  Copyright © 2015年 GoodDay. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol StringsOrderOperationDelegate <NSObject>

- (void)didCollectStrings:(NSDictionary *)dict;

@end

@interface StringsOrderOperation : NSOperation

@property (nonatomic, strong) NSArray *projectFiles;
@property (nonatomic, strong) NSString *workingFolder;

@property (nonatomic, weak) id<StringsOrderOperationDelegate> delegate;
@end
