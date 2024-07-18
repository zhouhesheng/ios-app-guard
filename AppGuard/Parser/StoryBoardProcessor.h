#import <Foundation/Foundation.h>


@interface StoryBoardProcessor : NSObject
@property(nonatomic, copy) NSString *xibBaseDirectory;

- (void)obfuscateFilesUsingSymbols:(NSDictionary *)symbols;
- (NSArray *)allObjCSymbols;

@end
