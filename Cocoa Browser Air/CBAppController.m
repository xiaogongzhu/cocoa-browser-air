//
//  CBAppController.m
//  Cocoa Browser Air
//
//  Created by numata on 08/05/05.
//  Copyright 2008 Satoshi Numata. All rights reserved.
//

#import "CBAppController.h"
#import "CBDocument.h"


// Singleton Pattern
static CBAppController *sInstance = nil;


@interface CBAppController (Private)

- (void)startLoadingIndicator;
- (void)stopLoadingIndicator;

@end


@implementation CBAppController

+ (void)initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:@"CBHidesSearchBarAutomatically"]) {
        [defaults setBool:YES forKey:@"CBHidesSearchBarAutomatically"];
        [defaults synchronize];
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication { return YES; }

+ (CBAppController *)sharedAppController
{
    return sInstance;
}

- (BOOL)_checkPlatformExistanceWithURL:(NSURL *)URL
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:[URL path]];
}

- (BOOL)_addPlatformWithName:(NSString *)platformName URL:(NSURL *)URL iconImagePath:(NSString *)iconImagePath
{
    if (![self _checkPlatformExistanceWithURL:URL]) {
        return NO;
    }

#ifdef __DEBUG__
    NSLog(@"CBAppController>> _addPlatformWithName:\"%@\"\n    URL:\"%@\"\n    iconImagePath:\"%@\"", platformName, URL, iconImagePath);
#endif

    NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     platformName, @"Name",
                                     [NSNumber numberWithBool:YES], @"Enabled",
                                     nil];
    [mPlatforms addObject:infoDict];
    NSString *filePath = [URL path];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        CBNode *platformNode = [[CBNode new] autorelease];
        platformNode.title = platformName;
        platformNode.type = CBNodeTypePlatform;
        platformNode.URL = URL;
        platformNode.isStrong = YES;
        NSData *iconImageData = [NSData dataWithContentsOfFile:iconImagePath];
        if (iconImageData) {
            NSImage *iconImage = [[[NSImage alloc] initWithData:iconImageData] autorelease];
            [iconImage setSize:NSMakeSize(16, 16)];
            platformNode.image = iconImage;
        }
        [mRootNode addChildNode:platformNode];
        [infoDict setObject:platformNode forKey:@"Node"];
    }
    return YES;
}

- (void)_setupPlatforms
{
    mPlatforms = [[NSMutableArray alloc] init];
    
    NSString *platformInfosPath = [[NSBundle mainBundle] pathForResource:@"Platforms" ofType:@"plist"];
    NSArray *platformInfos = [NSArray arrayWithContentsOfFile:platformInfosPath];
    for (NSDictionary *anInfo in platformInfos) {
        NSString *platformName = [anInfo objectForKey:@"Name"];
        NSString *urlStr = [anInfo objectForKey:@"URL"];
        NSString *iconFilePath = [anInfo objectForKey:@"Icon File Path"];
        int tryCount = 0;
        while (urlStr) {
            if ([self _addPlatformWithName:platformName
                                   URL:[NSURL URLWithString:urlStr]
                         iconImagePath:iconFilePath])
            {
                break;
            }
            tryCount++;
            urlStr = [anInfo objectForKey:[NSString stringWithFormat:@"Alt URL %d", tryCount]];
        }
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *disabledNames = [defaults objectForKey:@"Disabled Platforms"];
    for (NSMutableDictionary *aPlatformInfo in mPlatforms) {
        NSString *platformName = [aPlatformInfo objectForKey:@"Name"];
        if ([disabledNames containsObject:platformName]) {
            [aPlatformInfo setObject:[NSNumber numberWithBool:NO] forKey:@"Enabled"];
            CBNode *theNode = [aPlatformInfo objectForKey:@"Node"];
            theNode.enabled = NO;
        }
    }
    
    [self updateFrameworkList];
    [oPlatformTable reloadData];
}

- (void)_setupMenu:(NSMenu *)menu
{
    NSArray *menuItems = [menu itemArray];
    for (NSMenuItem *anItem in menuItems) {
        NSString *title = [anItem title];
        title = [NSString stringWithFormat:@"Menu %@", title];
        title = NSLocalizedString(title, nil);
        if (title && ![title hasPrefix:@"Menu"]) {
            [anItem setTitle:title];
        }
        if ([anItem hasSubmenu]) {
            NSMenu *submenu = [anItem submenu];
            NSString *title = [submenu title];
            title = [NSString stringWithFormat:@"Menu %@", title];
            title = NSLocalizedString(title, nil);
            if (title && ![title hasPrefix:@"Menu"]) {
                [submenu setTitle:title];
            }
            [self _setupMenu:submenu];
        }
    }
}

- (void)_setupMenuLocalization
{
    [self _setupMenu:oMenu];
}

- (void)awakeFromNib
{
    sInstance = self;
    
    mRootNode = [CBNode new];
    mRootNode.title = @"#root";
    mRootNode.type = CBNodeTypeRoot;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    mHidesSearchBarAutomatically = [defaults boolForKey:@"CBHidesSearchBarAutomatically"];
    if (mHidesSearchBarAutomatically) {
        [oHideSearchBarMenuItem setState:NSOnState];        
    } else {
        [oHideSearchBarMenuItem setState:NSOffState];
    }
}

- (void)dealloc
{
    [mRootNode release];
    [mLoadTargetURLStr release];
    
    [mPlatforms release];
    
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self _setupMenuLocalization];
    
    //[self _fetchFrameworkList];
    [self _setupPlatforms];
}


