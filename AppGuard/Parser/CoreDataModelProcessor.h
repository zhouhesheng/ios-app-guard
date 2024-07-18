#import <Foundation/Foundation.h>


@interface CoreDataModelProcessor : NSObject

@property(nonatomic, copy) NSString *coreDataBaseDirectory;


- (NSArray *)coreDataModelSymbolsToExclude;

@end
