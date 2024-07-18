//
//  NSView+NibLoading.m
//  Min60
//
//  Created by Peter Paulis on 08/09/14.
//  Copyright (c) 2014 min60 s.r.o. - Peter Paulis. All rights reserved.
//

#import "NSView+NibLoading.h"

@implementation NSView (OSXBGColorExtension)
- (NSColor *) backgroundColor
{
    CGColorRef colorRef = self.layer.backgroundColor;
    if (colorRef==nil) {
        return nil;
    } else {
        NSColor *theColor = [NSColor colorWithCGColor:colorRef];
        return theColor;
    }
}

- (void) setBackgroundColor:(NSColor *)backgroundColor
{
    [self setWantsLayer:YES];
    self.layer.backgroundColor = backgroundColor.CGColor;
}
@end


@implementation NSView (NibLoading)

+ (id)loadWithClass:(Class)loadClass owner:(id)owner {
    return [NSView loadWithNibNamed:NSStringFromClass(loadClass) class:loadClass owner:owner];
}

+ (id)loadWithNibNamed:(NSString *)nibNamed class:(Class)loadClass owner:(id)owner {
    
    NSNib * nib = [[NSNib alloc] initWithNibNamed:nibNamed bundle:nil];
    
    NSArray * objects;
    if (![nib instantiateWithOwner:owner topLevelObjects:&objects]) {
        NSLog(@"Couldn't load nib named %@", nibNamed);
        return nil;
    }
    
    for (id object in objects) {
        if ([object isKindOfClass:loadClass]) {
            return object;
        }
    }
    return nil;
}

+ (BOOL)confirm:(NSString*)questionTitle withMoreInfo:(NSString*)addInfo andTheActionButtonTitle:(NSString*)actionType {
    BOOL confirmFlag = NO;
    
    NSAlert *alert = [NSAlert alertWithMessageText: questionTitle
                                     defaultButton:actionType
                                   alternateButton:@"Cancel"
                                       otherButton:nil
                         informativeTextWithFormat:@"%@",addInfo];
    [alert setAlertStyle:NSAlertStyleCritical];
    
    NSInteger button = [alert runModal];
    
    if(button == 1){
        confirmFlag = YES;
    } else {
        confirmFlag = NO;
    }
    
    return confirmFlag;
}

+ (void)alert:(NSString*)questionTitle withMoreInfo:(NSString*)addInfo {
    
    NSAlert *alert = [NSAlert alertWithMessageText: questionTitle
                                     defaultButton:@"OK"
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@"%@",addInfo];
    [alert setAlertStyle:NSAlertStyleCritical];
    [alert runModal];
}

@end
