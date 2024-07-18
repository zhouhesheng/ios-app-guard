//
//  ObfuscatingOperation.m
//  AppGuard
//
//  Created by 周和生 on 15/10/27.
//  Copyright © 2015年 GoodDay. All rights reserved.
//

#import "ILSLogger.h"
#import "ObjCObfuscatingOperation.h"
#import "UUIDShortener.h"
#import "CoreDataModelProcessor.h"
#import "StoryBoardProcessor.h"
#import "NSString+Utils.h"
#import "NSString+RemovingComments.h"

@interface ObjCObfuscatingOperation()

@property (nonatomic, strong) NSArray *disabledSymbolsForClass;
@property (nonatomic, strong) NSArray *disabledSymbolsForSelector;

@property (nonatomic, strong) NSMutableDictionary *classes;
@property (nonatomic, strong) NSMutableDictionary *classSelectors;

@property (nonatomic, strong) NSMutableArray *blackListClasses;
@property (nonatomic, strong) NSMutableArray *blackListSelectors;

@property (nonatomic, strong) NSMutableArray *protocolSelectors;
@property (nonatomic, strong) NSMutableArray *callingSuperSelectors;

@property (nonatomic, strong) NSDictionary *resultMap;

@end

@implementation ObjCObfuscatingOperation



- (void)main {
    
    MYLog(@"ObfuscatingOperation main start");
    [self configDisabled];
    self.protocolSelectors = [NSMutableArray array];
    
    self.classes = [NSMutableDictionary dictionary];
    self.classSelectors = [NSMutableDictionary dictionary];
    
    self.blackListClasses = [NSMutableArray array];
    self.blackListSelectors = [NSMutableArray array];
    self.callingSuperSelectors = [NSMutableArray array];
    
    for (NSDictionary *projectFile in self.projectFiles) {
        if (self.isCancelled) {
            MYLog(@"operation cancelled");
            break;
        }
        
        [self parseFile:projectFile];
    }
    
    if (self.isCancelled) {
        MYLog(@"operation cancelled");
    } else {
        self.resultMap = [self generateResult];
    }
    
    if (self.shouldProcessStoryboard) {
        NSLog(@"NOW PROCESS storyboard");
        StoryBoardProcessor *processer = [[StoryBoardProcessor alloc]init];
        processer.xibBaseDirectory = self.workingFolder;
        [processer obfuscateFilesUsingSymbols:self.resultMap ?: @{}];
    } else {
        NSLog(@"NOT PROCESS storyboard");
    }
    
    NSLog(@"ALL DONE");
}

- (void)parseFile:(NSDictionary *)fileInfo {
    NSString *extension = fileInfo[@"extension"];
    if ([extension isEqualToString:@"classdump"]) {
        
        [self parseProtocol: fileInfo];
        [self parseInterface: fileInfo tag:NO];
        [self parseBlacklistClassAndSelectors:fileInfo];
        
    } else if ([extension isEqualToString:@"m"]) {
        
        [self parseInterface: fileInfo tag:YES];
        [self parseImplementation: fileInfo];
        [self parseBlacklistClassAndSelectors:fileInfo];
        
    } else if ([extension isEqualToString:@"h"]) {
        
        [self parseInterface: fileInfo tag:YES];
        [self parseBlacklistClassAndSelectors:fileInfo];
        
    }
    
    
}



//
// disabledSymbolsForClass ----------  Class及所有的Selector都不处理
// disabledSymbolsForSelector
//
- (void)configDisabled {
    self.disabledSymbolsForClass = @[@"AppDelegate"];
    self.disabledSymbolsForSelector = @[@"dealloc", @"main"];
}




