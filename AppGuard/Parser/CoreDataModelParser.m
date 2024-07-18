#import "CoreDataModelParser.h"
#import "GDataXMLNode.h"


@implementation CoreDataModelParser

- (NSArray *)symbolsInData:(NSData *)data {
    NSMutableArray *array = [NSMutableArray array];
    
    GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:data error:nil];
    
    [self addSymbolsFromNode:doc.rootElement toArray:array];
    
    return array;
}

- (void)addSymbolsFromNode:(GDataXMLElement *)element toArray:(NSMutableArray *)symbolsArray {
    NSArray *childNodes = element.children;

    // Get the class name
    GDataXMLNode *className = [element attributeForName:@"representedClassName"];
    if (className) {
        [symbolsArray addObject:[NSString stringWithFormat:@"!%@", className.stringValue]];
    }

    // Get the class name
    GDataXMLNode *parentClassName = [element attributeForName:@"parentEntity"];
    if (parentClassName) {
        [symbolsArray addObject:[NSString stringWithFormat:@"!%@", parentClassName.stringValue]];
    }

    // Recursively process rest of the elements
    for (GDataXMLElement *childNode in childNodes) {
        // Skip comments
        if ([childNode isKindOfClass:[GDataXMLElement class]]) {
            [self addSymbolsFromNode:childNode toArray:symbolsArray];
        }
    }
}

- (void)obfuscateElement:(GDataXMLElement *)element usingSymbols:(NSDictionary *)symbols {
    // TODO implement later
}


@end
