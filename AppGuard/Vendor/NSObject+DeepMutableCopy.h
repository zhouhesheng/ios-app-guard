//
//  NSObject+DeepMutableCopy.h
//  AddFriends
//
//  Created by 周和生 on 2017/3/1.
//  Copyright © 2017年 FM. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (DeepMutableCopy)
- (id)deepMutableCopy;
@end

@interface NSDate (DeepMutableCopy)
- (id)deepMutableCopy;
@end

@interface NSData (DeepMutableCopy)
- (id)deepMutableCopy;
@end

@interface NSNumber (DeepMutableCopy)
- (id)deepMutableCopy;
@end

@interface NSDictionary (DeepMutableCopy)
- (id)deepMutableCopy;
@end

@interface NSArray (DeepMutableCopy)
- (id)deepMutableCopy;
@end


@interface NSNull (DeepMutableCopy)
- (id)deepMutableCopy;
@end
