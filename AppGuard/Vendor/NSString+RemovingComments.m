//
//  NSString+RemovingComments.m
//  AppGuard
//
//  Created by 周和生 on 2018/3/7.
//  Copyright © 2018年 GoodDay. All rights reserved.
//

/*
 https://stackoverflow.com/questions/4568410/match-comments-with-regex-but-not-inside-a-quote
 
 You can have a regexp to match all strings and comments at the same time. If it's a string, you can replace it with itself, unchanged, and then handle a special case for comments.
 I came up with this regex:
 "(\\[\s\S]|[^"])*"|'(\\[\s\S]|[^'])*'|(\/\/.*|\/\*[\s\S]*?\*\/)
 There are 3 parts:
 "(\\[\s\S]|[^"])*" for matching double quoted strings.
 '(\\[\s\S]|[^'])*' for matching single quoted strings.
 (\/\/.*|\/\*[\s\S]*?\*\/) for matching both single line and multiline comments.
 The replace function check if the matched string is a comment. If it's not, don't replace. If it is, replace " and '.
 */

#import "RegExCategories.h"
#import "NSString+RemovingComments.h"

@implementation NSString(RemovingComments)

- (NSString *)stringByRemovingComments {
    NSString *pattern = @"\"(\\\\[\\s\\S]|[^\"])*\"|'(\\\\[\\s\\S]|[^'])*'|(\\/\\/.*|\\/\\*[\\s\\S]*?\\*\\/)";
    
    return [RX(pattern) replace:self withBlock:^NSString *(NSString *match) {
        // match如果是：/*或者//，删除
        // match是："或者'，不变
        if ([match hasPrefix:@"/"]) {
            MYLog(@"stringByRemovingComments remove: `%@`", match);
            return @"";
        } else {
            return match;
        }
    }];
}

@end
