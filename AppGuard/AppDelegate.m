//
//  AppDelegate.m
//  AppGuard
//
//  Created by 周和生 on 15/10/12.
//
//
#import "ILSLogger.h"
#import "AppDelegate.h"
#import "NSString+Utils.h"
#import "MagicalRecord.h"
#import "SafeLanguageManager.h"
#import "NSString+RemovingComments.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (nonatomic, assign) BOOL runningInCommandLineSession;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    [[ILSLogger sharedLogger]configureWithLogLevel:ILSLogLevelInfo domainWhiteList:nil bonjourName:LOGGER_TARGET];
    [MagicalRecord setupAutoMigratingCoreDataStack];
    
    // test
    NSString *result = SFLocalizedString(@"Long tap to record greeting", @"comment");
    NSLog(@"SFLocalizedString result = %@", result);
    
    result = SFLocalizedString(@"Get a phone number as your second one, use my invitation code(%@) to get a discount. http://apple.co/2r7BDGT", @"comment");
    NSLog(@"SFLocalizedString result = %@", result);

    NSString *line = @"this is (not) good";
    NSString *pattern = @"\\(.*?\\)";
    NSRange range = [line rangeOfString:pattern options:NSRegularExpressionSearch];
    MYLog(@"line `%@`, pattern `%@`, range is `%@`", line, pattern, NSStringFromRange(range));
    
    line = @"// version4.1(401)add";
    MYLog(@"line `%@`, stringByRemovingComments result `%@`", line, [line stringByRemovingComments]);
    
    NSString *path = @"/Users/zhouhesheng/Workspace/photoframe/PicFrame/Resources/PFimages.bundle/star_shower.png";
    MYLog(@"path %@ backuppath %@ isbackup %zd", path, [path backupPath], [path isBackupPath]);
    path = @"/Users/zhouhesheng/Workspace/photoframe/PicFrame/Resources/PFimages_.bundle/star_shower.png";
    MYLog(@"path %@ backuppath %@ isbackup %zd", path, @"X", [path isBackupPath]);

    
    //Process Command Line Arguments, If Any
    self.runningInCommandLineSession = NO;
    NSArray *commandLineArgs = [[NSProcessInfo processInfo] arguments];
    if (commandLineArgs && [commandLineArgs count] > 0) {
        self.runningInCommandLineSession = YES;
        [self performSelector:@selector(processCommandLineArguments:) withObject:commandLineArgs afterDelay:0];
    }
}



- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


#pragma mark - Command Line

#define kArgumentSeperator @"="
#define kObjCObfuscating @"-objcObfuscating"
#define kImgObfuscating @"-imgObfuscating"
#define kStrObfuscating @"-strObfuscating"
#define kProjectFolder @"-projectFolder"

- (void)processCommandLineArguments:(NSArray *)arguments {
    
    
    NSString *projectFolder = nil;
    NSString *strObfuscating = nil;
    NSString *imgObfuscating = nil;
    NSString *objcObfuscating = nil;
    
    for (NSString *argument in arguments) {
        NSArray *splitArgument = [argument componentsSeparatedByString:kArgumentSeperator];
        
        if ([splitArgument count] == 2) {
            if ([[splitArgument objectAtIndex:0] isEqualToString:kProjectFolder]) {
                projectFolder = [splitArgument objectAtIndex:1];
            } else if ([[splitArgument objectAtIndex:0] isEqualToString:kStrObfuscating]) {
                strObfuscating = [splitArgument objectAtIndex:1];
            } else if ([[splitArgument objectAtIndex:0] isEqualToString:kImgObfuscating]) {
                imgObfuscating = [splitArgument objectAtIndex:1];
            } else if ([[splitArgument objectAtIndex:0] isEqualToString:kObjCObfuscating]) {
                objcObfuscating = [splitArgument objectAtIndex:1];
            }
        }
    }
    
    if (projectFolder) {
        NSLog(@"Arguments: projectFolder=`%@` kObjCObfuscating=`%@` kImgObfuscating=`%@` kStrObfuscating=`%@`", projectFolder, objcObfuscating, imgObfuscating, strObfuscating);
        
    }
    
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}
@end
