#import "StoryBoardProcessor.h"
#import "StoryboardParser.h"


@implementation StoryBoardProcessor

- (void)obfuscateFilesUsingSymbols:(NSDictionary *)symbols {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *keys = @[NSURLIsDirectoryKey];
    NSURL *directoryURL;
    if (self.xibBaseDirectory) {
        directoryURL = [NSURL URLWithString:self.xibBaseDirectory];
    } else {
        directoryURL = [NSURL URLWithString:@"."];
    }

    NSDirectoryEnumerator *enumerator = [fileManager
        enumeratorAtURL:directoryURL
        includingPropertiesForKeys:keys
        options:0
        errorHandler:^(NSURL *url, NSError *error) {
            // Handle the error.
            // Return YES if the enumeration should continue after the error.
            return YES;
    }];

    StoryboardParser *parser = [[StoryboardParser alloc] init];
    for (NSURL *url in enumerator) {
        NSError *error;
        NSNumber *isDirectory = nil;
        if ([url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error] && ![isDirectory boolValue]) {
            if ([url.absoluteString hasSuffix:@".xib"] || [url.absoluteString hasSuffix:@".storyboard"]) {
                MYLog(@"Obfuscating IB file at path %@", url);
                NSData *data = [parser obfuscatedXmlData:[NSData dataWithContentsOfURL:url] symbols:symbols];
                if (data) {
                    [data writeToURL:url atomically:YES];
                    NSLog(@"============ CDXibStoryboardParser: file changed %@", url.path);
                } else {
                    NSLog(@"============ CDXibStoryboardParser: obfuscatedXmlData NO result");
                }
            }
        }
    }
}

- (NSArray *)allObjCSymbols {
    NSMutableArray *marray = [NSMutableArray array];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *keys = @[NSURLIsDirectoryKey];
    NSURL *directoryURL;
    if (self.xibBaseDirectory) {
        directoryURL = [NSURL URLWithString:self.xibBaseDirectory];
    } else {
        directoryURL = [NSURL URLWithString:@"."];
    }
    
    NSDirectoryEnumerator *enumerator = [fileManager
                                         enumeratorAtURL:directoryURL
                                         includingPropertiesForKeys:keys
                                         options:0
                                         errorHandler:^(NSURL *url, NSError *error) {
                                             // Handle the error.
                                             // Return YES if the enumeration should continue after the error.
                                             return YES;
                                         }];
    
    StoryboardParser *parser = [[StoryboardParser alloc] init];
    for (NSURL *url in enumerator) {
        NSError *error;
        NSNumber *isDirectory = nil;
        if ([url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error] && ![isDirectory boolValue]) {
            if ([url.absoluteString hasSuffix:@".xib"] || [url.absoluteString hasSuffix:@".storyboard"]) {
                MYLog(@"parsing IB file at path %@", url);
                [marray addObjectsFromArray: [parser objCSymbolsInFile:url]];
            }
        }
    }
    
    return marray;
}


@end
