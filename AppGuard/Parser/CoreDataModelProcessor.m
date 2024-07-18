#import "CoreDataModelProcessor.h"
#import "CoreDataModelParser.h"


@implementation CoreDataModelProcessor



- (NSArray *)coreDataModelSymbolsToExclude {
    NSMutableArray *coreDataModelSymbols = [NSMutableArray array];
    CoreDataModelParser *parser = [[CoreDataModelParser alloc] init];

    __weak CoreDataModelProcessor *weakSelf = self;


    void (^modelCallback)(NSURL *) = ^(NSURL *url){
        NSData *data = [NSData dataWithContentsOfURL:url];
        NSString *string = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        MYLog(@"Fetching symbols from CoreData model at path %@，contents %@", url, string);
        NSArray *result = [parser symbolsInData:data];
        [coreDataModelSymbols addObjectsFromArray:result];
    };

    void (^xcdatamodelCallback)(NSURL *) = ^(NSURL *url){
        [weakSelf findFileWithSuffix:@"contents" inDirectoryURL:url foundCallback:modelCallback];
    };

    void (^xcdatamodeldCallback)(NSURL *) = ^(NSURL *url){
        [weakSelf findDirectoryWithSuffix:@".xcdatamodel/" inDirectoryURL:url foundCallback:xcdatamodelCallback];
    };

    NSString *currentPath = self.coreDataBaseDirectory ?: [NSFileManager defaultManager].currentDirectoryPath;
    [self findDirectoryWithSuffix:@".xcdatamodeld/"
                   inDirectoryURL:[NSURL URLWithString:currentPath]
                    foundCallback:xcdatamodeldCallback];

    return coreDataModelSymbols;
}

- (void)findFileWithSuffix:(NSString *)string inDirectoryURL:(NSURL *)URL foundCallback:(void (^)(NSURL *))callback {
    [self findFilesOrDirectoryWithString:string isDirectory:NO URL:URL callback:callback];
}

- (void)findDirectoryWithSuffix:(NSString *)string inDirectoryURL:(NSURL *)URL foundCallback:(void (^)(NSURL *))callback {
    [self findFilesOrDirectoryWithString:string isDirectory:YES URL:URL callback:callback];
}

- (void)findFilesOrDirectoryWithString:(NSString *)string isDirectory:(BOOL)directory URL:(NSURL *)URL callback:(void (^)(NSURL *))callback {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];

    NSDirectoryEnumerator *enumerator = [fileManager
        enumeratorAtURL:URL
        includingPropertiesForKeys:keys
        options:0
        errorHandler:^(NSURL *url, NSError *error) {
            // Handle the error.
            // Return YES if the enumeration should continue after the error.
            return YES;
    }];

    for (NSURL *url in enumerator) {
        NSError *error;
        NSNumber *isDirectory = nil;

        if ([url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:&error] && [isDirectory boolValue] == directory) {
            if ([url.absoluteString hasSuffix:string]) {
                if (callback) {
                    callback(url);
                }
            }
        }
    }
}

@end
