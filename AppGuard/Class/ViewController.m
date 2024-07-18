//
//  ViewController.m
//  ios-class-guard
//
//  Created by 周和生 on 15/10/12.
//
//
#import "TableLineNumberRulerView.h"
#import "ViewController.h"
#import "ILSLogger.h"
#import "EntProjectFile.h"
#import "MagicalRecord.h"
#import "NSManagedObject+Dictionary.h"
#import "ObjCObfuscatingOperation.h"
#import "NSImage+Utils.h"
#import "ImageColorOperation.h"
#import "StringsOrderOperation.h"
#import "ImageUsageOperation.h"
#import "ObfuscatingManager.h"
#import "PDFConvertingOperation.h"
#import "StringsViewController.h"

@interface ViewController ()<NSTableViewDataSource, NSTableViewDelegate, StringsOrderOperationDelegate>
@property (weak) IBOutlet NSArrayController *arrayController;
@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSTextField *targetTextField;
@property (weak) IBOutlet NSView *colorIndicatatorView;
@property (weak) IBOutlet NSImageView *colorPickerImageView;
@property (weak) IBOutlet NSSlider *slider;
@property (weak) IBOutlet NSTableView *assetsView; // 只列出 assets

@property(nonatomic, strong) NSMutableArray *assetFiles;
@property(nonatomic, strong) NSMutableArray *selectedAssetFiles;

@property (nonatomic, strong) ObjCObfuscatingOperation *obfuscatingOperation;
@property (nonatomic, strong) ImageColorOperation *colorOperation;
@property (nonatomic, strong) StringsOrderOperation *stringsOperation;
@property (nonatomic, strong) ImageUsageOperation *imageUsageOperation;
@property (nonatomic, strong) PDFConvertingOperation *pdfConvertingOperation;


@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSString *workingFolder;

@property (nonatomic, strong) NSString *classDumpResult;
@property (nonatomic, strong) NSColor *pickColor;
@end

@implementation ViewController

- (void)didCollectStrings:(NSDictionary *)dict {
    
    StringsViewController *vc = [[StringsViewController alloc]init];
    vc.stringsDict = dict;
    vc.workingFolder = self.workingFolder;
    [self presentViewControllerAsSheet:vc];
}


- (IBAction)checkImagesButtonPressed:(id)sender {
    if (self.workingFolder == nil || [self.arrayController.arrangedObjects count] == 0) {
        NSLog(@"No project");
        return;
    }
    NSLog(@"checkImagesButtonPressed, will check images usage");
    
    NSMutableArray *marray = [NSMutableArray array];
    
    for (EntProjectFile *projectFile in self.arrayController.arrangedObjects) {
            NSDictionary *dict = [projectFile attributesDictionary];
            [marray addObject: dict];
    }
    
    MYLog(@"checkImagesButtonPressed, files to go %@", marray);
    if (self.imageUsageOperation) {
        [self.imageUsageOperation cancel];
    }
    
    self.imageUsageOperation = [[ImageUsageOperation alloc]init];
    self.imageUsageOperation.projectFiles = marray;
    self.imageUsageOperation.workingFolder = self.workingFolder;
    
    [self.queue addOperation:self.imageUsageOperation];
}

- (IBAction)convertPDF:(id)sender {
    if (self.workingFolder == nil || [self.arrayController.arrangedObjects count] == 0) {
        NSLog(@"No project");
        return;
    }
    
    NSArray *extensions = @[@"pdf"];
    NSMutableArray *marray = [NSMutableArray array];
    
    for (EntProjectFile *projectFile in self.arrayController.arrangedObjects) {
        if ([extensions containsObject:projectFile.extension] && projectFile.selected.boolValue) {
            NSDictionary *dict = [projectFile attributesDictionary];
            [marray addObject: dict];
        }
    }
    
    MYLog(@"convertPDF, files to go %@", marray);
    if (self.pdfConvertingOperation) {
        [self.pdfConvertingOperation cancel];
    }
    
    self.pdfConvertingOperation = [[PDFConvertingOperation alloc]init];
    self.pdfConvertingOperation.projectFiles = marray;
    self.pdfConvertingOperation.workingFolder = self.workingFolder;
    
    [self.queue addOperation:self.pdfConvertingOperation];
}

