//
//  ImageColorOperation.h
//  AppGuard
//
//  Created by 周和生 on 15/11/4.
//  Copyright © 2015年 GoodDay. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    
    ImageObfuscatingMethodPixel,
    ImageObfuscatingMethodColor,

} ImageObfuscatingMethod;

@interface ImageColorOperation : NSOperation

@property (nonatomic, strong) NSArray *projectFiles;
@property (nonatomic, strong) NSString *workingFolder;

@property (nonatomic, strong) NSColor *pixColor;
@property (nonatomic, assign) CGFloat obfuscatingValueSaturation, obfuscatingValueBrightness, obfuscatingValueContrast;
@property (nonatomic, assign) ImageObfuscatingMethod obfuscatingMethod;

@end
