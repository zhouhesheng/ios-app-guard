//
//  NSImage+Grayscale.h
//  ILSInstagram
//
//  Created by 周和生 on 15/7/16.
//  Copyright (c) 2015年 xiekw. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (Utils)

+ (NSImage *) imageWithColor:(NSColor *)color size:(NSSize)size;


- (void) saveWithName:(NSString*) fileName;
- (NSColor *) colorAtPoint:(NSPoint) point;

- (NSImage *)grayscaleImageWithSaturationValue:(CGFloat)saturationValue
                          brightnessValue:(CGFloat)brightnessValue
                            contrastValue:(CGFloat)contrastValue;

- (NSImage *)imageWithSaturationValue:(CGFloat)saturationValue
                 brightnessValue:(CGFloat)brightnessValue
                   contrastValue:(CGFloat)contrastValue;

- (NSImage *)imageByAddingImage:(NSImage *)image atPoint:(NSPoint)point;

- (NSImage *)grayscaleImageWithAlphaValue:(CGFloat)alphaValue
                          saturationValue:(CGFloat)saturationValue
                          brightnessValue:(CGFloat)brightnessValue
                            contrastValue:(CGFloat)contrastValue;

- (NSImage *)imageWithAlphaValue:(CGFloat)alphaValue
                 saturationValue:(CGFloat)saturationValue
                 brightnessValue:(CGFloat)brightnessValue
                   contrastValue:(CGFloat)contrastValue;

@end