- (IBAction)convertPDFTest:(id)sender {
    NSString *pathToUrPDF = [[NSBundle mainBundle]pathForResource:@"app_icon" ofType:@"pdf"];
    NSData *pdfData = [NSData dataWithContentsOfFile:pathToUrPDF];
    NSPDFImageRep *pdfImageRep = [NSPDFImageRep imageRepWithData:pdfData];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSInteger pageCount = [pdfImageRep pageCount];
    for(int i = 0 ; i < pageCount ; i++) {
        [pdfImageRep setCurrentPage:i];
        
        for (int factor=2; factor<=3; factor++) {
            NSSize newSize = NSMakeSize(pdfImageRep.size.width * factor,pdfImageRep.size.height * factor);
            NSImage* scaledImage = [NSImage imageWithSize:newSize flipped:NO drawingHandler:^BOOL(NSRect dstRect) {
                [pdfImageRep drawInRect:dstRect];
                return YES;
            }];
            ILSLogImage(@"PDFImage", scaledImage);
            
            NSBitmapImageRep* pngImageRep = [NSBitmapImageRep imageRepWithData:[scaledImage TIFFRepresentation]];
            NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
            NSData *finalData = [pngImageRep representationUsingType:NSPNGFileType properties:imageProps];
            
            NSString *pageName = [NSString stringWithFormat:@"page_%ld@%ldx.png", (long)[pdfImageRep currentPage], (long)factor];
            NSString* localDocuments = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
            NSString *path = [NSString stringWithFormat:@"%@/%@", localDocuments, pageName] ;
            [fileManager createFileAtPath:path contents:finalData attributes:nil];
            ILSLogInfo(@"PDFImage", @"saved to %@", path);
        }
    }
}

- (void)presentTestString {
    StringsViewController *vc = [[StringsViewController alloc]init];
    vc.stringsDict = @{@"en":@{
                               @"hello":@"hello english",
                               @"good":@"good english"
                               },
                       @"zh-Hans":@{
                               @"hello":@"你好",
                               @"good":@"早上好"
                               }
                       };
    [self presentViewControllerAsSheet:vc];

}

- (IBAction)obfuscateStringsPressed:(id)sender {
    if (self.workingFolder == nil || [self.arrayController.arrangedObjects count] == 0) {
        NSLog(@"No project");
        //[self presentTestString];
        return;
    }
    
    NSArray *extensions = @[@"strings"];
    NSMutableArray *marray = [NSMutableArray array];
    
    for (EntProjectFile *projectFile in self.arrayController.arrangedObjects) {
        if ([extensions containsObject:projectFile.extension] && projectFile.selected.boolValue) {
            NSDictionary *dict = [projectFile attributesDictionary];
            [marray addObject: dict];
        }
    }

    MYLog(@"obfuscateStringsPressed, files to go %@", marray);
    if (self.stringsOperation) {
        [self.stringsOperation cancel];
    }
    
    self.stringsOperation = [[StringsOrderOperation alloc]init];
    self.stringsOperation.delegate = self;
    self.stringsOperation.projectFiles = marray;
    self.stringsOperation.workingFolder = self.workingFolder;
    
    [self.queue addOperation:self.stringsOperation];
}


- (IBAction)obfuscateImagesPressed:(id)sender {
    
    if (self.workingFolder == nil || [self.arrayController.arrangedObjects count] == 0) {
        NSLog(@"No project");
        return;
    }
    
    NSArray *extensions = @[@"png", @"jpg"];
    NSMutableArray *marray = [NSMutableArray array];
    
    for (EntProjectFile *projectFile in self.arrayController.arrangedObjects) {
        if ([extensions containsObject:projectFile.extension] && projectFile.selected.boolValue) {
            NSDictionary *dict = [projectFile attributesDictionary];
            [marray addObject: dict];
        }
    }
    
    MYLog(@"obfuscateImagesPressed, files to go %@", marray);
    if (self.colorOperation) {
        [self.colorOperation cancel];
    }
    
    self.colorOperation = [[ImageColorOperation alloc]init];
    self.colorOperation.projectFiles = marray;
    self.colorOperation.workingFolder = self.workingFolder;
    self.colorOperation.pixColor = self.pickColor;
    self.colorOperation.obfuscatingMethod = ImageObfuscatingMethodColor;
    self.colorOperation.obfuscatingValueSaturation = kObfuscatingValueSaturation;
    self.colorOperation.obfuscatingValueBrightness = kObfuscatingValueBrightness;
    self.colorOperation.obfuscatingValueContrast = kObfuscatingValueContrast;
    
    [self.queue addOperation:self.colorOperation];
}



