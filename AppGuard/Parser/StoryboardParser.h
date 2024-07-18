#import <Foundation/Foundation.h>



@interface StoryboardParser : NSObject

- (NSArray *)objCSymbolsInFile:(NSURL *)url;
- (NSData *)obfuscatedXmlData:(NSData *)data symbols:(NSDictionary *)symbols;

@end
