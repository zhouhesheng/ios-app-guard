//
//  NSImage+Grayscale.m
//  ILSInstagram
//
//  Created by 周和生 on 15/7/16.
//  Copyright (c) 2015年 xiekw. All rights reserved.
//

#import "NSImage+Utils.h"
#import <QuartzCore/QuartzCore.h>
@import CoreImage;

// s:1
// b:0
// c:1

@implementation NSImage (Utils)

+ (NSImage *) imageWithColor:(NSColor *)color size:(NSSize)size
{
    NSImage *image = [[NSImage alloc] initWithSize:size];
    [image lockFocus];
    [color setFill];
    [NSBezierPath fillRect:NSMakeRect(0, 0, size.width, size.height)];
    [image unlockFocus];
    return image;
}



- (NSColor *) colorAtPoint:(NSPoint) point {
    NSBitmapImageRep* imageRep = [[NSBitmapImageRep alloc] initWithData:[self TIFFRepresentation]];
    NSSize pixelSize = NSMakeSize(imageRep.pixelsWide, imageRep.pixelsHigh);
    NSSize imageSize = imageRep.size;
    NSColor* color = [imageRep colorAtX:point.x*pixelSize.width/imageSize.width y:point.y*pixelSize.height/imageSize.height];
    return color;
}