- (IBAction)handleGesture:(NSClickGestureRecognizer *)sender {
    NSImage *image = self.colorPickerImageView.image;
    ILSLogImage(@"source", image);
    NSImage *convertedImage = [image imageWithAlphaValue:0.6 saturationValue:1 brightnessValue:0.01 contrastValue:1.01];
//    [convertedImage saveWithName:@"/Users/zhouhesheng/Desktop/converted.png"];
//    NSImage *convertedImage = [image imageWithSaturationValue:1 brightnessValue:0.01 contrastValue:1.01];
    ILSLogImage(@"converted", convertedImage);
    
    NSPoint point = [sender locationInView:self.colorPickerImageView];
    self.pickColor = [[self.colorPickerImageView.image colorAtPoint: NSMakePoint(point.x, self.colorPickerImageView.image.size.height-point.y)] colorWithAlphaComponent:self.slider.floatValue];
    self.colorIndicatatorView.layer.backgroundColor = self.pickColor.CGColor;
    MYLog(@"imageview clicked at %@, viewsize %@ imagesize %@; color %@", NSStringFromPoint(point), NSStringFromSize(self.colorPickerImageView.frame.size), NSStringFromSize(self.colorPickerImageView.image.size), self.pickColor);
    
    NSImage *overlayedImage = [image imageByAddingImage:[NSImage imageWithColor:self.pickColor size:NSMakeSize(30, 30)]
                                                atPoint:NSMakePoint(0, 0)];
    ILSLogImage(@"overlayed", overlayedImage);
}

- (void)awakeFromNib {
    [super awakeFromNib];
    NSLog(@"awakeFromNib");

    self.colorIndicatatorView.wantsLayer = YES;
    
    NSScrollView *scrollView = [self.tableView enclosingScrollView];
    TableLineNumberRulerView *lineNumberView = [[TableLineNumberRulerView alloc] initWithTableView:self.tableView
                                                                              usingArrayController:self.arrayController];
    
    [scrollView setVerticalRulerView:lineNumberView];
    [scrollView setHasVerticalRuler:YES];
    [scrollView setRulersVisible:YES];


    NSScrollView *assetsScrollView = [self.assetsView enclosingScrollView];
    TableLineNumberRulerView *assetsLineNumberView = [[TableLineNumberRulerView alloc] initWithTableView:self.assetsView
                                                                              usingArrayController:self.arrayController];

    [assetsScrollView setVerticalRulerView:assetsLineNumberView];
    [assetsScrollView setHasVerticalRuler:YES];
    [assetsScrollView setRulersVisible:YES];

    NSString *_TargetName = [[NSUserDefaults standardUserDefaults]stringForKey:@"_TargetName"];
    if (_TargetName) {
        [self.targetTextField setStringValue:_TargetName];
    }
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    NSLog(@"viewDidLoad");
    
    self.queue = [[NSOperationQueue alloc]init];
    self.queue.maxConcurrentOperationCount = 1;
    
    [self.arrayController setSortDescriptors:@[
                                               [[NSSortDescriptor alloc]initWithKey:@"extension" ascending:YES],
                                               [[NSSortDescriptor alloc]initWithKey:@"filename" ascending:YES]
                                               ]];
}

- (IBAction)openProjectButtonSelected:(id)sender {
    if (self.arrayController.managedObjectContext == nil) {
        self.arrayController.managedObjectContext = [NSManagedObjectContext MR_defaultContext];
    }

    MYLog(@"openProjectButtonSelected");
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:NO];
    [panel setCanChooseDirectories:YES];
    
    [panel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSArray* urls = [panel URLs];
            for (NSURL *url in urls) {
                NSLog(@"selected url %@", url);
                self.workingFolder = url.path;
                [[ObfuscatingManager shareManager] scanFolder:url];
                [self reloadProjectFiles];
            }
        }
    }];
    
}