- (void)parseInterfaceBody: (NSString *)body tag:(BOOL)tag {
    
    NSArray *lines = [body componentsSeparatedByString:@"\n"];
    NSString *firstLine = [[lines firstObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSAssert(firstLine.length > 0, @"interface first Line length 0");
    
    NSRange categoryRange = [firstLine rangeOfString:@"\\(.*?\\)" options:NSRegularExpressionSearch];
    NSString *categoryName;
    
    if (categoryRange.location != NSNotFound) {
        // category or extension
        categoryName = [[[[firstLine substringWithRange:categoryRange] stringByReplacingOccurrencesOfString:@"(" withString:@""]stringByReplacingOccurrencesOfString:@")" withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (categoryName.length) {
            if (![self.blackListClasses containsObject:categoryName]) {
                [self.blackListClasses addObject:categoryName];
            }
            ILSLogInfo(@"Interface", @"categoryName %@", categoryName);
        }
    }
    
    
    if ([firstLine rangeOfString:@"<.*?>" options:NSRegularExpressionSearch].location != NSNotFound) {
        // protocol support
    }

    
    if ([firstLine containsString:@"<"]) {
        firstLine = [[[firstLine componentsSeparatedByString:@"<"] firstObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    if ([firstLine containsString:@"("]) {
        firstLine = [[[firstLine componentsSeparatedByString:@"("] firstObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }

    NSString *className, *superClassName;
    if ([firstLine containsString:@":"]) {
        // class & super class
        NSArray *words = [firstLine componentsSeparatedByString:@":"];
        NSAssert(words.count==2, @"class and superclass");
        className = [[words firstObject]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        superClassName = [[words lastObject]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([superClassName isEqualToString:@"NSManagedObject"]) {
            [self.blackListClasses addObject:className];
        }
    } else {
        className = [firstLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }

    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: self.classes[className]];
    
    if (superClassName.length) {
       dict[@"superclass"] = superClassName;
    }
    
    if (categoryName.length) {
        dict[@"category"] = categoryName;
    }
    
    if (tag) {
        dict[@"tag"] = @(YES);
    }
    self.classes[className] = dict;
    MYLog(@"update class `%@` dict %@", className, dict);

}


- (void)parseImplementationBody: (NSString *)body {
    NSMutableArray *lines = [NSMutableArray arrayWithArray:[body componentsSeparatedByString:@"\n"]];
    NSString *firstLine = [[lines firstObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSAssert(firstLine.length > 0, @"implementation first Line length 0");

    if ([firstLine containsString:@"{"]) {
        firstLine = [[[firstLine componentsSeparatedByString:@"{"] firstObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    
    NSString *categoryName;
    NSRange cRange = [firstLine rangeOfString:@"\\(.*?\\)" options:NSRegularExpressionSearch];
    if (cRange.location != NSNotFound) {
        NSString *c = [[[[firstLine substringWithRange:cRange] stringByReplacingOccurrencesOfString:@"(" withString:@""]stringByReplacingOccurrencesOfString:@")" withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (c.length) {
            categoryName = c;
            if (![self.blackListSelectors containsObject:categoryName]) {
                [self.blackListSelectors addObject:categoryName];
            }
           ILSLogInfo(@"Implementation", @"categoryName %@", categoryName);
        } else {
            categoryName = nil;
        }
        
        firstLine = [[[firstLine componentsSeparatedByString:@"("] firstObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }

    NSString *currentClassName = [firstLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSLog(@"class name %@", currentClassName);
    MYLog(@"parsing class %@ implementation for selectors ...", currentClassName);
    [lines removeObjectIdenticalTo: lines.firstObject];
    NSMutableDictionary *selectorsDict = [NSMutableDictionary dictionaryWithDictionary:self.classSelectors[currentClassName]];
    
    NSString *currentSelectorName = nil;
    NSMutableDictionary *currentSelectorDict = nil;

    for (NSString *line in lines) {
        NSString *aLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([aLine hasPrefix:@"-"] || [aLine hasPrefix:@"+"]) {
            //parse selector
            NSString *regstr = @"(?<=\\))\\s*.*?(?=[\\s:;{]|$)";
            NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regstr
                                                                                        options:0
                                                                                          error:nil];
            NSArray *matches = [expression matchesInString:aLine
                                                   options:0
                                                     range:NSMakeRange(0, [aLine length])];
            NSTextCheckingResult *match = [matches firstObject];
            NSRange matchRange = [match range];
            NSString *matchString = [[aLine substringWithRange:matchRange] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSLog(@"selector name %@, line `%@`", matchString, aLine);
            if (matchString.length) {
                currentSelectorName = matchString;
                MYLog(@"updating class `%@` selector `%@`", currentClassName, currentSelectorName);
                currentSelectorDict = [NSMutableDictionary dictionaryWithDictionary: selectorsDict[currentSelectorName]];
                if (categoryName) {
                    currentSelectorDict[@"category"] = categoryName;
                }
                
                selectorsDict[currentSelectorName] = currentSelectorDict;
            }
        }
        
        // now check calls like [super viewDidLoad];
        NSString *regStr = @"(?<=\\[super\\s)[\\s\\S]*?(?=\\])";
        NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regStr
                                                                                    options:0
                                                                                      error:nil];
        
        NSArray *matches = [expression matchesInString:aLine
                                               options:0
                                                 range:NSMakeRange(0, [aLine length])];
        if (matches.count) {
            NSAssert(currentSelectorDict!=nil && currentSelectorName!=nil, @"[super xxxx] found, selector name shoud not nil");
            currentSelectorDict[@"super"] = @YES;
        }
        for (NSTextCheckingResult *match in matches) {
            NSRange matchRange = [match range];
            NSString *matchString = [[aLine substringWithRange:matchRange] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            ILSLogInfo(@"SUPER", @"`%@` in `%@`, currentSelector `%@`", matchString, aLine, currentSelectorName);
            if ([matchString containsString:@":"]) {
                matchString = [[[matchString componentsSeparatedByString:@":"] firstObject]stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
            if (![self.callingSuperSelectors containsObject:matchString]) {
                [self.callingSuperSelectors addObject:matchString];
            }
        }
    }
    
    self.classSelectors[currentClassName] = selectorsDict;
}

- (void)parseProtocolBody: (NSString *)body {
    
    NSArray *lines = [body componentsSeparatedByString:@"\n"];
    
    for (NSString *line in lines) {
        NSString *aLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([aLine hasPrefix:@"-"] || [aLine hasPrefix:@"+"]) {
            //parse selector
            NSString *regstr = @"(?<=\\))\\s*.*?(?=[\\s:;{]|$)";
            NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regstr
                                                                                        options:0
                                                                                          error:nil];
            NSArray *matches = [expression matchesInString:aLine
                                                   options:0
                                                     range:NSMakeRange(0, [aLine length])];
            NSTextCheckingResult *match = [matches firstObject];
            NSRange matchRange = [match range];
            NSString *matchString = [[aLine substringWithRange:matchRange] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (matchString.length && ![self.protocolSelectors containsObject:matchString]) {
                [self.protocolSelectors addObject:matchString];
                MYLog(@"adding protocol selectors `%@`", matchString);
            }
        }
    }
}


- (void)parseBlacklistClassAndSelectors: (NSDictionary *)fileInfo {
    NSURL *fileUrl = [NSURL fileURLWithPath:fileInfo[@"path"]];
    NSStringEncoding encoding;
    NSError *error;
    NSString *_fileContent = [[NSString alloc] initWithContentsOfURL:fileUrl
                                                        usedEncoding:&encoding
                                                               error:&error];
    NSAssert(_fileContent != nil, @"file content nil");
    NSString *fileContent = [_fileContent stringByRemovingComments];

    [self checkFor:@"(?<=@selector\\().*?(?=\\))" inText:fileContent action:^(NSString *item) {
        ILSLogInfo(@"parseBlacklistClassAndSelectors", @"@selector %@", item);
        [self.blackListSelectors addObject: [item componentsSeparatedByString:@":"].firstObject];
    }];

    [self checkFor:@"(?<=NSSelectorFromString\\(@\").*?(?=\"\\))" inText:fileContent action:^(NSString *item) {
        ILSLogInfo(@"parseBlacklistClassAndSelectors", @"NSSelectorFromString %@", item);
        [self.blackListSelectors addObject: [item componentsSeparatedByString:@":"].firstObject];
    }];
    
    [self checkFor:@"(?<=NSClassFromString\\(@\").*?(?=\"\\))" inText:fileContent action:^(NSString *item) {
        ILSLogInfo(@"parseBlacklistClassAndSelectors", @"NSClassFromString %@", item);
        [self.blackListClasses addObject:item];
    }];
    
    
}

- (void)checkFor:(NSString *)regstr inText:(NSString *)text action:(void (^)(NSString *item))action {
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regstr
                                                                                options:0
                                                                                  error:nil];
    
    NSArray *matches = [expression matchesInString:text
                                           options:0
                                             range:NSMakeRange(0, [text length])];
    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = [match range];
        NSString *matchString = [text substringWithRange:matchRange];
        if (action) {
            action(matchString);
        }
    }
}

- (void)parseInterface: (NSDictionary *)fileInfo tag:(BOOL)tag {
    NSURL *fileUrl = [NSURL fileURLWithPath:fileInfo[@"path"]];
    NSStringEncoding encoding;
    NSError *error;
    NSString *_fileContent = [[NSString alloc] initWithContentsOfURL:fileUrl
                                                        usedEncoding:&encoding
                                                               error:&error];
    NSAssert(_fileContent != nil, @"file content nil");
    NSString *fileContent = [_fileContent stringByRemovingComments];
    
    NSString *regStr = @"(?<=@interface)[\\S\\s]*?(?=@end)";
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regStr
                                                                                options:0
                                                                                  error:nil];
    
    NSArray *matches = [expression matchesInString:fileContent
                                           options:0
                                             range:NSMakeRange(0, [fileContent length])];
    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = [match range];
        NSString *matchString = [fileContent substringWithRange:matchRange];
        [self parseInterfaceBody: matchString tag:tag];
    }
}

- (void)parseProtocol: (NSDictionary *)fileInfo {
    NSURL *fileUrl = [NSURL fileURLWithPath:fileInfo[@"path"]];
    NSStringEncoding encoding;
    NSError *error;
    NSString *_fileContent = [[NSString alloc] initWithContentsOfURL:fileUrl
                                                        usedEncoding:&encoding
                                                               error:&error];
    NSAssert(_fileContent != nil, @"file content nil");
    NSString *fileContent = [_fileContent stringByRemovingComments];
    
    NSString *regProtocol = @"(?<=@protocol)[\\S\\s]*?(?=@end)";
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regProtocol
                                                           options:0
                                                             error:nil];
    
    NSArray *matches = [expression matchesInString:fileContent
                                  options:0
                                    range:NSMakeRange(0, [fileContent length])];
    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = [match range];
        NSString *matchString = [fileContent substringWithRange:matchRange];
        [self parseProtocolBody: matchString];
    }
}

- (void)parseImplementation: (NSDictionary *)fileInfo {
    NSURL *fileUrl = [NSURL fileURLWithPath:fileInfo[@"path"]];
    NSStringEncoding encoding;
    NSError *error;
    NSString *_fileContent = [[NSString alloc] initWithContentsOfURL:fileUrl
                                                        usedEncoding:&encoding
                                                               error:&error];
    NSAssert(_fileContent != nil, @"file content nil");
    NSString *fileContent = [_fileContent stringByRemovingComments];
    
    NSString *regImplementation = @"(?<=@implementation)[\\S\\s]*?(?=@end)";
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regImplementation
                                                                                options:0
                                                                                  error:nil];
    
    NSArray *matches = [expression matchesInString:fileContent
                                           options:0
                                             range:NSMakeRange(0, [fileContent length])];
    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = [match range];
        NSString *matchString = [fileContent substringWithRange:matchRange];
        [self parseImplementationBody: matchString];
    }
}

- (NSArray *)blackListFromStoryboard {
    StoryBoardProcessor *processer = [[StoryBoardProcessor alloc]init];
    processer.xibBaseDirectory = self.workingFolder;
    
    NSArray *result = processer.allObjCSymbols;
    return result;
}

- (NSDictionary *)generateResult {
    NSLog(@"Now generateResult");
    
    
    NSMutableArray *symbols = [self allSymbolsToObfuscate];
    
    [[NSFileManager defaultManager] changeCurrentDirectoryPath:self.workingFolder];
    CoreDataModelProcessor *coreDataModelProcessor = [[CoreDataModelProcessor alloc] init];
    coreDataModelProcessor.coreDataBaseDirectory = self.workingFolder;
    NSArray *coreDataBlocks = [coreDataModelProcessor coreDataModelSymbolsToExclude];
    if (coreDataBlocks.count) {
        [symbols removeObjectsInArray:coreDataBlocks];
        MYLog(@"remove coreData symbols %@", coreDataBlocks);
    }
    
    NSArray *storyboardSymbols = [self blackListFromStoryboard];
    [symbols removeObjectsInArray: storyboardSymbols];
    MYLog(@"remove storyboardSymbols symbols %@", storyboardSymbols);

    [self removeSetters:symbols];

    NSString *jsonPath = [self.workingFolder stringByAppendingPathComponent:@"obfuscated.whitelist"];
    NSString *jsonString = JSON_STRING_WITH_OBJ(symbols);
    [jsonString writeToFile:jsonPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    NSString *mapPath = [self.workingFolder stringByAppendingPathComponent:@"symbols.json"];
    NSString *mapContent = [NSString stringWithContentsOfFile:mapPath encoding:NSUTF8StringEncoding error:nil];
    NSDictionary *revDict = JSON_OBJECT_WITH_STRING(mapContent);

    if (revDict.count) {
        __block NSMutableDictionary *mapDict = [NSMutableDictionary dictionary];
        [revDict enumerateKeysAndObjectsUsingBlock:^(NSString*  _Nonnull obfValue, NSString*  _Nonnull selectorName, BOOL * _Nonnull stop) {
            switch (self.obfuscatingLevel) {
                case obfuscatingLevelHard:
                    if ([symbols containsObject:selectorName]) {
                        [mapDict setObject:obfValue forKey:selectorName];
                        if (![selectorName hasPrefix:@"_"]) {
                            [mapDict setObject:[@"_" stringByAppendingString: obfValue]
                                        forKey:[@"_" stringByAppendingString: selectorName]];
                        }
                    }
                    break;
                    
                case obfuscatingLevelSimple :
                    if ([symbols containsObject:selectorName]) {
                        NSString *simpleObfValue = [NSString stringWithFormat:@"%@_V%ld", selectorName, (long)(arc4random()%10)];
                        [mapDict setObject:simpleObfValue forKey:selectorName];
                        if (![selectorName hasPrefix:@"_"]) {
                            [mapDict setObject:[@"_" stringByAppendingString: simpleObfValue]
                                        forKey:[@"_" stringByAppendingString: selectorName]];
                        }
                    }
                    break;
                default:
                    break;
            }
            
        }];
        
        [self saveHeaderWith: mapDict];
        return mapDict;
    } else {
    
        NSMutableDictionary *mapDict = [self generateMaps:symbols];
        [self saveHeaderWith: mapDict];
        return mapDict;
    }
}

- (void)saveHeaderWith: (NSDictionary *)mapDict {
    __block NSMutableString *mString = [[NSMutableString alloc]init];
    [mapDict enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull selectorName, NSString *  _Nonnull obfuscatedName, BOOL * _Nonnull stop) {
        [mString appendFormat:@"#ifndef %@\n#define %@ %@\n#endif\n\n", selectorName, selectorName, obfuscatedName];
    }];
    
    NSString *savingPath = [self.workingFolder stringByAppendingPathComponent:@"obfuscated.h"];
    [mString writeToFile:savingPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    
    NSString *jsonPath = [self.workingFolder stringByAppendingPathComponent:@"obfuscated.json"];
    NSString *jsonString = JSON_STRING_WITH_OBJ(mapDict);
    [jsonString writeToFile:jsonPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (NSMutableDictionary *)generateMaps: (NSMutableArray *)symbols {
    __block NSMutableDictionary *mdict = [NSMutableDictionary dictionary];
    
    [symbols enumerateObjectsUsingBlock:^(NSString *  _Nonnull selectorName, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *obfuscatedName = [@"_" stringByAppendingString: [[NSUUID UUID]shortUUIDString]];
        [mdict setObject:obfuscatedName forKey:selectorName];
    }];
    
    return mdict;
}

- (void)removeSetters: (NSMutableArray *)symbols {
//    
//    handle Setter and Getter - JUST REMOVE THEM
//    symbols content is Modified
//
    __block NSMutableArray *setters = [NSMutableArray array];
    [symbols enumerateObjectsUsingBlock:^(NSString *  _Nonnull selectorName, NSUInteger idx, BOOL * _Nonnull stop) {
        if ( [selectorName hasPrefix:@"set"] && selectorName.length > 3 && 'A' <= [selectorName characterAtIndex:3] && [selectorName characterAtIndex:3] <= 'Z') {
            [setters addObject:selectorName];
        }
    }];
    MYLog(@"removed setters === %@", setters);
    
    __block NSMutableArray *getters = [NSMutableArray array];
    [setters enumerateObjectsUsingBlock:^(NSString *  _Nonnull selectorName, NSUInteger idx, BOOL * _Nonnull stop) {
        unichar ch = [selectorName characterAtIndex:3];
        NSString *getterName0 = [NSString stringWithCharacters:&ch
                                                        length:1].lowercaseString;
        NSString *getterName1 = [selectorName substringFromIndex:4];
        NSString *getterName = [getterName0 stringByAppendingString:getterName1];
        if ([symbols containsObject:getterName]) {
            if (![getters containsObject:getterName]) {
                [getters addObject:getterName];
            }
        }
    }];
    
    MYLog(@"removed getters === %@", getters);

    [symbols removeObjectsInArray: getters];
    [symbols removeObjectsInArray: setters];
}


- (NSMutableArray *)allSymbolsToObfuscate {
    
    __block NSMutableArray *symbols = [NSMutableArray array];
    
    [self.classes enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull className, NSDictionary*  _Nonnull dict, BOOL * _Nonnull stop) {
        BOOL tag = [dict[@"tag"] boolValue];
        // 只处理有源码，并且不是category的class
        NSString *category = dict[@"category"];
        if (tag && category.length==0) {
            if (![symbols containsObject:className]) {
                [symbols addObject:className];
            }
        }
    }];
    
    [self.classSelectors enumerateKeysAndObjectsUsingBlock:^(NSString*  _Nonnull className, NSDictionary*  _Nonnull selectorDict, BOOL * _Nonnull stop) {
        
        [selectorDict enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull selectorName, NSDictionary *  _Nonnull selectorAdditionalInfo, BOOL * _Nonnull stop) {
            // category 的 Selector不处理！
            if (![symbols containsObject:selectorName] && selectorAdditionalInfo[@"category"]==nil) {
                [symbols addObject:selectorName];
            }
        }];
    }];
    
    
    [symbols removeObjectsInArray: self.disabledSymbolsForClass];
    [symbols removeObjectsInArray: self.disabledSymbolsForSelector];
    [symbols removeObjectsInArray: self.blackListClasses];
    [symbols removeObjectsInArray: self.blackListSelectors];
    [symbols removeObjectsInArray: self.protocolSelectors];
    [symbols removeObjectsInArray: self.callingSuperSelectors];
    
    return symbols;
}



@end
