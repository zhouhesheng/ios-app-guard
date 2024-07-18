//
//  NSDataAdditional.h
//  MSN
//
//  Created by Jiqun Zheng on 3/23/10.
//  Copyright 2010 iLegendSoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (ILS_AES256)
//
// MAY CONFLICT WITH OTHER LIBS, WILL NOT USE ANYMORE
//
- (NSData *)AES256EncryptWithKey:(NSString *)key __deprecated;
- (NSData *)AES256DecryptWithKey:(NSString *)key __deprecated;

- (NSData *)AES256EncryptWithKey:(NSString *)key ifPKCS7Padding:(BOOL)padding7 __deprecated;
- (NSData *)AES256DecryptWithKey:(NSString *)key ifPKCS7Padding:(BOOL)padding7 __deprecated;


- (NSData *)ILSAES256EncryptWithKey:(NSString *)key;
- (NSData *)ILSAES256DecryptWithKey:(NSString *)key;

- (NSData *)ILSAES256EncryptWithKey:(NSString *)key ifPKCS7Padding:(BOOL)padding7;
- (NSData *)ILSAES256DecryptWithKey:(NSString *)key ifPKCS7Padding:(BOOL)padding7;

@end
