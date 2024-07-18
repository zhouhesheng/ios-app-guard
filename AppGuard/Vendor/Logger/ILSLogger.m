//
//  ILSLogger.m
//  ILSLogger
//
//  Created by bloodmagic on 13-5-7.
//  Copyright (c) 2013年 iLegendSoft. All rights reserved.
//
@import Cocoa;
#import "ILSLogger.h"
#import "LoggerClient.h"
#import "FileLogger.h"

@interface ILSLogger ()
@property (nonatomic, strong) NSSet* domainWhiteList;
@property (nonatomic) enum ILSLogLevel logLevel;
@property (nonatomic, strong) NSString* bonjourName;
@property (nonatomic,strong) NSString* localFilePath;

@end

@implementation ILSLogger

+ (ILSLogger*) sharedLogger{
    static ILSLogger* shared;
    static dispatch_once_t done;
    dispatch_once(&done, ^{
        shared = [ILSLogger new];
    });
    return shared;
}

+ (NSString *)logFileContents {
    return [FileLogger sharedInstance].logFileContents;
}



+ (void) logWithinDomain_va: (NSString *)domain level: (ILSLogLevel) level format: (NSString *)format arguments:(va_list)argList {
    BOOL needLog = ([ILSLogger sharedLogger].logLevel >= level) || [[ILSLogger sharedLogger].domainWhiteList containsObject:domain];
    if (needLog) {
        if ([ILSLogger sharedLogger].logEnabled) {
            va_list arg;
            va_copy(arg, argList);
            LogMessage_va(domain, level, format, argList);
            [[FileLogger sharedInstance]log_va:format arguments:arg];
        }
    }
}



-(id)init {
    self = [super init];
    if (self) {
        
        int options = LOGGER_DEFAULT_OPTIONS;
        options &= (uint32_t)~kLoggerOption_CaptureSystemConsole;
        LoggerSetOptions(NULL, options);
        
        self.logLevel = ILSLogLevelError;
    }
    return self;
}

-(void) configureWithLogLevel:(enum ILSLogLevel) logLevel
              domainWhiteList:(NSArray*)domainWhiteList
                  bonjourName:(NSString*)bonjourName
{
    self.logLevel = logLevel;
    
    if (domainWhiteList) {
        self.domainWhiteList = [NSSet setWithArray:domainWhiteList];
    }
    if (bonjourName) {
        LoggerSetupBonjour(NULL, NULL, (__bridge CFStringRef)(bonjourName));
        _logEnabled = YES;
    }
}

-(void) setNSLoggerViewerHost:(NSString*)hostNameOrIP port:(UInt32)port {
    LoggerSetViewerHost(NULL, (__bridge CFStringRef)hostNameOrIP, port);
    _logEnabled = YES;
}


@end



void ILSLogString(NSString *domain, ILSLogLevel level, NSString *format, ...)
{
    BOOL needLog = ([ILSLogger sharedLogger].logLevel >= level) || [[ILSLogger sharedLogger].domainWhiteList containsObject:domain];
    if (needLog) {
        if ([ILSLogger sharedLogger].logEnabled) {
            va_list args;
            va_start(args, format);
            LogMessage_va(domain, level, format, args);
            va_end(args);
            
            va_list ap;
            va_start(ap, format);
            [[FileLogger sharedInstance]log_va:format arguments:ap];
        }
    }
}


void ILSLogData(NSString *title, NSData* data)
{
    if ([ILSLogger sharedLogger].logLevel >= ILSLogLevelInfo) {
        if ([ILSLogger sharedLogger].logEnabled) {
            LogData(title, ILSLogLevelInfo, data);
        }
    }
    
}

void ILSLogImage(NSString *title, NSImage* image)
{
    if ([ILSLogger sharedLogger].logLevel >= ILSLogLevelInfo) {
        if ([ILSLogger sharedLogger].logEnabled) {
            NSSize size = [image size];
            LogImageData(title, ILSLogLevelInfo, size.width, size.height, [image TIFFRepresentation]);
        }
    }
}


void ILSLogFlush()
{
    LoggerFlush(NULL,YES);
}

