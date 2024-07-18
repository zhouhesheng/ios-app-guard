//
//  Node.h
//  MakeMoneyClient
//
//  Created by 周和生 on 2017/1/5.
//  Copyright © 2017年 zhouhs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Node : NSObject  < NSCopying>
@property (nonatomic, strong, readonly) NSString *nodeName;

+ (Node *)nodeWithName:(NSString *)name object:(id)object;

@property (nonatomic, strong) NSDictionary *data;
@property (nonatomic, strong) NSMutableArray<Node *> *children;

- (instancetype)initWithData:(NSDictionary *)data;
- (BOOL)isLeaf;

// for tree controller sorting

@end