- (void)reloadProjectFiles {
    
    NSRange range = NSMakeRange(0, [[self.arrayController arrangedObjects] count]);
    [self.arrayController removeObjectsAtArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:range]];
    
    [EntProjectFile MR_truncateAll];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];

    _assetFiles = [NSMutableArray array];
    _selectedAssetFiles = [NSMutableArray array];

    for (NSDictionary *dict in [ObfuscatingManager shareManager].projectFiles) {
        EntProjectFile *projectFile = [EntProjectFile MR_createEntity];
        projectFile.path = dict[@"path"];
        projectFile.folder = dict[@"folder"];
        projectFile.relativepath = dict[@"relativepath"];
        projectFile.filename = dict[@"filename"];
        projectFile.extension = dict[@"extension"];
        projectFile.modified = dict[@"modified"] ?: [NSNumber numberWithBool:NO];
        projectFile.selected = dict[@"selected"] ?: [NSNumber numberWithBool:YES];

        [self.arrayController addObject:projectFile];
    }
   
    [self.arrayController rearrangeObjects];

    [self.assetFiles addObjectsFromArray:[ObfuscatingManager shareManager].assets];
    [self.assetsView reloadData];

    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}

- (IBAction)chechAll:(NSButton *)sender {
    if (self.workingFolder == nil || [self.arrayController.arrangedObjects count] == 0) {
        NSLog(@"No project");
        return;
    }
    
    MYLog(@"check all state %ld", sender.state);
    for (EntProjectFile *projectFile in self.arrayController.arrangedObjects) {
        projectFile.selected = [NSNumber numberWithBool:sender.state];
    }
    
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}


- (void)checkAsset:(NSString *)assetName selected:(BOOL)selected {
    if (self.workingFolder == nil || [self.arrayController.arrangedObjects count] == 0) {
        NSLog(@"No project");
        return;
    }

    MYLog(@"check checkAsset: %@, state %hhd", assetName, selected);
    NSString *assetPath = [NSString stringWithFormat:@"/%@/", assetName];
    for (EntProjectFile *projectFile in self.arrayController.arrangedObjects) {
        if ([projectFile.relativepath rangeOfString:assetPath].location != NSNotFound) {
            projectFile.selected = [NSNumber numberWithBool:selected];
        }
    }

    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}



- (IBAction)obfuscateButtonPressed:(id)sender {
    if (self.workingFolder == nil || [self.arrayController.arrangedObjects count] == 0) {
        NSLog(@"No project");
        return;
    }
    
    NSArray *extensions = @[@"h", @"m", @"xib", @"storyboard", @"classdump"];
    NSMutableArray *marray = [NSMutableArray array];
    
    for (EntProjectFile *projectFile in self.arrayController.arrangedObjects) {
        if ([extensions containsObject:projectFile.extension] && projectFile.selected.boolValue) {
            NSDictionary *dict = [projectFile attributesDictionary];
            [marray addObject: dict];
        }
    }
    
    MYLog(@"obfuscateButtonPressed, files to go %@", marray);
    if (self.obfuscatingOperation) {
        [self.obfuscatingOperation cancel];
    }
    
    self.obfuscatingOperation = [[ObjCObfuscatingOperation alloc]init];
    self.obfuscatingOperation.projectFiles = marray;
    self.obfuscatingOperation.workingFolder = self.workingFolder;
    self.obfuscatingOperation.obfuscatingLevel = obfuscatingLevelSimple;
#if DEBUG
    self.obfuscatingOperation.shouldProcessStoryboard = YES;
#endif
    [self.queue addOperation:self.obfuscatingOperation];
}

- (IBAction)checkboxAction:(NSTableView *)tableView {
    NSInteger row = tableView.selectedRow;
    EntProjectFile *projectFile = [self.arrayController.arrangedObjects objectAtIndex:row];
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
    MYLog(@"The button at row %ld was clicked, file %@, selected %d", row, projectFile.relativepath, projectFile.selected.boolValue);
}

