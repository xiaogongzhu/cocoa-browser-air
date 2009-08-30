//
//  CBDocument.m
//  Cocoa Browser Air
//
//  Created by numata on 08/05/05.
//  Copyright Satoshi Numata 2008 . All rights reserved.
//

#import "CBDocument.h"
#import "CBAppController.h"
#import "NSURL+AppleRefAnalyze.h"
#import "CBOutlineViewCell.h"
#import "CBNavigationInfo.h"
#import "CBReferenceInfo.h"
#import "NSView+FadeAnimation.h"
#import "CBToolbar.h"


static NSString *sCBToolbarItemIdentifierGoBack     = @"CBToolbarItemIdentifierGoBack";
static NSString *sCBToolbarItemIdentifierSearch     = @"CBToolbarItemIdentifierSearch";
static NSString *sCBToolbarItemIdentifierLoading    = @"CBToolbarItemIdentifierLoading";


@interface CBDocument (Private)

- (CBNode *)nodeForPlatform:(NSString *)platformName;
- (CBNode *)nodeForFramework:(NSString *)frameworkName;
- (int)nodeCountForColumn:(int)column;
- (CBNode *)nodeForRow:(int)row column:(int)column;
- (CBNode *)selectedNode;

- (void)resolveNextShowInfoStack;
- (void)finishResolvingStack;

- (void)setHTMLSource:(NSString *)htmlSource;

- (BOOL)canGoBack;
- (BOOL)canGoForward;
- (void)validateHistoryButtons;
- (void)addHistoryItemForNode:(CBNode *)targetNode;

- (void)showFullSearchResultsView;
- (void)hideFullSearchResultsView;
- (void)hideSearchBar;
- (void)showSearchBar;

- (void)clearAllSearchWords;

@end


@implementation CBDocument

//-------------------------------------------------------------------------
#pragma mark ==== Initialization ====
//-------------------------------------------------------------------------

- (id)init
{
    self = [super init];
    if (self) {
        mLastSelectedRow = -1;
        mLastSelectedColumn = -1;
        mShowInfoStack = [[NSMutableArray array] retain];
        mHistoryPastNodes = [[NSMutableArray array] retain];
        mHistoryFutureNodes = [[NSMutableArray array] retain];
        mIsResolvingStacks = NO;
        mIsManuallyShowingNode = NO;
        mIsFullSearchResultShown = NO;
        mIsSearchBarShown = YES;
    }
    return self;
}

- (void)dealloc
{
    [mShowInfoStack release];
    [mHistoryPastNodes release];
    [mHistoryFutureNodes release];
    [super dealloc];
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];

    NSTableColumn *frameworkColumn = [oFrameworkListView tableColumnWithIdentifier:@"framework"];
    CBOutlineViewCell *templateCell = [[CBOutlineViewCell new] autorelease];
    [frameworkColumn setDataCell:templateCell];
    
    // Set up framework list
    [oFrameworkListView setTarget:self];
    [oFrameworkListView setDoubleAction:@selector(frameworkListDoubleClicked:)];
    
    // Set up search field
    id searchFieldCell = [oFullSearchField cell];
    if ([searchFieldCell respondsToSelector:@selector(setPlaceholderString:)]) {
        [searchFieldCell setPlaceholderString:NSLocalizedString(@"Search Field Placeholder", nil)];
    }
    
    // Set up status field
    CBAppController *appController = [CBAppController sharedAppController];
    if ([[appController rootNode] childNodeCount] == 0) {
        [oStatusField setStringValue:NSLocalizedString(@"Loading Framework List...", nil)];
    } else {
        [oStatusField setStringValue:@""];
        [self updateFrameworkList];
    }

    // Set up HTML source view
    NSMutableAttributedString *sourceAttrStr = [oSourceView textStorage];
    [sourceAttrStr setAttributedString:[[[NSAttributedString alloc] init] autorelease]];
    
    // Set up browser
    [oBrowser setMinColumnWidth:1.0];
    NSRect browserFrame = [oBrowser frame];
    browserFrame.size.width -= 10;
    [oBrowser setFrame:browserFrame];
    [oBrowser setTarget:self];
    [oBrowser setDoubleAction:@selector(browserDoubleClicked:)];
    
    // Set up loading indicator
    [oLoadingIndicator setDisplayedWhenStopped:NO];
    
    // Set up history buttons
    [self validateHistoryButtons];

    // Set up toolbar
    NSToolbar *toolbar = [[[CBToolbar alloc] initWithIdentifier:@"Main Toolbar"] autorelease];
    [toolbar setDelegate:self];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setAutosavesConfiguration:NO];
    [oMainWindow setToolbar:toolbar];
    
    [oFullSearchResultView setRowHeight:15.0f];
    
    // 検索フィールドの画像をセット
    [oSearchButton1 setImage:[NSImage imageNamed:NSImageNameRevealFreestandingTemplate]];
    [oSearchButton3 setImage:[NSImage imageNamed:NSImageNameRevealFreestandingTemplate]];
    
    {
        NSRect frame = [oBrowserSplitView frame];
        frame.size.height += [oFullSearchResultViewBox frame].size.height - 2 + 5;
        [oBrowserSplitView setFrame:frame];
    }
    
    // 全文検索はまだサポートしない
    [oFullSearchField setEnabled:NO];
    
    // Window is not visible at this time (but it will be visible just after this method is completed).
    [NSTimer scheduledTimerWithTimeInterval:0
                                     target:self
                                   selector:@selector(setupWindowTitleProc:)
                                   userInfo:nil
                                    repeats:NO];
}

- (IBAction)searchField1CancelButtonPressed:(id)sender
{
    NSLog(@"OK");
}

- (void)setupWindowTitleProc:(NSTimer *)theTimer
{
    [oMainWindow setTitle:@"Cocoa Browser Air"];
}

- (IBAction)activateFullSearchField:(id)sender
{
    [oMainWindow makeFirstResponder:oFullSearchField];
    [oBrowserSplitView setNeedsDisplay:YES];
}


//-------------------------------------------------------------------------
#pragma mark ==== Document's Settings ====
//-------------------------------------------------------------------------

- (NSString *)windowNibName
{
    return @"CBDocument";
}


//-------------------------------------------------------------------------
#pragma mark ==== Actions ====
//-------------------------------------------------------------------------

- (IBAction)goBack:(id)sender
{
    if ([mHistoryPastNodes count] < 2) {
        return;
    }
    
    // Save one possible future
    [mHistoryFutureNodes addObject:[mHistoryPastNodes lastObject]];
    [mHistoryPastNodes removeLastObject];
    
    // And load one past
    CBNode *aPastNode = [mHistoryPastNodes lastObject];

    // Go to the time
    [self showNode:aPastNode];

    // Validate go/back button
    [self validateHistoryButtons];
}

- (IBAction)goForward:(id)sender
{
    if ([mHistoryFutureNodes count] < 1) {
        return;
    }
    
    // Get one possible future
    CBNode *aFutureNode = [mHistoryFutureNodes lastObject];
    [mHistoryPastNodes addObject:aFutureNode];
    [mHistoryFutureNodes removeLastObject];

    // Go to the time
    [self showNode:aFutureNode];
    
    // Validate go/back button
    [self validateHistoryButtons];
}

- (IBAction)viewSource:(id)sender
{
    [oSourceWindow makeKeyAndOrderFront:self];
}

- (IBAction)activateSearchField1:(id)sender
{
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(deactivateSearchField2:) userInfo:nil repeats:NO];
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(deactivateSearchField3:) userInfo:nil repeats:NO];
    
    mLastSearchFieldActivatedTime1 = [NSDate timeIntervalSinceReferenceDate];
    [oSearchButton1 fadeOut:0.25];
    [oSearchField1 fadeIn:0.25];
    [oMainWindow makeFirstResponder:oSearchField1];
}

- (IBAction)deactivateSearchField1:(id)sender
{
    if ([oSearchField1 isHidden]) {
        return;
    }
    [oSearchField1 fadeOut:0.25];
    [oSearchButton1 fadeIn:0.25];
}

- (IBAction)activateSearchField2:(id)sender
{
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(deactivateSearchField1:) userInfo:nil repeats:NO];
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(deactivateSearchField3:) userInfo:nil repeats:NO];

    mLastSearchFieldActivatedTime2 = [NSDate timeIntervalSinceReferenceDate];
    [oSearchButton2 fadeOut:0.25];
    [oSearchField2 fadeIn:0.25];
    [oMainWindow makeFirstResponder:oSearchField2];
}

- (IBAction)deactivateSearchField2:(id)sender
{
    if ([oSearchField2 isHidden]) {
        return;
    }
    [oSearchField2 fadeOut:0.25];
    [oSearchButton2 fadeIn:0.25];
}

