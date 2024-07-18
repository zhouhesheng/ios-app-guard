//
//  FileLogger.m
//  ILSLog
//
//  Created by 周和生 on 14/8/1.
//  Copyright (c) 2014年 iLegendSoft. All rights reserved.
//

#import "FileLogger.h"

#define FILE_LOGGER_COUNTER @"ils.logger.FILE_LOGGER_COUNTER"

#define GCD_IS_CURRENT (dispatch_get_specific(&syncQueueID) ==  &syncQueueID)
static int syncQueueID = 0;

@interface FileLogger()
@property (nonatomic, strong) dispatch_queue_t syncQueue;
@end

@implementation FileLogger {
    NSFileHandle *logFile;
    NSString *logDirectory;
}

+ (FileLogger *)sharedInstance {
    static FileLogger *instance = nil;
    static dispatch_once_t done;
    dispatch_once(&done, ^{
        instance = [[FileLogger alloc] init];
    });
    
    return instance;
}

- (id) init {
    if (self == [super init]) {
        NSString* queueName = @"ils.filelogger.queue";
        _syncQueue = dispatch_queue_create(queueName.UTF8String, DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(_syncQueue, &syncQueueID, &syncQueueID, NULL);
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        logDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"filelogger"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager createDirectoryAtPath:logDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        
        NSInteger cnt = [[NSUserDefaults standardUserDefaults]integerForKey:FILE_LOGGER_COUNTER];
        cnt++;
        [[NSUserDefaults standardUserDefaults]setInteger:cnt forKey:FILE_LOGGER_COUNTER];
        [[NSUserDefaults standardUserDefaults]synchronize];
        
        NSString *filePath = [logDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"app%ld.log", (unsigned long)cnt]];
        [fileManager createFileAtPath:filePath contents:nil attributes:nil];

        [self runAsynchronously:^{
            logFile = [NSFileHandle fileHandleForWritingAtPath:filePath];
        }];
    }
    
    return self;
}




- (void) runSynchronously:(void (^)(void))block {
    if (GCD_IS_CURRENT) {
        block();
    }  else {
        dispatch_sync(_syncQueue, ^{
            block();
        });
    }
}

- (void) runAsynchronously:(void (^)(void))block {
    if (GCD_IS_CURRENT) {
        block();
    } else {
        dispatch_async(_syncQueue, ^{
            block();
        });
    }
}

- (NSString *)logFileContents {
    // We include last 5 files if exists
    NSMutableString *mString = [[NSMutableString alloc]init];
    NSInteger cnt = [[NSUserDefaults standardUserDefaults]integerForKey:FILE_LOGGER_COUNTER];
    for (NSInteger idx = MAX(cnt-5, 0); idx <= cnt; idx++) {
        NSString *filePath = [logDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"app%ld.log", (unsigned long)idx]];
        NSString *fileContent = [[NSString alloc]initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        if (fileContent.length) {
            [mString appendString:fileContent];
        }
    }
    
    return mString;
}

- (void)log_va:(NSString *)format arguments:(va_list)argList {
    NSString *message = [[NSString alloc] initWithFormat:format arguments:argList];
    [self logMessage:message];
}

- (void)logString:(NSString *)format, ... {
    va_list ap;
    va_start(ap, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:ap];
    [self logMessage:message];
}

- (void)logMessage: (NSString *)message {
    [self runAsynchronously:^{
        [logFile writeData:[[NSString stringWithFormat:@"%@: %@\n", [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterFullStyle timeStyle:NSDateFormatterMediumStyle], message]
                            dataUsingEncoding:NSUTF8StringEncoding]
         ];
        [logFile synchronizeFile];
    }];
}


@end