- (void) saveWithName:(NSString*) fileName
{
    // Cache the reduced image
    NSData *imageData = [self TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    if ([fileName.pathExtension isEqualToString:@"jpg"]) {
        imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
    } else {
        imageData = [imageRep representationUsingType:NSPNGFileType properties:imageProps];
    }
    [imageData writeToFile:fileName atomically:NO];
}

- (NSImage *)imageByAddingImage:(NSImage *)image atPoint:(NSPoint)point {
    
    CIFilter *filter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    CIImage *background = [CIImage imageWithData:[self TIFFRepresentation]];
    CIImage *inputImage = [CIImage imageWithData:[image TIFFRepresentation]];
    
    [filter setValue:background forKey:kCIInputBackgroundImageKey];
    [filter setValue:inputImage forKey:kCIInputImageKey];
    
    CIImage *outputImage = [filter outputImage];
    NSImage *resultImage = [[NSImage alloc] initWithSize:[outputImage extent].size];
    NSCIImageRep *rep = [NSCIImageRep imageRepWithCIImage:outputImage];
    [resultImage addRepresentation:rep];
    
    return resultImage;
}



- (NSImage *)grayscaleImageWithSaturationValue:(CGFloat)saturationValue
                          brightnessValue:(CGFloat)brightnessValue
                            contrastValue:(CGFloat)contrastValue
{
    CIFilter *monochromeFilter = [CIFilter filterWithName:@"CIColorMonochrome"];
    [monochromeFilter setDefaults];
    [monochromeFilter setValue:[CIImage imageWithData:[self TIFFRepresentation]] forKey:@"inputImage"];
    [monochromeFilter setValue:[CIColor colorWithRed:0 green:0 blue:0 alpha:1] forKey:@"inputColor"];
    [monochromeFilter setValue:[NSNumber numberWithFloat:1] forKey:@"inputIntensity"];
    
    CIFilter *colorFilter = [CIFilter filterWithName:@"CIColorControls"];
    [colorFilter setDefaults];
    [colorFilter setValue:[monochromeFilter valueForKey:@"outputImage"] forKey:@"inputImage"];
    [colorFilter setValue:[NSNumber numberWithFloat:saturationValue]  forKey:@"inputSaturation"];
    [colorFilter setValue:[NSNumber numberWithFloat:brightnessValue] forKey:@"inputBrightness"];
    [colorFilter setValue:[NSNumber numberWithFloat:contrastValue] forKey:@"inputContrast"];
    
    CIImage *outputImage = [colorFilter valueForKey:@"outputImage"];
    NSImage *resultImage = [[NSImage alloc] initWithSize:[outputImage extent].size];
    NSCIImageRep *rep = [NSCIImageRep imageRepWithCIImage:outputImage];
    [resultImage addRepresentation:rep];
    
    return resultImage;
}

- (NSImage *)imageWithSaturationValue:(CGFloat)saturationValue
                 brightnessValue:(CGFloat)brightnessValue
                   contrastValue:(CGFloat)contrastValue
{
    
    CIFilter *colorFilter = [CIFilter filterWithName:@"CIColorControls"];
    [colorFilter setDefaults];
    [colorFilter setValue:[CIImage imageWithData:[self TIFFRepresentation]] forKey:@"inputImage"];
    [colorFilter setValue:[NSNumber numberWithFloat:saturationValue]  forKey:@"inputSaturation"];
    [colorFilter setValue:[NSNumber numberWithFloat:brightnessValue] forKey:@"inputBrightness"];
    [colorFilter setValue:[NSNumber numberWithFloat:contrastValue] forKey:@"inputContrast"];
    
    CIImage *outputImage = [colorFilter valueForKey:@"outputImage"];
    NSImage *resultImage = [[NSImage alloc] initWithSize:[outputImage extent].size];
    NSCIImageRep *rep = [NSCIImageRep imageRepWithCIImage:outputImage];
    [resultImage addRepresentation:rep];
    
    return resultImage;
}

- (NSImage *)grayscaleImageWithAlphaValue:(CGFloat)alphaValue
                          saturationValue:(CGFloat)saturationValue
                          brightnessValue:(CGFloat)brightnessValue
                            contrastValue:(CGFloat)contrastValue
{
    NSImageRep *rep = [[self representations] objectAtIndex:0];
    NSSize size = NSMakeSize(rep.pixelsWide, rep.pixelsHigh);
    NSRect bounds = { NSZeroPoint, size };
    NSImage *tintedImage = [[NSImage alloc] initWithSize:size];
    
    [tintedImage lockFocus];
    
    CIFilter *monochromeFilter = [CIFilter filterWithName:@"CIColorMonochrome"];
    [monochromeFilter setDefaults];
    [monochromeFilter setValue:[CIImage imageWithData:[self TIFFRepresentation]] forKey:@"inputImage"];
    [monochromeFilter setValue:[CIColor colorWithRed:0 green:0 blue:0 alpha:1] forKey:@"inputColor"];
    [monochromeFilter setValue:[NSNumber numberWithFloat:1] forKey:@"inputIntensity"];
    
    CIFilter *colorFilter = [CIFilter filterWithName:@"CIColorControls"];
    [colorFilter setDefaults];
    [colorFilter setValue:[monochromeFilter valueForKey:@"outputImage"] forKey:@"inputImage"];
    [colorFilter setValue:[NSNumber numberWithFloat:saturationValue]  forKey:@"inputSaturation"];
    [colorFilter setValue:[NSNumber numberWithFloat:brightnessValue] forKey:@"inputBrightness"];
    [colorFilter setValue:[NSNumber numberWithFloat:contrastValue] forKey:@"inputContrast"];
    
    [[colorFilter valueForKey:@"outputImage"] drawAtPoint:NSZeroPoint
                                                 fromRect:bounds
                                                operation:NSCompositeCopy
                                                 fraction:alphaValue];
    
    [tintedImage unlockFocus];
    
    return tintedImage;
}

- (NSImage *)imageWithAlphaValue:(CGFloat)alphaValue
                 saturationValue:(CGFloat)saturationValue
                 brightnessValue:(CGFloat)brightnessValue
                   contrastValue:(CGFloat)contrastValue
{
    NSImageRep *rep = [[self representations] objectAtIndex:0];
    NSSize size = NSMakeSize(rep.pixelsWide, rep.pixelsHigh);
    NSRect bounds = { NSZeroPoint, size };
    NSImage *tintedImage = [[NSImage alloc] initWithSize:size];
    
    [tintedImage lockFocus];
    
    CIFilter *colorFilter = [CIFilter filterWithName:@"CIColorControls"];
    [colorFilter setDefaults];
    [colorFilter setValue:[CIImage imageWithData:[self TIFFRepresentation]]  forKey:@"inputImage"];
    [colorFilter setValue:[NSNumber numberWithFloat:saturationValue]  forKey:@"inputSaturation"];
    [colorFilter setValue:[NSNumber numberWithFloat:brightnessValue] forKey:@"inputBrightness"];
    [colorFilter setValue:[NSNumber numberWithFloat:contrastValue] forKey:@"inputContrast"];
    
    [[colorFilter valueForKey:@"outputImage"] drawAtPoint:NSZeroPoint
                                                 fromRect:bounds
                                                operation:NSCompositeCopy
                                                 fraction:alphaValue];
    
    [tintedImage unlockFocus];
    
    return tintedImage;
}


@end