- (NSString *)getTargetName {
    return [self.targetTextField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (IBAction)xcodebuildButtonPressed:(id)sender {
    
    if (self.getTargetName.length) {
        [[NSUserDefaults standardUserDefaults]setObject:self.getTargetName forKey:@"_TargetName"];
        [[NSUserDefaults standardUserDefaults]synchronize];
        
        NSOpenPanel* panel = [NSOpenPanel openPanel];
        [panel setCanChooseFiles:YES];
        [panel setCanChooseDirectories:NO];
        
        [panel beginWithCompletionHandler:^(NSInteger result){
            if (result == NSFileHandlingPanelOKButton) {
                NSArray* urls = [panel URLs];
                for (NSURL *url in urls) {
                    NSLog(@"building url %@, target %@", url, self.getTargetName);
                    [self performSelector:@selector(buildProject:) withObject:url afterDelay:0];
                }
            }
        }];
    } else {
        NSAlert *alert = [[NSAlert alloc]init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Target Not Set"];
        [alert setInformativeText:@"You should specify a target name to run xcodebuild and class-dump."];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert runModal];
    }
    
}

- (void)buildProject: (NSURL *)url {
    MYLog(@"Now build with xcode %@", url.path);
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/sh"];
    
    NSString *project = url.path;
    NSString *target = self.getTargetName;
    NSString *buildPath = [NSTemporaryDirectory() stringByAppendingPathComponent:target];
    [[NSFileManager defaultManager]removeItemAtPath:buildPath error:nil];
    
    NSString *command = [NSString stringWithFormat:@"xcodebuild -project \"%@\" -target \"%@\" -configuration Debug -sdk iphonesimulator clean build OBJROOT=\"%@\" SYMROOT=\"%@\"", project, target, buildPath, buildPath];
    NSLog(@"running %@", command);
    
    NSArray *arguments = [NSArray arrayWithObjects:
                          @"-c" ,
                          command,
                          nil];
    [task setArguments: arguments];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    [task launch];
    NSData *data = [file readDataToEndOfFile];
    NSString *result = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    MYLog(@"xcode build result is %@, buildPath %@", result, buildPath);
    
    NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:buildPath];
    
    NSString *appPath = nil;
    while ((appPath = [dirEnum nextObject])) {
        if ([[appPath pathExtension] isEqualToString: @"app"]) {
            [self classDump: [buildPath stringByAppendingPathComponent: appPath] forProject:project];
        }
    }
    
    
    NSAlert *alert = [[NSAlert alloc]init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:@"Build Project Finished"];
    [alert setInformativeText:@"Build Project Finished"];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert runModal];
}

- (void)classDump: (NSString *)appPath forProject: (NSString *)project {
    NSLog(@"dump %@", appPath);
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/sh"];
    
    NSArray *arguments = [NSArray arrayWithObjects:
                          @"-c" ,
                          [NSString stringWithFormat:@"/usr/local/bin/class-dump \"%@\"", appPath],
                          nil];
    [task setArguments: arguments];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    [task launch];
    NSData *data = [file readDataToEndOfFile];
    NSString *result = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    MYLog(@"class-dump result %@", result);
    self.classDumpResult = result;
    
    NSString *classDumpFilePath = [[project stringByDeletingPathExtension] stringByAppendingPathExtension:@"classdump"];
    [self.classDumpResult writeToFile:classDumpFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"class-dump saved to %@", classDumpFilePath);
}


#pragma mark - <NSTableViewDataSource>

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_assetFiles count];
}


- (void)tableView:(NSTableView *)tableView setObjectValue:(nullable id)object forTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView != _assetsView) return;

    if ([tableColumn.identifier isEqualToString:@"selected"]) {
        NSString *assetFile = [_assetFiles objectAtIndex:row];
        if (assetFile == nil) return;

        if ([object boolValue]) {
            [_selectedAssetFiles addObject:assetFile];
            [self checkAsset:assetFile selected:YES];
        } else {
            [_selectedAssetFiles removeObject:assetFile];
            [self checkAsset:assetFile selected:NO];
        }
    }
}


- (nullable id)tableView:(NSTableView *)tableView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView != _assetsView) return nil;

    NSString *assetFile = [_assetFiles objectAtIndex:row];
    if ([tableColumn.identifier isEqualToString:@"text"]) {
        return assetFile;
    }
    if ([tableColumn.identifier isEqualToString:@"selected"]) {
        BOOL selected = (assetFile && [_selectedAssetFiles containsObject:assetFile]);
        return @(selected);
    }

    return nil;
}


@end
