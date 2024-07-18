//
//  Node.m
//  MakeMoneyClient
//
//  Created by 周和生 on 2017/1/5.
//  Copyright © 2017年 zhouhs. All rights reserved.
//

#import "Node.h"
#define _SORT_CHILDREN_   YES

@interface Node()

@end

@implementation Node

- (instancetype)initWithData:(NSDictionary *)data {
    if (self = [super init]) {
        _children = [NSMutableArray array];
        _data = data;
    }
    
    return self;
}

- (BOOL)isLeaf {
    return _children.count==0;
}

- (NSString *)nodeName {
    
    return _data[@"name"] ?: @"";
}

- (NSString *)description {
    if (_data[@"name"]) {
        if (_data[@"count"]) {
            return [NSString stringWithFormat:@"%@: %@ items", _data[@"name"], _data[@"count"]];
        } else {
            return _data[@"name"];
        }
    } else {
        return [NSString stringWithFormat:@"%@: %@", _data.allKeys.firstObject, _data.allValues.firstObject];
    }
}

- (id)copyWithZone:(NSZone*)zone
{
    Node *newNode = [[[self class] allocWithZone:zone] init];
    
    if (newNode) {
        newNode.data = [self.data copyWithZone:zone];
        newNode.children =  [self.children copyWithZone:zone];
    }
    
    return newNode;
}

+ (Node *)nodeWithName:(NSString *)name object:(id)object {
   
    if ([object isKindOfClass:[NSDictionary class]]) {
        Node *parent = [[Node alloc]initWithData:@{@"name":name}];;
        NSDictionary *dict = object;
        if (_SORT_CHILDREN_) {
            NSArray *keys = [dict.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
            for (NSString *key in keys) {
                [parent.children addObject:[Node nodeWithName:key
                                                       object:dict[key]]];
            }
        } else {
            [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                [parent.children addObject:[Node nodeWithName:key object:obj]];
            }];
        }
        return parent;
    } else if ([object isKindOfClass:[NSArray class]]) {
        NSArray *array = object;
        Node *parent = [[Node alloc]initWithData:@{@"name":name, @"count":@(array.count)}];
        [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [parent.children addObject: [Node nodeWithName:[NSString stringWithFormat:@"item %@", @(idx)]
                                                    object:obj]];
        }];
        return parent;
    } else {
        Node *leaf = [[Node alloc]initWithData:@{name:object}];
        return  leaf;
    }
}


@end
