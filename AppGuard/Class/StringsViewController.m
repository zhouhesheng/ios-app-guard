//
//  StringsViewController.m
//  AppGuard
//
//  Created by 周和生 on 2018/3/5.
//  Copyright © 2018年 GoodDay. All rights reserved.
//
#import "Node.h"
#import "StringsViewController.h"
#import "SafeLanguageManager.h"

@interface StringsViewController ()
@property (strong) IBOutlet NSTreeController *treeController;
@property (weak) IBOutlet NSOutlineView *outlineView;

@property (weak) IBOutlet NSTableView *detailsTableView;
@property (strong) IBOutlet NSArrayController *detailsController;

@property (nonatomic, strong) NSMutableDictionary *selectedLanguage;
@property (nonatomic, strong) Node *selectedNode, *parentNode;

@end

@implementation StringsViewController

- (IBAction)doneButtonPressed:(id)sender {
    [self dismissController:nil];
}

- (IBAction)encryptButtonPressed:(id)sender {
    if (self.workingFolder && self.stringsDict) {
        [SafeLanguageManager clearCache];
        
        NSString *path = [self.workingFolder stringByAppendingPathComponent:@"Strings"];
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        [[NSWorkspace sharedWorkspace] openFile:path];

        NSString *json = JSON_STRING_WITH_OBJ(self.stringsDict);
        [json writeToFile:[path stringByAppendingPathComponent:@"source.json"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
        MYLog(@"didSaveStrings=%@", json);
        
        NSData *encrypted = [SafeLanguageManager encryptString:json];
        [encrypted writeToFile:[path stringByAppendingPathComponent:SFLanguageFilename] atomically:YES];
        MYLog(@"didSaveData, len=%@", @(encrypted.length));
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    [self.treeController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"nodeName" ascending:YES]]];
    [self setupTreeNodes];
}


#pragma mark - NSOutlineView delegate

// only select leaf!
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    Node* node = [item representedObject];
    return node.isLeaf;
}

- (void)setupTreeNodes {
    NSDictionary *dict = @{
                           @"Languages" : [self.stringsDict.allKeys sortedArrayUsingSelector:@selector(compare:)]
                           };
    MYLog(@"setupTreeNodes with dict: %@", dict);
    
    //    just for testing
    //    dict[@"test"] = @[@(1), @"text", @{@"hello":@"world"}];
    
    Node *tree = [Node nodeWithName:@"root" object:dict];
    for (Node *child in tree.children) {
        [self.treeController addObject:child];
    }
    
    [self.treeController rearrangeObjects];
    [self.outlineView sizeLastColumnToFit];
    [self.outlineView expandItem:nil expandChildren:YES];
}

- (IBAction)outlineViewSelected:(NSOutlineView *)outlineView {
    NSInteger row = outlineView.selectedRow;
    if (row!=-1) {
        id selectedItem = [outlineView itemAtRow: row];
        MYLog(@"outlineView selectedItem %@", selectedItem);
        
        NSTreeNode *treeNode = self.treeController.selectedNodes.firstObject;
        Node *selectedNode = treeNode.representedObject;
        if (selectedNode.isLeaf) {
            Node *parentNode = treeNode.parentNode.representedObject;
            
            [self showDetails:selectedNode parent:parentNode];
            self.selectedNode = selectedNode;
            self.parentNode = parentNode;
        }
    }
}

- (void)showDetails:(Node *)node parent:(id)parent {
    MYLog(@"Will showDetails %@ parent %@", node.data, parent);
    if ([parent isKindOfClass:[Node class]]) {
        NSString *language = node.data.allValues.firstObject;
        NSDictionary *stringDict = self.stringsDict[language];
        [self refreshDetails:stringDict];

    } else {
        MYLog(@"parent for node %@ is %@", node, parent);
    }
}


- (void)refreshDetails:(NSDictionary *)stringDict {
    NSRange range = NSMakeRange(0, [[self.detailsController arrangedObjects] count]);
    [self.detailsController removeObjectsAtArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:range]];
    
    NSMutableArray *translations = [NSMutableArray array];
    NSArray *keys = [stringDict.allKeys sortedArrayUsingSelector:@selector(compare:)];
    NSInteger idx = 0;
    for (NSString *key in keys) {
        idx++;
        [translations addObject:@{
                                  @"idx":@(idx),
                                  @"key":key,
                                  @"value":stringDict[key]
                                  }];
    }
    
    [self.detailsController addObjects: translations];
}


@end
