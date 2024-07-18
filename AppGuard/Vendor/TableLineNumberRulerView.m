//
//  TableLineNumberRulerView.m
//  ios-class-guard
//
//  Created by 周和生 on 15/10/12.
//
//



#import "TableLineNumberRulerView.h"

#define DEFAULT_THICKNESS   22.0
#define RULER_MARGIN        5.0

@interface TableLineNumberRulerView()

@property (strong) NSArrayController *arrayController;

@property (strong) NSFont       *font;
@property (strong) NSColor  *textColor;
@property (strong) NSColor  *alternateTextColor;
@property (strong) NSColor  *backgroundColor;
@property (strong) NSDictionary *textAttributes;
@property (assign) NSUInteger   rowCount;

@end

@implementation TableLineNumberRulerView

@synthesize font;
@synthesize textColor;
@synthesize alternateTextColor;
@synthesize backgroundColor;
@synthesize textAttributes;
@synthesize rowCount;


- (id)initWithTableView:(NSTableView *)tableView usingArrayController:(NSArrayController *)arrayController
{
    NSScrollView *scrollView = [tableView enclosingScrollView];
    
    if ((self = [super initWithScrollView:scrollView orientation:NSVerticalRuler]) == nil)
        return nil;
    
    [self setClientView:tableView];
    
    self.arrayController = arrayController;
    [arrayController addObserver:self forKeyPath:@"arrangedObjects" options:NSKeyValueObservingOptionNew context:nil];
    
    self.font = [NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeSmall]];
    self.textColor = [NSColor colorWithCalibratedWhite:0.42 alpha:1.0];
    self.alternateTextColor = [NSColor whiteColor];
    self.textAttributes = @{
                            NSFontAttributeName: [self font],
                            NSForegroundColorAttributeName: [self textColor]
                            };
    
    self.rowCount = [[arrayController arrangedObjects] count];
    NSLog(@"TableLineNumberRulerView init and addObserver %p", self);

    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setClientView:[[self scrollView] documentView]];      // this will be an NSTableView instance
}


- (void)finalize
{
    NSLog(@"TableLineNumberRulerView finalize and removeObserver %p", self);
    [self.arrayController removeObserver:self forKeyPath:@"arrangedObjects"];
}


- (void)dealloc
{
    NSLog(@"TableLineNumberRulerView dealloc and removeObserver %p", self);
    @try{
        [self.arrayController removeObserver:self forKeyPath:@"arrangedObjects"];
    } @catch (NSException *exception) {
        NSLog(@"TableLineNumberRulerView dealloc and removeObserver %p exception %@", self, exception);
    }
}

#pragma mark -
#pragma mark Key-Value observing of changes to array controller

/*
 * This picks up changes to the arrayController's arrangedObjects using KVO.
 * We check the size of the old and new rowCounts and compare them to see if the number
 * digits has changed, and if so, we adjust the ruler width.
 */

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"arrangedObjects"]) {
        NSUInteger newRowCount = [[self.arrayController arrangedObjects] count];
        
        if ((int)log10(self.rowCount) != (int)log10(newRowCount))
            [self setRuleThickness:[self requiredThickness]];
        self.rowCount = newRowCount;
        // we need to redisplay because line numbers may change or disappear in view
        [self setNeedsDisplay:YES];
    }
}


- (CGFloat)requiredThickness
{
    NSUInteger      lineCount = [[self.arrayController arrangedObjects] count],
    digits = (unsigned)log10((lineCount < 1) ? 1: lineCount) + 1;
    NSMutableString *sampleString = [NSMutableString string];
    NSSize          stringSize;
    
    for (NSUInteger i = 0; i < digits; i++) {
        // Use "8" since it is one of the fatter numbers. Anything but "1"
        // will probably be ok here. I could be pedantic and actually find the fattest
        // number for the current font but nah.
        [sampleString appendString:@"8"];
    }
    
    stringSize = [sampleString sizeWithAttributes:[self textAttributes]];
    
    // Round up the value. There is a bug on 10.4 where the display gets all wonky when scrolling if you don't
    // return an integral value here.
    return ceil(MAX(DEFAULT_THICKNESS, stringSize.width + RULER_MARGIN * 2));
}

- (void)drawHashMarksAndLabelsInRect:(NSRect)aRect
{
    NSTableView *tableView = (NSTableView *)[self clientView];
    NSRect bounds = [self bounds];
    NSRect visibleRect = [[tableView enclosingScrollView] documentVisibleRect];
    NSRange visibleRowRange = [tableView rowsInRect:visibleRect];
    
    if (backgroundColor != nil) {
        [backgroundColor set];
        NSRectFill(bounds);
        
        [[NSColor colorWithCalibratedWhite:0.58 alpha:1.0] set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMaxX(bounds) - 0/5, NSMinY(bounds))
                                  toPoint:NSMakePoint(NSMaxX(bounds) - 0.5, NSMaxY(bounds))];
    }
    
    //    NSLog(@"drawHashMarksAndLabelsInRect: bounds %@, ruleThickness %lf", NSStringFromRect(bounds), [self ruleThickness]);
    
    for (NSUInteger row = visibleRowRange.location; NSLocationInRange(row, visibleRowRange); row++) {
        // Line numbers are internally stored starting at 0
        NSString *labelText = [NSString stringWithFormat:@"%lu", row + 1];
        NSSize stringSize = [labelText sizeWithAttributes:self.textAttributes];
        NSRect rowRect = [tableView rectOfRow:row];
        CGFloat ypos = NSMinY(rowRect) - NSMinY(visibleRect);
        
        [labelText drawInRect:NSMakeRect(NSWidth(bounds) - stringSize.width - RULER_MARGIN,
                                         ypos + (NSHeight(rowRect) - stringSize.height) / 2.0,
                                         NSWidth(bounds) - RULER_MARGIN * 2.0, NSHeight(rowRect))
               withAttributes:self.textAttributes];
    }
}

#pragma mark -
#pragma mark NSCoding methods

#define FONT_CODING_KEY             @"font"
#define TEXT_COLOR_CODING_KEY       @"textColor"
#define ALT_TEXT_COLOR_CODING_KEY   @"alternateTextColor"
#define BACKGROUND_COLOR_CODING_KEY @"backgroundColor"

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super initWithCoder:decoder]) != nil) {
        if ([decoder allowsKeyedCoding]) {
            font = [decoder decodeObjectForKey:FONT_CODING_KEY];
            textColor = [decoder decodeObjectForKey:TEXT_COLOR_CODING_KEY];
            alternateTextColor = [decoder decodeObjectForKey:ALT_TEXT_COLOR_CODING_KEY];
            backgroundColor = [decoder decodeObjectForKey:BACKGROUND_COLOR_CODING_KEY];
        } else {
            font = [decoder decodeObject];
            textColor = [decoder decodeObject];
            alternateTextColor = [decoder decodeObject];
            backgroundColor = [decoder decodeObject];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    
    if ([encoder allowsKeyedCoding]) {
        [encoder encodeObject:font forKey:FONT_CODING_KEY];
        [encoder encodeObject:textColor forKey:TEXT_COLOR_CODING_KEY];
        [encoder encodeObject:alternateTextColor forKey:ALT_TEXT_COLOR_CODING_KEY];
        [encoder encodeObject:backgroundColor forKey:BACKGROUND_COLOR_CODING_KEY];
    } else {
        [encoder encodeObject:font];
        [encoder encodeObject:textColor];
        [encoder encodeObject:alternateTextColor];
        [encoder encodeObject:backgroundColor];
    }
}

@end