- (void)startLoadingIndicator
{
    NSDocumentController *docController = [NSDocumentController sharedDocumentController];
    for (CBDocument *aDocument in [docController documents]) {
        [aDocument startLoadingIndicator];
    }
}

- (void)stopLoadingIndicator
{
    NSDocumentController *docController = [NSDocumentController sharedDocumentController];
    for (CBDocument *aDocument in [docController documents]) {
        [aDocument stopLoadingIndicator];
    }
}

- (CBNode *)rootNode
{
    return mRootNode;
}

- (void)updateFrameworkList
{
    NSDocumentController *docController = [NSDocumentController sharedDocumentController];
    for (CBDocument *aDocument in [docController documents]) {
        [aDocument updateFrameworkList];
    }
}

- (void)updateBrowser
{
    NSDocumentController *docController = [NSDocumentController sharedDocumentController];
    for (CBDocument *aDocument in [docController documents]) {
        [aDocument updateBrowser];
    }
}

- (void)updateColumn:(NSInteger)column
{
    NSDocumentController *docController = [NSDocumentController sharedDocumentController];
    for (CBDocument *aDocument in [docController documents]) {
        [aDocument updateColumn:column];
    }
}

- (void)updateWebView
{
    NSDocumentController *docController = [NSDocumentController sharedDocumentController];
    for (CBDocument *aDocument in [docController documents]) {
        [aDocument updateWebView];
    }
}

- (IBAction)showPreferences:(id)sender
{
    if (![oPrefPanel isVisible]) {
        [oPrefPanel center];
    }
    [oPrefPanel makeKeyAndOrderFront:self];
}

- (IBAction)setHidesSearchBarAutomatically:(id)sender
{
    mHidesSearchBarAutomatically = !mHidesSearchBarAutomatically;

    if (mHidesSearchBarAutomatically) {
        [oHideSearchBarMenuItem setState:NSOnState];        
    } else {
        [oHideSearchBarMenuItem setState:NSOffState];
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:mHidesSearchBarAutomatically forKey:@"CBHidesSearchBarAutomatically"];
    [defaults synchronize];
    
    NSDocumentController *docController = [NSDocumentController sharedDocumentController];
    for (CBDocument *aDocument in [docController documents]) {
        [aDocument validateSearchBarShowing];
    }        
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [mPlatforms count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSDictionary *platformInfo = [mPlatforms objectAtIndex:rowIndex];
    if ([[aTableColumn identifier] isEqualToString:@"enabled"]) {
        return [platformInfo objectForKey:@"Enabled"];
    } else {
        return [platformInfo objectForKey:@"Name"];
    }
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSMutableDictionary *platformInfo = [mPlatforms objectAtIndex:rowIndex];
    [platformInfo setObject:anObject forKey:@"Enabled"];
    CBNode *theNode = [platformInfo objectForKey:@"Node"];
    theNode.enabled = [anObject boolValue];
    
    NSDocumentController *docController = [NSDocumentController sharedDocumentController];
    NSArray *documents = [docController documents];
    for (NSDocument *aDocument in documents) {
        if (![aDocument isKindOfClass:[CBDocument class]]) {
            continue;
        }
        CBDocument *aCBDocument = (CBDocument *)aDocument;
        [aCBDocument reloadFrameworkList];
    }
    
    NSMutableArray *disabledNames = [NSMutableArray array];
    for (NSDictionary *aPlatformInfo in mPlatforms) {
        if (![[aPlatformInfo objectForKey:@"Enabled"] boolValue]) {
            [disabledNames addObject:[aPlatformInfo objectForKey:@"Name"]];
        }
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:disabledNames forKey:@"Disabled Platforms"];
    [defaults synchronize];
}

- (BOOL)hidesSearchBarAutomatically
{
    return mHidesSearchBarAutomatically;
}

@end


