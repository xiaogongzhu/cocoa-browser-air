//
//  CBNode.h
//  Cocoa Browser Air
//
//  Created by numata on 08/05/05.
//  Copyright 2008 Satoshi Numata. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CBSAXParser.h"


@class CBReferenceInfo;


/*!
    @enum   CBNodeType
    @discussion
        Node type has priority. Root node type should always be smaller than platform, and so on.
 */
typedef enum {
    CBNodeTypeRoot = 0,
    CBNodeTypePlatform,
    CBNodeTypeFrameworkFolder,  // 「主要フレームワーク」などの、フレームワークをまとめておくためのノード
    CBNodeTypeFramework,

    CBNodeTypeReferences,
    CBNodeTypeDocument,
    
    CBNodeTypeClassLevel,
    CBNodeTypeCategory,
    CBNodeTypeMethodLevel,

    CBNodeTypeDocumentCategory,
    CBNodeTypeDocumentTitle,
    CBNodeTypeDocumentChapter,

    CBNodeTypeUnknown,
} CBNodeType;


@interface CBNode : NSObject<CBSAXParserDelegate> {
    BOOL            mIsEnabled;

    CBNodeType      mType;
    BOOL            mIsStrong;
    BOOL            mIsLeaf;
    BOOL            mIsLoaded;
    BOOL            mIsMainFramework;

    CBNode          *mParentNode;
    NSString        *mTitle;
    NSURL           *mURL;
    NSImage         *mImage;
    NSString        *mContentHTMLSource;

    NSMutableArray  *mChildNodes;
    NSArray         *mFilteredChildNodes;
    NSString        *mFilteringStr;
}

@property(assign, readwrite) BOOL       enabled;

@property(assign, readwrite) CBNodeType type;
@property(assign, readwrite) BOOL       isStrong;
@property(assign, readwrite) BOOL       isLeaf;
@property(assign, readwrite) BOOL       isLoaded;

@property(assign, readwrite) CBNode*    parentNode;
@property(retain, readwrite) NSImage*   image;
@property(copy, readwrite) NSString*    title;
@property(copy, readwrite) NSURL*       URL;
@property(copy, readwrite) NSString*    contentHTMLSource;

- (CBReferenceInfo *)makeReferenceInfo;

- (void)startLoad;

- (void)addChildNode:(CBNode *)aNode;
- (CBNode *)childNodeAtIndex:(int)index;
- (CBNode *)enabledChildNodeAtIndex:(int)index;
- (int)childNodeCount;
- (int)enabledChildNodeCount;

- (CBNode *)childNodeWithTitle:(NSString *)title;
- (CBNode *)childNodeWithContent:(NSString *)str;
- (int)indexOfChildNodeWithTitle:(NSString *)title;
- (int)indexOfChildNodeWithTitle:(NSString *)title allowsAmbiguous:(BOOL)allowsAmbiguous;
- (int)indexOfChildNode:(CBNode *)aChildNode;

- (NSArray *)childNodes;

- (void)sortChildNodes;

- (NSString *)filteringStr;
- (void)setFilteringStr:(NSString *)str;

- (NSString *)localizedTitle;

- (BOOL)isInFrameworkView;
- (CBNode *)lastParentNodeInFrameworkView;

@end


