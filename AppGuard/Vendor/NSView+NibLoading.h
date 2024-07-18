//
//  NSView+NibLoading.h
//  Min60
//
//  Created by Peter Paulis on 08/09/14.
//  Copyright (c) 2014 min60 s.r.o. - Peter Paulis. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSView (OSXBGColorExtension)
@property (nonatomic, weak) NSColor *backgroundColor;
@end


@interface NSView (NibLoading)

+ (id)loadWithClass:(Class)loadClass owner:(id)owner;
+ (id)loadWithNibNamed:(NSString *)nibNamed class:(Class)loadClass owner:(id)owner;

+ (BOOL)confirm:(NSString*)questionTitle withMoreInfo:(NSString*)addInfo andTheActionButtonTitle:(NSString*)actionType;
+ (void)alert:(NSString*)questionTitle withMoreInfo:(NSString*)addInfo;

@end
