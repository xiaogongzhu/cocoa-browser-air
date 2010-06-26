//
//  CBDocument.h
//  Cocoa Browser Air
//
//  Created by numata on 08/05/05.
//  Copyright Satoshi Numata 2008 . All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "WebView+SimpleAPI.h"
#import "CBNode.h"
#import "CBStatusBarBackgroundView.h"


@interface CBDocument : NSDocument<NSToolbarDelegate>
{
    IBOutlet NSWindow               *oMainWindow;
    IBOutlet NSBrowser              *oBrowser;
    IBOutlet WebView                *oWebView;
    IBOutlet NSTextField            *oStatusField;
    IBOutlet NSOutlineView          *oFrameworkListView;
    IBOutlet NSOutlineView          *oFullSearchResultView;
    
    IBOutlet NSPanel                *oFindPanel;
    IBOutlet NSTextField            *oFindField;
    IBOutlet NSButton               *oFindCaseIgnoreButton;

    IBOutlet NSWindow               *oSourceWindow;
    IBOutlet NSTextView             *oSourceView;

    IBOutlet NSProgressIndicator    *oLoadingIndicator;
    IBOutlet NSSegmentedControl     *oGoBackSegmentedControl;
    IBOutlet NSSearchField          *oFullSearchField;

    IBOutlet CBStatusBarBackgroundView          *oBGView;

    IBOutlet NSSplitView        *oBrowserSplitView;
    
    IBOutlet NSButton           *oSearchButton1;
    IBOutlet NSButton           *oSearchButton2;
    IBOutlet NSButton           *oSearchButton3;
    
    IBOutlet NSSearchField      *oSearchField1;
    IBOutlet NSSearchField      *oSearchField2;
    IBOutlet NSSearchField      *oSearchField3;
    
    IBOutlet NSView             *oSearchBarView;
    IBOutlet NSBox              *oBrowserBox;
    IBOutlet NSView             *oFullSearchResultViewBox;

    BOOL        mIsFullSearchResultShown;
    
    CBNode  *mFilteredReferencesNode;
    CBNode  *mFilteredCategoryNode;
    CBNode  *mFilteringNode;
    
    CBNode *mLastSelectedNodeInFrameworkList;
    
    NSMutableArray  *mShowInfoStack;

    int     mLastSelectedColumn;
    int     mLastSelectedRow;
    
    CBNode  *mCurrentPlatformNode;
    CBNode  *mCurrentFrameworkFolderNode;
    CBNode  *mCurrentFrameworkNode;
    CBNode  *mCurrentReferencesNode;
    CBNode  *mCurrentClassLevelNode;
    CBNode  *mCurrentCategoryNode;
    
    CBNode  *mLastBrowsedNode;
    
    NSMutableArray  *mHistoryPastNodes;
    NSMutableArray  *mHistoryFutureNodes;
    
    BOOL    mIsManuallyShowingNode;
    
    BOOL    mIsResolvingStacks;
    
    NSTimeInterval  mLastSearchFieldActivatedTime1;
    NSTimeInterval  mLastSearchFieldActivatedTime2;
    NSTimeInterval  mLastSearchFieldActivatedTime3;
    
    BOOL    mIsSearchBarShown;
}

//// Actions

- (IBAction)goBack:(id)sender;
- (IBAction)goForward:(id)sender;

- (IBAction)activateSearchField1:(id)sender;
- (IBAction)deactivateSearchField1:(id)sender;
- (IBAction)activateSearchField2:(id)sender;
- (IBAction)deactivateSearchField2:(id)sender;
- (IBAction)activateSearchField3:(id)sender;
- (IBAction)deactivateSearchField3:(id)sender;

- (IBAction)performFullSearch:(id)sender;

- (IBAction)activateFullSearchField:(id)sender;


//// Actions for Interaction with UI Parts

- (IBAction)changedBrowserSelection:(id)sender;
- (IBAction)historyButtonClicked:(NSSegmentedControl *)sender;

- (IBAction)showFindPanel:(id)sender;
- (IBAction)findNext:(id)sender;
- (IBAction)findPrevious:(id)sender;


//// Accessor Methods

- (void)startLoadingIndicator;
- (void)stopLoadingIndicator;

- (void)updateFrameworkList;
- (void)updateBrowser;
- (void)updateColumn:(int)column;
- (void)updateWebView;

- (void)startSearchWithStr:(NSString *)str;
- (void)validateSearch;
- (void)activateFrameworkListView;
- (void)activateBrowser;
- (void)activateWebView;
- (void)selectFirstRowOfFilteringColumn;

- (void)showNode:(CBNode *)targetNode;
- (void)showNodeForDoubleClickOpen:(CBNode *)node;
- (void)resolveStackForNewWindowOpen:(NSArray *)stack;

- (void)reloadFrameworkList;

- (void)validateSearchBarShowing;

- (void)clearCurrentSearchWord;

@end