- (IBAction)activateSearchField3:(id)sender
{
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(deactivateSearchField1:) userInfo:nil repeats:NO];
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(deactivateSearchField2:) userInfo:nil repeats:NO];

    mLastSearchFieldActivatedTime3 = [NSDate timeIntervalSinceReferenceDate];
    [oSearchButton3 fadeOut:0.25];
    [oSearchField3 fadeIn:0.25];
    [oMainWindow makeFirstResponder:oSearchField3];
}

- (IBAction)deactivateSearchField3:(id)sender
{
    if ([oSearchField3 isHidden]) {
        return;
    }
    [oSearchField3 fadeOut:0.25];
    [oSearchButton3 fadeIn:0.25];
}

- (IBAction)performFullSearch:(id)sender
{
    NSString *searchWord = [[oFullSearchField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([searchWord length] == 0) {
        [self hideFullSearchResultsView];
        return;
    }

    [self showFullSearchResultsView];
}


//-------------------------------------------------------------------------
#pragma mark ==== Actions for Interacting with UI Parts ====
//-------------------------------------------------------------------------

/*!
    @method     changedBrowserSelection:
    @abstract   This action is invoked when the browser selection is changed.
 */
- (IBAction)changedBrowserSelection:(id)sender
{
    if ([[CBAppController sharedAppController] hidesSearchBarAutomatically]) {
        NSString *searchWord1 = [[oSearchField1 stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *searchWord3 = [[oSearchField3 stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([searchWord1 length] == 0 && [searchWord3 length] == 0) {
            [self hideSearchBar];
        }
    }
    
    int column = [oBrowser selectedColumn];
    int row = [oBrowser selectedRowInColumn:column];
        
    if (column == mLastSelectedColumn && row == mLastSelectedRow) {
        // Ignore when the selected position was same as before
        return;
    }
    
    mLastSelectedColumn = column;
    mLastSelectedRow = row;
    
    CBNode *selectedNode = [self selectedNode];
    [self addHistoryItemForNode:selectedNode];
    
    if (![oSearchField1 isHidden] && [[[oSearchField1 stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0) {
        [self deactivateSearchField1:self];
    }
    if (![oSearchField3 isHidden] && [[[oSearchField3 stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0) {
        [self deactivateSearchField3:self];
    }
    
    if (selectedNode.type == CBNodeTypeClassLevel) {
        [oSearchField3 setStringValue:@""];
        [self deactivateSearchField3:self];
        [oSearchButton3 fadeOut:0.25];
        
        if (selectedNode.isLeaf) {
            [oSearchButton2 fadeOut:0.25];
        } else {
            [oSearchButton2 setEnabled:NO];
            [oSearchButton2 setTitle:NSLocalizedString(@"Categories", nil)];
            [oSearchButton2 fadeIn:0.25];
        }
    } else if (selectedNode.type == CBNodeTypeCategory) {
        [selectedNode setFilteringStr:nil];
        [oSearchField3 setStringValue:@""];
        [oSearchField3 fadeOut:0.25];
        if (selectedNode.isLeaf) {
            [oSearchButton3 fadeOut:0.25];
        } else {
            if ([selectedNode.title hasSuffix:@" Methods"]) {
                [oSearchButton3 setTitle:NSLocalizedString(@"Method Names", nil)];
                [oSearchButton3 fadeIn:0.25];
            }
            else if ([selectedNode.title isEqualToString:@"Tasks"]) {
                [oSearchButton3 setTitle:NSLocalizedString(@"Task Names", nil)];
                [oSearchButton3 fadeIn:0.25];
            }
            else if ([selectedNode.title isEqualToString:@"Constants"]) {
                [oSearchButton3 setTitle:NSLocalizedString(@"Constant Names", nil)];
                [oSearchButton3 fadeIn:0.25];
            }
            else if ([selectedNode.title isEqualToString:@"Functions"]) {
                [oSearchButton3 setTitle:NSLocalizedString(@"Function Names", nil)];
                [oSearchButton3 fadeIn:0.25];
            }
            else if ([selectedNode.title isEqualToString:@"Functions by Task"]) {
                [oSearchButton3 setTitle:NSLocalizedString(@"Task Names", nil)];
                [oSearchButton3 fadeIn:0.25];
            }
            else if ([selectedNode.title isEqualToString:@"Data Types"]) {
                [oSearchButton3 setTitle:NSLocalizedString(@"Type Names", nil)];
                [oSearchButton3 fadeIn:0.25];
            }
            else if ([selectedNode.title isEqualToString:@"Notifications"]) {
                [oSearchButton3 setTitle:NSLocalizedString(@"Notification Names", nil)];
                [oSearchButton3 fadeIn:0.25];
            }
            else {
                [oSearchButton3 fadeOut:0.25];
            }
        }
    }
    
    if (selectedNode.isLoaded || !selectedNode.URL) {
        [self updateWebView];
    } else {
        [selectedNode startLoad];
    }
}

- (IBAction)historyButtonClicked:(NSSegmentedControl *)sender
{
    int selectedSegment = [sender selectedSegment];
    int clickedSegmentTag = [[sender cell] tagForSegment:selectedSegment];
    if (clickedSegmentTag == 0) {
        [self goBack:self];
    } else {
        [self goForward:self];
    }
}

- (IBAction)showFindPanel:(id)sender
{
    [oFindPanel center];
    [oFindPanel makeKeyAndOrderFront:self];
}

- (IBAction)findNext:(id)sender
{
    NSString *targetWord = [oFindField stringValue];
    if (!targetWord || [targetWord length] == 0) {
        NSBeep();
        return;
    }
    [oFindPanel orderOut:self];
    [oWebView searchFor:targetWord direction:YES caseSensitive:([oFindCaseIgnoreButton state] != NSOnState) wrap:NO];
}

- (IBAction)findPrevious:(id)sender
{
    NSString *targetWord = [oFindField stringValue];
    if (!targetWord || [targetWord length] == 0) {
        NSBeep();
        return;
    }
    [oFindPanel orderOut:self];
    [oWebView searchFor:targetWord direction:NO caseSensitive:([oFindCaseIgnoreButton state] != NSOnState) wrap:NO];
}

- (void)printShowingPrintPanel:(BOOL)flag
{
    NSPrintInfo *printInfo = [self printInfo];

    [printInfo setTopMargin:50.0];
    [printInfo setBottomMargin:50.0];
    [printInfo setLeftMargin:30.0];
    [printInfo setRightMargin:30.0];
    [printInfo setHorizontallyCentered:NO];
    [printInfo setVerticallyCentered:NO];
    
    WebPreferences *pref = [WebPreferences standardPreferences];
    [pref setShouldPrintBackgrounds:YES];    

    NSView *documentView = [[[oWebView mainFrame] frameView] documentView];
    
    NSPrintOperation *printOperation = [NSPrintOperation printOperationWithView:documentView printInfo:printInfo];
    [printOperation setShowPanels:flag];
    [printOperation setCanSpawnSeparateThread:NO];    
    
    [printOperation runOperationModalForWindow:oMainWindow
                                      delegate:self 
                                didRunSelector:@selector(_printOperationDidRun:success:contextInfo:) 
                                   contextInfo:NULL];    
}

- (void)_printOperationDidRun:(NSPrintOperation*)printOperation 
                      success:(BOOL)success 
                  contextInfo:(void*)contextInfo
{
}

- (void)frameworkListDoubleClicked:(id)sender
{
    int selectedRow = [oFrameworkListView selectedRow];
    if (selectedRow < 0) {
        return;
    }
    CBNode *theNode = [oFrameworkListView itemAtRow:selectedRow];
    
    NSDocumentController *docController = [NSDocumentController sharedDocumentController];
    CBDocument *newDoc = [docController openUntitledDocumentOfType:@"DocumentType" display:YES];
    [newDoc showNodeForDoubleClickOpen:theNode];
}

- (void)browserDoubleClicked:(id)sender
{
    CBNode *theNode = [self selectedNode];
    if (!theNode) {
        return;
    }
    NSDocumentController *docController = [NSDocumentController sharedDocumentController];
    CBDocument *newDoc = [docController openUntitledDocumentOfType:@"DocumentType" display:YES];
    [newDoc showNodeForDoubleClickOpen:theNode];
}
                            

//-------------------------------------------------------------------------
#pragma mark ==== Accessor Methods ====
//-------------------------------------------------------------------------

- (void)startLoadingIndicator
{
    [oLoadingIndicator startAnimation:self];
}

- (void)stopLoadingIndicator
{
    [oLoadingIndicator stopAnimation:self];
}

- (void)updateFrameworkList
{
    [oFrameworkListView reloadData];
//    CBNode *firstItem = [oFrameworkListView itemAtRow:0];
//    [oFrameworkListView expandItem:firstItem];
    
    [oStatusField setStringValue:@""];
    
    if ([mShowInfoStack count] > 0) {
        [self resolveNextShowInfoStack];
    } else {
        [self finishResolvingStack];
    }
}

- (void)updateBrowser
{
    [oBrowser loadColumnZero];    
}

- (void)updateColumn:(int)column
{
    [oBrowser reloadColumn:column];

    if ([mShowInfoStack count] > 0) {
        [self resolveNextShowInfoStack];
    } else {
        [self finishResolvingStack];
    }
}

- (void)updateWebView
{
    if ([mShowInfoStack count] == 0) {
        [oBrowser setEnabled:YES];
    }
    
    CBNode *selectedNode = [self selectedNode];
    if (!selectedNode) {
        return;
    }
    NSString *htmlStr = selectedNode.contentHTMLSource;
    if (!htmlStr) {
        CBNode *parentNode = selectedNode.parentNode;
        if (parentNode) {
            htmlStr = parentNode.contentHTMLSource;
        }
    }
    if (htmlStr) {
        [self setHTMLSource:htmlStr];
    }
    
    if (mLastSelectedNodeInFrameworkList) {
        NSInteger prevSelectedRow = [oFrameworkListView rowForItem:mLastSelectedNodeInFrameworkList];
        if (prevSelectedRow >= 0) {
            [oFrameworkListView selectRow:prevSelectedRow byExtendingSelection:NO];
        }
        mLastSelectedNodeInFrameworkList = nil;
    }
}

- (BOOL)canGoBack
{
    return ([mHistoryPastNodes count] >= 2);
}

- (BOOL)canGoForward
{
    return ([mHistoryFutureNodes count] >= 1);
}

- (void)validateHistoryButtons
{
    [oGoBackSegmentedControl setEnabled:[self canGoBack] forSegment:0];
    [oGoBackSegmentedControl setEnabled:[self canGoForward] forSegment:1];
}

- (void)addHistoryItemForNode:(CBNode *)targetNode
{
    if (!targetNode) {
        return;
    }
    // Future items are needless (because the future has been changed)
    [mHistoryFutureNodes removeAllObjects];

    if ([mHistoryPastNodes count] == 0 || [mHistoryPastNodes lastObject] != targetNode) {
        [mHistoryPastNodes addObject:targetNode];
    }
    
    // Enable/Disable history buttons
    [self validateHistoryButtons];
}

- (CBNode *)_platformNodeForName:(NSString *)targetName
{
    if (mLastBrowsedNode) {
        CBNode *ret = mLastBrowsedNode;
        while (ret.type != CBNodeTypePlatform) {
            ret = ret.parentNode;
        }
        return ret;
    }
    return [self nodeForPlatform:targetName];
}

- (void)resolveNextShowInfoStack
{
    if ([mShowInfoStack count] == 0) {
        [self finishResolvingStack];
        return;
    }
    CBNavigationInfo *aNaviInfo = [[mShowInfoStack lastObject] retain];
    [mShowInfoStack removeLastObject];
    
    NSString *searchWordForFinish = nil;
    
    // Navigate to Platform
    if (aNaviInfo.type == CBNavigationTypePlatform) {
        CBNode *platformNode = [self _platformNodeForName:aNaviInfo.targetName];
        int platformNodeRow = [oFrameworkListView rowForItem:platformNode];
        if (platformNodeRow >= 0) {
            [oFrameworkListView selectRow:platformNodeRow byExtendingSelection:NO];
            [oFrameworkListView expandItem:platformNode];
            mCurrentPlatformNode = platformNode;
            if (!platformNode.isLoaded) {
                [platformNode startLoad];
                return;
            }
        } else {
            NSLog(@"Failed to navigate to platform: %@", aNaviInfo.targetName);
        }
    }
    // Navigate to Framework Folder
    else if (aNaviInfo.type == CBNavigationTypeFrameworkFolder) {
        CBNode *frameworkFolderNode = [mCurrentPlatformNode childNodeWithTitle:aNaviInfo.targetName];
        // フレームワーク・フォルダは常にロード済み
        int frameworkFolderNodeRow = [oFrameworkListView rowForItem:frameworkFolderNode];
        if (frameworkFolderNodeRow >= 0) {
            [oFrameworkListView selectRow:frameworkFolderNodeRow byExtendingSelection:NO];
            [oFrameworkListView expandItem:frameworkFolderNode];
            mCurrentFrameworkFolderNode = frameworkFolderNode;
        } else {
            NSLog(@"Failed to navigate to framework folder: %@", aNaviInfo.targetName);
        }
    }
    // Navigate to Framework
    else if (aNaviInfo.type == CBNavigationTypeFramework) {
        CBNode *frameworkNode = [mCurrentFrameworkFolderNode childNodeWithTitle:aNaviInfo.targetName];
        int frameworkNodeRow = [oFrameworkListView rowForItem:frameworkNode];
        if (frameworkNodeRow >= 0) {
            [oFrameworkListView selectRow:frameworkNodeRow byExtendingSelection:NO];
            [oFrameworkListView expandItem:frameworkNode];
            mCurrentFrameworkNode = frameworkNode;
            if (!frameworkNode.isLoaded) {
                [frameworkNode startLoad];
                return;
            }
        } else {
            NSLog(@"Failed to navigate to framework: %@", aNaviInfo.targetName);
        }
    }
    // Navigate to Class List Level
    else if (aNaviInfo.type == CBNavigationTypeReferences) {
        CBNode *referencesNode = [mCurrentFrameworkNode childNodeWithTitle:aNaviInfo.targetName];
        int referencesNodeRow = [oFrameworkListView rowForItem:referencesNode];
        if (referencesNodeRow >= 0) {
            [oFrameworkListView selectRow:referencesNodeRow byExtendingSelection:NO];
            [oFrameworkListView expandItem:referencesNode];
            mCurrentReferencesNode = referencesNode;
            [oBrowser reloadColumn:0];
        } else {
            NSLog(@"Failed to navigate to references: %@", aNaviInfo.targetName);
        }
    }
    // Navigate to Class Level
    else if (aNaviInfo.type == CBNavigationTypeClassLevel) {
        CBNode *classLevelNode = [mCurrentReferencesNode childNodeWithTitle:aNaviInfo.targetName];
        int classLevelNodeRow = [mCurrentReferencesNode indexOfChildNode:classLevelNode];
        if (classLevelNodeRow >= 0) {
            [oBrowser selectRow:classLevelNodeRow inColumn:0];
            mCurrentClassLevelNode = classLevelNode;
            if ([mShowInfoStack count] == 0) {
                [self addHistoryItemForNode:classLevelNode];
                [oMainWindow makeFirstResponder:oBrowser];
            }
            if (!classLevelNode.isLoaded) {
                [classLevelNode startLoad];
                return;
            }
        } else {
            NSLog(@"Failed to navigate to class level: %@", aNaviInfo.targetName);
        }
    }
    // Navigate to Category
    else if (aNaviInfo.type == CBNavigationTypeCategory) {
        CBNode *categoryNode = [mCurrentClassLevelNode childNodeWithTitle:aNaviInfo.targetName];
        int categoryNodeRow = [mCurrentClassLevelNode indexOfChildNode:categoryNode];
        if (categoryNodeRow >= 0) {
            [oBrowser selectRow:categoryNodeRow inColumn:1];
            mCurrentCategoryNode = categoryNode;
            if ([mShowInfoStack count] == 0) {
                [oMainWindow makeFirstResponder:oBrowser];
            }
        } else {
            NSLog(@"Failed to navigate to category level: %@", aNaviInfo.targetName);
        }
    }
    // Navigate to Method Level
    else if (aNaviInfo.type == CBNavigationTypeMethodLevel) {
        CBNode *methodLevelNode = nil;
        if ([mCurrentCategoryNode.title isEqualToString:@"Constants"]) {
            methodLevelNode = [mCurrentCategoryNode childNodeWithContent:[NSString stringWithFormat:@"title=\"%@\"", aNaviInfo.targetName]];
            if (!methodLevelNode) {
                methodLevelNode = [mCurrentCategoryNode childNodeWithContent:aNaviInfo.targetName];
            }
            searchWordForFinish = aNaviInfo.targetName;
        } else {
            methodLevelNode = [mCurrentCategoryNode childNodeWithTitle:aNaviInfo.targetName];
        }
        int methodLevelNodeRow = [mCurrentCategoryNode indexOfChildNode:methodLevelNode];
        if (methodLevelNodeRow >= 0) {
            [oBrowser selectRow:methodLevelNodeRow inColumn:2];
            if ([mShowInfoStack count] == 0) {
                [self addHistoryItemForNode:methodLevelNode];
                [oMainWindow makeFirstResponder:oBrowser];
            }
        } else {
            NSLog(@"Failed to navigate to method level: %@", aNaviInfo.targetName);
        }
    }
    // Otherwise
    else {
        NSLog(@"Unknown navigation type: %d (target=%@) (stack cleared)", aNaviInfo.type, aNaviInfo.targetName);
        [mShowInfoStack removeAllObjects];
    }
    
    if ([mShowInfoStack count] > 0) {
        [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(resolveNextShowInfoStack) userInfo:nil repeats:NO];
    } else {
        [self finishResolvingStack];
        [self updateWebView];
        if (searchWordForFinish) {
            [NSTimer scheduledTimerWithTimeInterval:0
                                             target:self
                                           selector:@selector(finalSearchProc:)
                                           userInfo:searchWordForFinish
                                            repeats:NO];
        }
    }
}

- (void)finishResolvingStack
{
    if (!mIsResolvingStacks) {
        return;
    }
    mIsResolvingStacks = NO;
    [oFullSearchField setStringValue:@""];
    [self validateSearch];
}

- (void)finalSearchProc:(NSTimer *)theTimer
{
    NSString *searchWord = (NSString *)[theTimer userInfo];
    
    NSString *source = [[NSString alloc] initWithData:[[[oWebView mainFrame] dataSource] data] encoding:NSUTF8StringEncoding];
    NSRange titleRange = [source rangeOfString:[NSString stringWithFormat:@"title=\"%@\"", searchWord]];
    if (titleRange.location != NSNotFound) {
        NSRange nameStartRange = [source rangeOfString:@"name=\"" options:NSBackwardsSearch range:NSMakeRange(0, titleRange.location)];
        if (nameStartRange.location != NSNotFound) {
            unsigned length = [source length];
            NSRange endRange = [source rangeOfString:@"\"" options:0 range:NSMakeRange(nameStartRange.location+6, length-(nameStartRange.location+6))];
            if (endRange.location != NSNotFound) {
                NSString *name = [source substringWithRange:NSMakeRange(nameStartRange.location+6, endRange.location-(nameStartRange.location+6))];
                WebScriptObject *wso = [oWebView windowScriptObject];
                [wso evaluateWebScript:[NSString stringWithFormat:@"location.hash = \"%@\";", name]];
            }
        }
    } else {
        [oWebView searchFor:searchWord direction:YES caseSensitive:NO wrap:NO];
    }
}

- (void)startSearchWithStr:(NSString *)str
{
    CBNode *selectedNode = [self selectedNode];
    if (!selectedNode) {
        return;
    }
    CBNodeType type = selectedNode.type;
    if (type == CBNodeTypeClassLevel || type == CBNodeTypeReferences) {
        if (type == CBNodeTypeClassLevel) {
            mFilteredReferencesNode = selectedNode.parentNode;
        } else {
            mFilteredReferencesNode = selectedNode;
        }
        [oSearchField1 setStringValue:str];
        [oSearchButton1 setHidden:YES];
        [oSearchField1 setHidden:NO];
        [oMainWindow makeFirstResponder:oSearchField1];
        NSTextView *fieldEditor = (NSTextView *)[oMainWindow fieldEditor:NO forObject:oSearchField1];
        [fieldEditor setSelectedRange:NSMakeRange(1, 0)];
        [fieldEditor setAllowedInputSourceLocales:[NSArray arrayWithObject:NSAllRomanInputSourcesLocaleIdentifier]];
        
        if (!mIsSearchBarShown) {
            [self showSearchBar];
        }
    }
    else if (type == CBNodeTypeMethodLevel || type == CBNodeTypeCategory) {
        if (type == CBNodeTypeMethodLevel) {
            mFilteredCategoryNode = selectedNode.parentNode;
        } else {
            mFilteredCategoryNode = selectedNode;
        }
        [oSearchField3 setStringValue:str];
        [oSearchButton3 setHidden:YES];
        [oSearchField3 setHidden:NO];
        [oMainWindow makeFirstResponder:oSearchField3];
        NSTextView *fieldEditor = (NSTextView *)[oMainWindow fieldEditor:NO forObject:oSearchField3];
        [fieldEditor setSelectedRange:NSMakeRange(1, 0)];
        [fieldEditor setAllowedInputSourceLocales:[NSArray arrayWithObject:NSAllRomanInputSourcesLocaleIdentifier]];

        if (!mIsSearchBarShown) {
            [self showSearchBar];
        }
    }
    
    [self validateSearch];
}

- (void)activateFrameworkListView
{
    [oMainWindow makeFirstResponder:oFrameworkListView];
}

- (void)activateBrowser
{
    [oMainWindow makeFirstResponder:oBrowser];
}

- (void)activateWebView
{
    [oMainWindow makeFirstResponder:oWebView];
}

- (void)validateSearch
{
    CBNode *selectedNode = [self selectedNode];
    if (!selectedNode) {
        return;
    }
    
    // References or category can be filtered
    CBNodeType type = selectedNode.type;
    if (type == CBNodeTypeClassLevel) {
        selectedNode = selectedNode.parentNode;
    } else if (type == CBNodeTypeMethodLevel) {
        selectedNode = selectedNode.parentNode;
    }

    // Do filter
    if (selectedNode.type == CBNodeTypeReferences) {
        NSString *searchWord = [oSearchField1 stringValue];
        mFilteringNode = selectedNode;
        [selectedNode setFilteringStr:searchWord];
        mFilteredReferencesNode = selectedNode;
        if ([searchWord length] == 0) {
            mFilteredReferencesNode = nil;
        }
        [oBrowser reloadColumn:0];
    } else if (selectedNode.type == CBNodeTypeCategory) {
        NSString *searchWord = [oSearchField3 stringValue];
        mFilteringNode = selectedNode;
        [selectedNode setFilteringStr:searchWord];
        mFilteredCategoryNode = selectedNode;
        if ([searchWord length] == 0) {
            mFilteredCategoryNode = nil;
        }
        [oBrowser reloadColumn:2];
    }
}

- (void)selectFirstRowOfFilteringColumn
{
    if (!mFilteringNode) {
        return;
    }
    int targetColumn = -1;
    if (mFilteringNode.type == CBNodeTypeReferences) {
        targetColumn = 0;
    } else if (mFilteringNode.type == CBNodeTypeCategory) {
        targetColumn = 2;
    }

    if (targetColumn >= 0) {
        int targetRow = [oBrowser selectedRowInColumn:targetColumn];
        if (targetRow < 0) {
            targetRow = 0;
        }
        CBNode *targetNode = [self nodeForRow:targetRow column:targetColumn];
        if (targetNode) {
            [oBrowser selectRow:targetRow inColumn:targetColumn];
            [oMainWindow makeFirstResponder:oBrowser];
            if (!targetNode.isLoaded) {
                //[[CBAppController sharedAppController] fetchDataForNode:targetNode column:targetColumn];
                [targetNode startLoad];
                return;
            }
            [self updateWebView];
        } else {
            NSBeep();
        }
    }
}

- (void)_showNodeInFrameworkView:(CBNode *)targetNode
{
    NSMutableArray *nodesToBeShown = [NSMutableArray array];
    [nodesToBeShown addObject:targetNode];
    CBNode *aNode = targetNode.parentNode;
    while (aNode) {
        [nodesToBeShown addObject:aNode];
        int nodeRow = [oFrameworkListView rowForItem:aNode];
        if (nodeRow >= 0) {
            break;
        }
        aNode = aNode.parentNode;
    }
    while ([nodesToBeShown count] > 0) {
        CBNode *aNode = [nodesToBeShown lastObject];
        [nodesToBeShown removeLastObject];
        [oFrameworkListView expandItem:aNode];
        if ([nodesToBeShown count] == 0) {
            int row = [oFrameworkListView rowForItem:aNode];
            if (row >= 0) {
                [oFrameworkListView selectRow:row byExtendingSelection:NO];
            }
            if (aNode.type >= CBNodeTypeReferences) {
                mCurrentReferencesNode = aNode;
            } else {
                mCurrentReferencesNode = nil;
            }
            [self updateBrowser];
        }
    }
}

- (void)_showNodeInBrowser:(CBNode *)targetNode
{
    // Select Node in Framework List at first
    CBNode *lastNodeInFrameworkView = [targetNode lastParentNodeInFrameworkView];
    [self _showNodeInFrameworkView:lastNodeInFrameworkView];
    
    // Select Node in Browser
    NSMutableArray *nodesToBeShown = [NSMutableArray array];
    [nodesToBeShown addObject:targetNode];
    CBNode *aNode = targetNode.parentNode;
    while (![aNode isInFrameworkView]) {
        [nodesToBeShown addObject:aNode];
        aNode = aNode.parentNode;
    }
    int column = 0;
    while ([nodesToBeShown count] > 0) {
        CBNode *aNode = [nodesToBeShown lastObject];
        [nodesToBeShown removeLastObject];
        if (!aNode.isLoaded) {
            // ここ、これより下のヤツの読み込みを考えなくてもいいのだろうか。。。とりあえず動いてるからいいか（ぁ。
            //[[CBAppController sharedAppController] fetchDataForNode:aNode column:column];
            [aNode startLoad];
        }
        CBNode *parent = aNode.parentNode;
        int row = [parent indexOfChildNode:aNode];
        if (row != [oBrowser selectedRowInColumn:column]) {
            [oBrowser selectRow:row inColumn:column];
            if (column < 2) {
                [oBrowser reloadColumn:column+1];
            }
        }
        column++;
    }
    [self updateWebView];
}

- (void)showNode:(CBNode *)targetNode
{
    mIsManuallyShowingNode = YES;
    if ([targetNode isInFrameworkView]) {
        [self _showNodeInFrameworkView:targetNode];
        [oMainWindow makeFirstResponder:oFrameworkListView];
    } else {
        [self _showNodeInBrowser:targetNode];
        [oMainWindow makeFirstResponder:oBrowser];
    }
    mIsManuallyShowingNode = NO;
}

- (void)showNodeForDoubleClickOpen:(CBNode *)node
{
    NSMutableArray *nodesToOpen = [NSMutableArray array];
    
    CBNode *theNode = node;
    while (theNode.parentNode) {
        [nodesToOpen addObject:theNode];
        theNode = theNode.parentNode;
    }
    
    int browserColumn = 0;
    for (CBNode *aNode in [nodesToOpen reverseObjectEnumerator]) {
        int row = [oFrameworkListView rowForItem:aNode];
        if (row >= 0) {
            [oFrameworkListView selectRow:row byExtendingSelection:NO];
            [oFrameworkListView expandItem:aNode];
        } else {
            int row = [aNode.parentNode indexOfChildNode:aNode];
            [oBrowser selectRow:row inColumn:browserColumn];
            browserColumn++;
        }
    }
    
    if (!node.isLoaded) {
        [node startLoad];
    }
}

- (void)reloadFrameworkList
{
    [oFrameworkListView reloadData];
}

- (void)hideSearchBar
{
    if (!mIsSearchBarShown) {
        return;
    }
    mIsSearchBarShown = NO;

    NSMutableArray *animationInfos = [NSMutableArray array];
    
    {
        NSMutableDictionary *animInfo = [NSMutableDictionary dictionary];
        [animationInfos addObject:animInfo];

        [animInfo setObject:oSearchBarView forKey:NSViewAnimationTargetKey];
        NSRect frame = [oSearchBarView frame];
        [animInfo setObject:[NSValue valueWithRect:frame] forKey:NSViewAnimationStartFrameKey];
        frame.origin.y += 24;
        [animInfo setObject:[NSValue valueWithRect:frame] forKey:NSViewAnimationEndFrameKey];
    }
    
    {
        NSMutableDictionary *animInfo = [NSMutableDictionary dictionary];
        [animationInfos addObject:animInfo];

        [animInfo setObject:oBrowser forKey:NSViewAnimationTargetKey];
        NSRect frame = [oBrowser frame];
        [animInfo setObject:[NSValue valueWithRect:frame] forKey:NSViewAnimationStartFrameKey];
        frame.size.height += 24;
        [animInfo setObject:[NSValue valueWithRect:frame] forKey:NSViewAnimationEndFrameKey];
    }

    NSViewAnimation *anim = [[NSViewAnimation alloc] initWithViewAnimations:animationInfos];
    [anim setDuration:0.20];
    [anim setAnimationCurve:NSAnimationEaseIn];
    
    [anim startAnimation];
    [anim release];
}

- (void)showSearchBar
{
    if (mIsSearchBarShown) {
        return;
    }
    mIsSearchBarShown = YES;

    NSMutableArray *animationInfos = [NSMutableArray array];

    {
        NSMutableDictionary *animInfo = [NSMutableDictionary dictionary];
        [animationInfos addObject:animInfo];

        [animInfo setObject:oSearchBarView forKey:NSViewAnimationTargetKey];
        NSRect frame = [oSearchBarView frame];
        [animInfo setObject:[NSValue valueWithRect:frame] forKey:NSViewAnimationStartFrameKey];
        frame.origin.y -= 24;
        [animInfo setObject:[NSValue valueWithRect:frame] forKey:NSViewAnimationEndFrameKey];
    }

    {
        NSMutableDictionary *animInfo = [NSMutableDictionary dictionary];
        [animationInfos addObject:animInfo];
        
        [animInfo setObject:oBrowser forKey:NSViewAnimationTargetKey];
        NSRect frame = [oBrowser frame];
        [animInfo setObject:[NSValue valueWithRect:frame] forKey:NSViewAnimationStartFrameKey];
        frame.size.height -= 24;
        [animInfo setObject:[NSValue valueWithRect:frame] forKey:NSViewAnimationEndFrameKey];
    }
    
    NSViewAnimation *anim = [[NSViewAnimation alloc] initWithViewAnimations:animationInfos];
    [anim setDuration:0.20];
    [anim setAnimationCurve:NSAnimationEaseIn];
    
    [anim startAnimation];
    [anim release];
}

- (void)validateSearchBarShowing
{
    // 自動的に検索バーを隠す
    if ([[CBAppController sharedAppController] hidesSearchBarAutomatically]) {
        if (mIsSearchBarShown) {
            NSString *searchWord1 = [[oSearchField1 stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSString *searchWord3 = [[oSearchField3 stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if ([searchWord1 length] == 0 && [searchWord3 length] == 0) {
                [self hideSearchBar];
            }
        }
    }
    // 隠さない
    else {
        if (!mIsSearchBarShown) {
            [self showSearchBar];
        }
    }
}

- (void)clearAllSearchWords
{
    //[oFullSearchField setStringValue:@""];
    [oSearchField1 setStringValue:@""];
    [oSearchField3 setStringValue:@""];
    
    [self deactivateSearchField1:self];
    [self deactivateSearchField3:self];

    if (mFilteredCategoryNode) {
        [mFilteredCategoryNode setFilteringStr:nil];
        mFilteredCategoryNode = nil;
    }
    if (mFilteredReferencesNode) {
        [mFilteredReferencesNode setFilteringStr:nil];
        mFilteredReferencesNode = nil;
    }

    int selectedRow = [oFrameworkListView selectedRow];
    CBNode *targetNode = [oFrameworkListView itemAtRow:selectedRow];
    
    [oSearchButton2 fadeOut:0.25];
    [oSearchButton3 fadeOut:0.25];
    
    if (targetNode.type == CBNodeTypeReferences) {
        if ([targetNode.title hasSuffix:@"Class References"]) {
            [oSearchButton1 setTitle:NSLocalizedString(@"Class Names", nil)];
            [oSearchButton1 fadeIn:0.25];
        }
        else if ([targetNode.title isEqualToString:@"Protocol References"]) {
            [oSearchButton1 setTitle:NSLocalizedString(@"Protocol Names", nil)];
            [oSearchButton1 fadeIn:0.25];
        }
        else if ([targetNode.title isEqualToString:@"Opaque Type References"]) {
            [oSearchButton1 setTitle:NSLocalizedString(@"Type Names", nil)];
            [oSearchButton1 fadeIn:0.25];
        }
        else {
            [oSearchButton1 fadeOut:0.25];
        }
    } else {
        [oSearchButton1 fadeOut:0.25];
    }
    
    if ([[CBAppController sharedAppController] hidesSearchBarAutomatically]) {
        [self hideSearchBar];
    }
}

- (void)showFullSearchResultsView
{
    if (mIsFullSearchResultShown) {
        return;
    }
    
    mIsFullSearchResultShown = YES;
    
    NSMutableDictionary *dict1 = [NSMutableDictionary dictionary];
    {
        [dict1 setObject:oBrowserSplitView forKey:NSViewAnimationTargetKey];
        NSRect frame = [oBrowserSplitView frame];
        [dict1 setObject:[NSValue valueWithRect:frame] forKey:NSViewAnimationStartFrameKey];
        frame.size.height -= [oFullSearchResultViewBox frame].size.height - 2 + 5;
        [dict1 setObject:[NSValue valueWithRect:frame] forKey:NSViewAnimationEndFrameKey];
    }
    
    NSViewAnimation *anim = [[NSViewAnimation alloc]
                             initWithViewAnimations:[NSArray arrayWithObjects:dict1, nil]];
    [anim setDuration:0.30];
    [anim setAnimationCurve:NSAnimationEaseIn];
    
    [anim startAnimation];
    [anim release];
}

- (void)hideFullSearchResultsView
{
    if (!mIsFullSearchResultShown) {
        return;
    }
    
    mIsFullSearchResultShown = NO;
    
    NSMutableDictionary *dict1 = [NSMutableDictionary dictionary];
    {
        [dict1 setObject:oBrowserSplitView forKey:NSViewAnimationTargetKey];
        NSRect frame = [oBrowserSplitView frame];
        [dict1 setObject:[NSValue valueWithRect:frame] forKey:NSViewAnimationStartFrameKey];
        frame.size.height += [oFullSearchResultViewBox frame].size.height - 2 + 5;
        [dict1 setObject:[NSValue valueWithRect:frame] forKey:NSViewAnimationEndFrameKey];
    }
    
    NSViewAnimation *anim = [[NSViewAnimation alloc]
                             initWithViewAnimations:[NSArray arrayWithObjects:dict1, nil]];
    [anim setDuration:0.30];
    [anim setAnimationCurve:NSAnimationEaseIn];
    
    [anim startAnimation];
    [anim release];
}


//-------------------------------------------------------------------------
#pragma mark ==== Accessor Methods for Nodes ====
//-------------------------------------------------------------------------

- (CBNode *)nodeForPlatform:(NSString *)platformName
{
    CBAppController *appController = [CBAppController sharedAppController];
    CBNode *rootNode = [appController rootNode];
    return [rootNode childNodeWithTitle:platformName];
}

- (CBNode *)nodeForFramework:(NSString *)frameworkName
{
    CBAppController *appController = [CBAppController sharedAppController];
    CBNode *rootNode = [appController rootNode];
    int platformCount = [rootNode childNodeCount];
    for (int i = 0; i < platformCount; i++) {
        CBNode *platformNode = [rootNode childNodeAtIndex:i];
        int folderCount = [platformNode childNodeCount];
        for (int j = 0; j < folderCount; j++) {
            CBNode *folderNode = [platformNode childNodeAtIndex:j];
            CBNode *theNode = [folderNode childNodeWithTitle:frameworkName];
            if (theNode) {
                return theNode;
            }
        }
    }
    return nil;
}

- (int)nodeCountForColumn:(int)column
{
    if (!mCurrentReferencesNode) {
        return 0;
    }
    CBNode *lastParentNode = mCurrentReferencesNode;
    for (int i = 0; i < column; i++) {
        int selectedRow = [oBrowser selectedRowInColumn:i];
        lastParentNode = [lastParentNode childNodeAtIndex:selectedRow];
    }
    return [lastParentNode childNodeCount];
}

- (CBNode *)nodeForRow:(int)row column:(int)column
{
    if (!mCurrentReferencesNode) {
        return nil;
    }
    CBNode *lastParentNode = mCurrentReferencesNode;
    for (int i = 0; i < column; i++) {
        int selectedRow = [oBrowser selectedRowInColumn:i];
        lastParentNode = [lastParentNode childNodeAtIndex:selectedRow];
    }
    return [lastParentNode childNodeAtIndex:row];
}

- (CBNode *)selectedNode
{
    int frameworkRow = [oFrameworkListView selectedRow];
    if (frameworkRow < 0) {
        return nil;
    }
    CBNode *frameworkListNode = [oFrameworkListView itemAtRow:frameworkRow];
    if (frameworkListNode.type != CBNodeTypeReferences && frameworkListNode.type != CBNodeTypeDocument) {
        return nil;
    }
    int browserColumn = [oBrowser selectedColumn];
    if (browserColumn < 0) {
        return frameworkListNode;
    }
    int browserRow = [oBrowser selectedRowInColumn:browserColumn];
    return [self nodeForRow:browserRow column:browserColumn];
}

- (int)indexOfColumnZeroNode:(CBNode *)node
{
    CBAppController *appController = [CBAppController sharedAppController];
    CBNode *rootNode = [appController rootNode];
    int ret = 0;
    int frameworkCount = [rootNode childNodeCount];
    for (int i = 0; i < frameworkCount; i++) {
        CBNode *frameworkNode = [rootNode childNodeAtIndex:i];
        if (frameworkNode == node) {
            return ret;
        }
        ret++;
        if (frameworkNode.isLoaded) {
            int childCount = [frameworkNode childNodeCount];
            for (int j = 0; j < childCount; j++) {
                CBNode *childNode = [frameworkNode childNodeAtIndex:j];
                if (childNode == node) {
                    return ret;
                }
                ret++;
            }
        }
    }
    return -1;
}

- (void)setHTMLSource:(NSString *)htmlSource
{
    NSString *originalSource = htmlSource;
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *cssFilePath = [bundle pathForResource:@"stylesheet" ofType:@"css"];
    NSData *cssData = [NSData dataWithContentsOfFile:cssFilePath];
    NSString *cssStr = [[[NSString alloc] initWithData:cssData encoding:NSUTF8StringEncoding] autorelease];
    cssStr = [NSString stringWithFormat:@"<style>\n%@\n</style>\n", cssStr];
    
    htmlSource = [cssStr stringByAppendingString:htmlSource];
    
    [oWebView loadHTMLString:htmlSource];
    
    NSMutableAttributedString *sourceAttrStr = [oSourceView textStorage];
    [sourceAttrStr setAttributedString:[[[NSAttributedString alloc] initWithString:originalSource] autorelease]];
}


//-------------------------------------------------------------------------
#pragma mark ==== Delegate Methods for Toolbar ====
//-------------------------------------------------------------------------

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects:
            sCBToolbarItemIdentifierGoBack,
            NSToolbarFlexibleSpaceItemIdentifier,
            sCBToolbarItemIdentifierLoading,
            sCBToolbarItemIdentifierSearch,
            nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects:
            sCBToolbarItemIdentifierGoBack,
            sCBToolbarItemIdentifierLoading,
            sCBToolbarItemIdentifierSearch,            
            NSToolbarSeparatorItemIdentifier,
            NSToolbarSpaceItemIdentifier,
            NSToolbarFlexibleSpaceItemIdentifier,
            NSToolbarCustomizeToolbarItemIdentifier,
            NSToolbarPrintItemIdentifier,            
            nil];
}

void _CBSetupToolbarView(NSToolbarItem *item, NSView *view)
{
    [item setView:view];
    NSSize viewSize = [view frame].size;
    [item setMinSize:viewSize];
    [item setMaxSize:viewSize];    
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
    
    // Localization will treat the actual name of each item
    [item setLabel:NSLocalizedString(itemIdentifier, nil)];
    [item setPaletteLabel:NSLocalizedString([itemIdentifier stringByAppendingString:@"_pallet"], nil)];
    
    // Initialize each item
    if ([itemIdentifier isEqualToString:sCBToolbarItemIdentifierGoBack]) {
        _CBSetupToolbarView(item, oGoBackSegmentedControl);
    } else if ([itemIdentifier isEqualToString:sCBToolbarItemIdentifierSearch]) {
        _CBSetupToolbarView(item, oFullSearchField);
    } else if ([itemIdentifier isEqualToString:sCBToolbarItemIdentifierLoading]) {
        _CBSetupToolbarView(item, oLoadingIndicator);
    }
    return item;
}

//-------------------------------------------------------------------------
#pragma mark ==== Delegate Methods for NSBrowser ====
//-------------------------------------------------------------------------

- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(NSInteger)row column:(NSInteger)column
{
    mLastSelectedNodeInFrameworkList = nil;

    CBNode *theNode = [self nodeForRow:row column:column];
    if (!theNode) {
        [cell setStringValue:[NSString stringWithFormat:@"--(null)--: %d, %d", row, column]];
        return;
    }
    
    // Set cell infos
    [cell setStringValue:[theNode localizedTitle]];
    [cell setLeaf:theNode.isLeaf];
    [cell setImage:theNode.image];
    if (theNode.isStrong) {
        [cell setFont:[NSFont fontWithName:@"LucidaGrande-Bold" size:12.0]];
    } else {
        [cell setFont:[NSFont fontWithName:@"LucidaGrande" size:12.0]];
    }    
}

- (NSInteger)browser:(NSBrowser *)sender numberOfRowsInColumn:(NSInteger)column
{
    return [self nodeCountForColumn:column];
}


//-------------------------------------------------------------------------
#pragma mark ==== Delegate Methods for WebView's Policy ====
//-------------------------------------------------------------------------

- (void)webView:(WebView *)sender decidePolicyForNewWindowAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request newFrameName:(NSString *)frameName decisionListener:(id < WebPolicyDecisionListener >)listener
{
    [listener ignore];

    // Redirect it to Safari
    NSURL *requestedURL = [request URL];
    [[NSWorkspace sharedWorkspace] openURL:requestedURL];
}

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id < WebPolicyDecisionListener >)listener
{
    WebNavigationType navType = [[actionInformation objectForKey:WebActionNavigationTypeKey] intValue];
    if (navType != WebNavigationTypeLinkClicked) {
        [listener use];
        return;
    }
    
    [listener ignore];

    if (![oBrowser isEnabled]) {
        return;
    }

    NSURL *requestedURL = [request URL];
    
    int modifiers = [[actionInformation objectForKey:WebActionModifierFlagsKey] intValue];

    mLastBrowsedNode = [self selectedNode];
    
    NSArray *stack = [requestedURL makeNavigationInfos];
    if (stack) {
        if (modifiers & NSCommandKeyMask) {
            NSDocumentController *docController = [NSDocumentController sharedDocumentController];
            CBDocument *newDoc = [docController openUntitledDocumentOfType:@"DocumentType" display:YES];
            [newDoc resolveStackForNewWindowOpen:stack];
        } else {
            /*NSLog(@"====");
            for (CBNavigationInfo *info in stack) {
                NSLog(@":: %@", info);
            }
            NSLog(@"====");*/
            mIsResolvingStacks = YES;
            [mShowInfoStack addObjectsFromArray:stack];
            [self resolveNextShowInfoStack];
        }
    } else {
        [[NSWorkspace sharedWorkspace] openURL:requestedURL];
    }
}

- (void)resolveStackForNewWindowOpen:(NSArray *)stack
{
    [mShowInfoStack addObjectsFromArray:stack];
    [self resolveNextShowInfoStack];
}

//-------------------------------------------------------------------------
#pragma mark ==== Delegate Methods for WebView's UI ====
//-------------------------------------------------------------------------

- (void)webView:(WebView *)sender mouseDidMoveOverElement:(NSDictionary *)elementInformation modifierFlags:(NSUInteger)modifierFlags
{
    NSNumber *linkIsLiveObj = [elementInformation objectForKey:@"WebElementLinkIsLive"];
    if (linkIsLiveObj && [linkIsLiveObj boolValue]) {
        NSURL *URL = [elementInformation objectForKey:@"WebElementLinkURL"];
        CBReferenceInfo *refInfo = [URL makeReferenceInfo];
        if (refInfo) {
            [oStatusField setStringValue:[refInfo statusText]];
        } else {
            [oStatusField setStringValue:[URL absoluteString]];
        }
    } else {
        [oStatusField setStringValue:@""];
    }
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems
{
    NSMutableArray *ret = [NSMutableArray array];

    for (NSMenuItem *anItem in defaultMenuItems) {
        int tag = [anItem tag];
        if (tag != WebMenuItemTagReload &&
            tag != WebMenuItemTagOpenLinkInNewWindow &&
            tag != WebMenuItemTagOpenImageInNewWindow &&
            tag != WebMenuItemTagOpenFrameInNewWindow &&
            tag != WebMenuItemTagDownloadImageToDisk &&
            tag != 2000 // "Open Link"
            )
        {
            NSLog(@"%@, %d", [anItem title], tag);
            [ret addObject:anItem];
        }
    }
    if ([ret count] > 0) {
        [ret addObject:[NSMenuItem separatorItem]];
    }
    
    NSMenuItem *viewSourceItem = [[[NSMenuItem alloc] init] autorelease];
    [viewSourceItem setTitle:NSLocalizedString(@"CMI View HTML Source", nil)];
    [viewSourceItem setTarget:self];
    [viewSourceItem setAction:@selector(viewSource:)];
    [ret addObject:viewSourceItem];
    
    return ret;
}


//-------------------------------------------------------------------------
#pragma mark ==== Delegate Methods for Framework List Outline View ====
//-------------------------------------------------------------------------

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (outlineView == oFrameworkListView) {
        CBAppController *appController = [CBAppController sharedAppController];
        CBNode *rootNode = [appController rootNode];
        if (!item) {
            return [rootNode enabledChildNodeCount];
        } else {
            CBNodeType type = ((CBNode *)item).type;
            if (type == CBNodeTypePlatform ||
                type == CBNodeTypeFrameworkFolder ||
                type == CBNodeTypeFramework)
            {
                return [item childNodeCount];
            } else {
                return 0;
            }
        }
    }
    else if (outlineView == oFullSearchResultView) {
        return 20;
    }
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if (outlineView == oFrameworkListView) {
        CBOutlineViewCell *cell = [tableColumn dataCell];
        cell.node = (CBNode *)item;
        
        return [(CBNode *)item localizedTitle];
    }
    else if (outlineView == oFullSearchResultView) {
        return @"test";
    }
    return nil;
}

/*- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
    if (outlineView == oFullSearchResultView) {
        return 5.0f;
    }
    return 20.0f;
}*/

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (outlineView == oFrameworkListView) {
        if (!item) {
            CBAppController *appController = [CBAppController sharedAppController];
            CBNode *rootNode = [appController rootNode];
            return [rootNode enabledChildNodeAtIndex:index];
        }
        return [(CBNode *)item childNodeAtIndex:index];
    }
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if (outlineView == oFrameworkListView) {
        return (((CBNode *)item).type <= CBNodeTypeFramework);
    }
    return NO;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    id sourceObj = [notification object];
    if (sourceObj == oFrameworkListView) {
        if (mIsManuallyShowingNode || mIsResolvingStacks) {
            return;
        }
        
        [self clearAllSearchWords];
        
        int selectedRow = [oFrameworkListView selectedRow];
        CBNode *targetNode = [oFrameworkListView itemAtRow:selectedRow];
#ifdef __DEBUG__
        NSLog(@"Target Node: %@", targetNode);
#endif

        // Add History Item
        [self addHistoryItemForNode:targetNode];

        // Perform loading & updating
        if (targetNode.type == CBNodeTypeReferences || targetNode.type == CBNodeTypeDocument) {
            mCurrentReferencesNode = targetNode;
            if (!targetNode.isLoaded) {
#ifdef __DEBUG__
                NSLog(@"   -> startLoad");
#endif
                [targetNode startLoad];
            }
        }
        else {
            mCurrentReferencesNode = nil;
        }
        [self updateBrowser];
    }
}

- (void)outlineViewItemWillExpand:(NSNotification *)notification
{
    id sourceObj = [notification object];
    if (sourceObj == oFrameworkListView) {
        mLastSelectedNodeInFrameworkList = nil;
        if (mIsManuallyShowingNode || mIsResolvingStacks) {
            return;
        }
        CBNode *targetNode = [[notification userInfo] objectForKey:@"NSObject"];
        [self addHistoryItemForNode:targetNode];
        if (!targetNode.isLoaded) {
            NSInteger selectedRow = [oFrameworkListView selectedRow];
            mLastSelectedNodeInFrameworkList = [oFrameworkListView itemAtRow:selectedRow];
            [targetNode startLoad];
        }
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
    if (outlineView == oFrameworkListView) {
        CBNode *theNode = (CBNode *)item;
        return (theNode && (theNode.type <= CBNodeTypeFrameworkFolder));
    }
    return NO;
}

/*- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item
{
    CBNode *theNode = (CBNode *)item;
    return (!theNode || theNode.type != CBNodeTypeRefFrameworkFolder ||
            ![theNode.title isEqualToString:NSLocalizedString(@"FL Main Frameworks", nil)]);
}*/

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    if (outlineView == oFrameworkListView) {
        //CBNode *theNode = (CBNode *)item;
        //return (!theNode || theNode.type != CBNodeTypeRefFrameworkFolder);
        return YES;
    }
    return YES;
}

/*- (void)outlineView:(NSOutlineView *)theOutlineView willDisplayOutlineCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    CBNode *theNode = (CBNode *)item;
    if (theNode && theNode.type == CBNodeTypeRefFrameworkFolder && [theNode.title isEqualToString:NSLocalizedString(@"FL Main Frameworks", nil)]) {
        [cell setTransparent:YES];
    } else {
        [cell setTransparent:NO];
    }
}*/


//-------------------------------------------------------------------------
#pragma mark ==== Delegate Methods for Split View (Vertical/Horizontal) ====
//-------------------------------------------------------------------------

- (void)controlTextDidBeginEditing:(NSNotification *)aNotification
{
    id sourceObj = [aNotification object];
    if (sourceObj == oFullSearchField) {
        NSTextView *fieldEditor = (NSTextView *)[oMainWindow fieldEditor:NO forObject:oFullSearchField];
        [fieldEditor setAllowedInputSourceLocales:[NSArray arrayWithObject:NSAllRomanInputSourcesLocaleIdentifier]];        
    }
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
    id sourceObj = [aNotification object];
    if (sourceObj == oFullSearchField) {
        NSString *searchWord = [[oFullSearchField stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([searchWord length] == 0) {
            [self hideFullSearchResultsView];
        }
    } else {
        [self validateSearch];
    }
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
    BOOL hideSearchBar = NO;

    id sourceObj = [aNotification object];
    if (sourceObj == oSearchField1) {
        if ([NSDate timeIntervalSinceReferenceDate] - mLastSearchFieldActivatedTime1 < 0.6) {
            [oMainWindow makeFirstResponder:oSearchField1];
            return;
        }
        
        NSString *searchWord = [[oSearchField1 stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([searchWord length] == 0) {
            hideSearchBar = YES;
            if ([oMainWindow firstResponder] != oSearchField1) {
                [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(deactivateSearchField1:) userInfo:nil repeats:NO];
            }
        }        
    }
    else if (sourceObj == oSearchField2) {
        if ([NSDate timeIntervalSinceReferenceDate] - mLastSearchFieldActivatedTime2 < 0.6) {
            [oMainWindow makeFirstResponder:oSearchField2];
            return;
        }
        
        NSString *searchWord = [[oSearchField2 stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([searchWord length] == 0) {
            hideSearchBar = YES;
            if ([oMainWindow firstResponder] != oSearchField2) {
                [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(deactivateSearchField2:) userInfo:nil repeats:NO];
            }
        }
    }
    else if (sourceObj == oSearchField3) {
        if ([NSDate timeIntervalSinceReferenceDate] - mLastSearchFieldActivatedTime3 < 0.6) {
            [oMainWindow makeFirstResponder:oSearchField3];
            return;
        }
        
        NSString *searchWord = [[oSearchField3 stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([searchWord length] == 0) {
            hideSearchBar = YES;
            if ([oMainWindow firstResponder] != oSearchField3) {
                [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(deactivateSearchField3:) userInfo:nil repeats:NO];
            }
        }
    }
    
    if (hideSearchBar && [[CBAppController sharedAppController] hidesSearchBarAutomatically]) {
        NSString *searchWord1 = [[oSearchField1 stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *searchWord3 = [[oSearchField3 stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([searchWord1 length] == 0 && [searchWord3 length] == 0) {
            [self hideSearchBar];
        }
    }    
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{
    // クラス名検索
    if (control == oSearchField1) {
        // ESCキー（検索文字列を消してブラウザをアクティブにする（フォーカスを検索フィールドに残したままの方がいいかも？？））
        if (command == @selector(cancelOperation:)) {
            if ([[oSearchField1 stringValue] length] > 0) {
                if (mFilteredReferencesNode) {
                    [mFilteredReferencesNode setFilteringStr:nil];
                    mFilteredReferencesNode = nil;
                    [self updateColumn:0];
                }
                [oSearchField1 setStringValue:@""];
                [self deactivateSearchField1:self];
            }
            [self activateBrowser];
            return YES;
        }
    }
    // メソッド名検索
    else if (control == oSearchField3) {
        // ESCキー（検索文字列を消してブラウザをアクティブにする（フォーカスを検索フィールドに残したままの方がいいかも？？））
        if (command == @selector(cancelOperation:)) {
            if ([[oSearchField3 stringValue] length] > 0) {
                if (mFilteredCategoryNode) {
                    [mFilteredCategoryNode setFilteringStr:nil];
                    mFilteredCategoryNode = nil;
                    [self updateColumn:2];
                }
                [oSearchField3 setStringValue:@""];
                [self deactivateSearchField3:self];
            }
            [self activateBrowser];
            return YES;
        }
    }
    return NO;
}

/*- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
{
    // Return key in search field will select first browser row
    else if (command == @selector(insertNewline:)) {
        [self selectFirstRowOfFilteringColumn];
        return YES;
    }
    // Up key in search field will select previous row of the current selection in the browser view
    else if (command == @selector(moveUp:)) {
        NSInteger selectedColumn = [oBrowser selectedColumn];
        if  (selectedColumn < 0) {
            selectedColumn = 0;
        } else if (selectedColumn == 1) {
            selectedColumn = 2;
        }
        if ([self nodeCountForColumn:selectedColumn] == 0) {
            return YES;
        }
        NSInteger selectedRow = [oBrowser selectedRowInColumn:selectedColumn];
        NSInteger nextRow = [self nodeCountForColumn:selectedColumn] - 1;
        if (selectedRow > 0) {
            nextRow = selectedRow - 1;
        }
        [oBrowser selectRow:nextRow inColumn:selectedColumn];
        [oMainWindow makeFirstResponder:oBrowser];
        
        CBNode *targetNode = [self selectedNode];
        
        if (!targetNode.isLoaded) {
            //[[CBAppController sharedAppController] fetchDataForNode:targetNode column:selectedColumn];
            [targetNode startLoad];
        }
        
        [self updateWebView];
        return YES;
    }
    // Down key in search field will select next row of the current selection in the browser view
    else if (command == @selector(moveDown:)) {
        NSInteger selectedColumn = [oBrowser selectedColumn];
        if  (selectedColumn < 0) {
            selectedColumn = 0;
        } else if (selectedColumn == 1) {
            selectedColumn = 2;
        }
        if ([self nodeCountForColumn:selectedColumn] == 0) {
            return YES;
        }
        NSInteger selectedRow = [oBrowser selectedRowInColumn:selectedColumn];
        NSInteger nextRow = 0;
        if (selectedRow >= 0) {
            nextRow = selectedRow + 1;
            if (nextRow >= [self nodeCountForColumn:selectedColumn]) {
                nextRow = 0;
            }
        }
        [oBrowser selectRow:nextRow inColumn:selectedColumn];
        [oMainWindow makeFirstResponder:oBrowser];
        
        CBNode *targetNode = [self selectedNode];
        
        if (!targetNode.isLoaded) {
            //[[CBAppController sharedAppController] fetchDataForNode:targetNode column:selectedColumn];
            [targetNode startLoad];
        }
        
        [self updateWebView];
        return YES;
    }
    //NSLog(@"doCommandBySelector: %@", NSStringFromSelector(command));
    return NO;
}
*/

- (void)windowDidBecomeMain:(NSNotification *)notification
{
    [oBGView setNeedsDisplay:YES];
    [oSearchBarView setNeedsDisplay:YES];
    [oSearchButton1 setEnabled:YES];
    [oSearchButton3 setEnabled:YES];
}

- (void)windowDidResignMain:(NSNotification *)notification
{
    [oBGView setNeedsDisplay:YES];
    [oSearchBarView setNeedsDisplay:YES];
    [oSearchButton1 setEnabled:NO];
    [oSearchButton3 setEnabled:NO];
}

- (void)windowDidResize:(NSNotification *)notification
{
    NSRect browserFrame = [oBrowser frame];
    NSRect parentFrame = [[oSearchButton1 superview] frame];
    
    NSRect searchField1Frame = [oSearchField1 frame];
    
    int oneWidth = (int)(browserFrame.size.width / 3);
    int buttonWidth = (int)(oneWidth * 0.8f);
    int paddingWidth = (int)((oneWidth - buttonWidth) / 2);
    
    [oSearchButton1 setFrame:NSMakeRect(paddingWidth, parentFrame.size.height-20, buttonWidth, 17)];
    [oSearchField1 setFrame:NSMakeRect(paddingWidth, searchField1Frame.origin.y, buttonWidth, searchField1Frame.size.height)];

    [oSearchButton2 setFrame:NSMakeRect(oneWidth*1 + paddingWidth, parentFrame.size.height-20, buttonWidth, 17)];
    [oSearchField2 setFrame:NSMakeRect(oneWidth*1 + paddingWidth, searchField1Frame.origin.y, buttonWidth, searchField1Frame.size.height)];

    [oSearchButton3 setFrame:NSMakeRect(oneWidth*2 + paddingWidth, parentFrame.size.height-20, buttonWidth, 17)];
    [oSearchField3 setFrame:NSMakeRect(oneWidth*2 + paddingWidth, searchField1Frame.origin.y, buttonWidth, searchField1Frame.size.height)];
}

- (NSRect)splitView:(NSSplitView *)splitView effectiveRect:(NSRect)proposedEffectiveRect forDrawnRect:(NSRect)drawnRect ofDividerAtIndex:(NSInteger)dividerIndex
{
    if (mIsFullSearchResultShown) {
        return proposedEffectiveRect;
    }
    return NSZeroRect;
}

@end


