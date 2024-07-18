//
//  TableLineNumberRulerView.h
//  ios-class-guard
//
//  Created by 周和生 on 15/10/12.
//
//

#import <Cocoa/Cocoa.h>

@interface TableLineNumberRulerView : NSRulerView<NSCoding>


- (id)initWithTableView:(NSTableView *)tableView  usingArrayController:(NSArrayController *)arrayController;

@end
