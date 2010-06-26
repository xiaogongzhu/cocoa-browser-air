//
//  CBNode.m
//  Cocoa Browser Air
//
//  Created by numata on 08/05/05.
//  Copyright 2008 Satoshi Numata. All rights reserved.
//

#import "CBNode.h"
#import "NSString+Tokenizer.h"
#import "CBReferenceInfo.h"
#import "CBAppController.h"
#import "CBSAXParser.h"


static BOOL     sIsLoading = NO;
static NSMutableArray  *sLoadingTargets = nil;


typedef enum {
    CBNodeLoadingLockStateLoading,
    CBNodeLoadingLockStateFinished
} CBNodeLoadingLockState;


@implementation CBNode

@synthesize enabled = mIsEnabled;

@synthesize type = mType;
@synthesize isStrong = mIsStrong;
@synthesize isLeaf = mIsLeaf;
@synthesize isLoaded = mIsLoaded;

@synthesize parentNode = mParentNode;
@synthesize title = mTitle;
@synthesize URL = mURL;
@synthesize image = mImage;
@synthesize contentHTMLSource = mContentHTMLSource;

- (void)initialize
{
    if (!sLoadingTargets) {
        sLoadingTargets = [[NSMutableArray alloc] init];
    }
}

- (id)init
{
    self = [super init];
    if (self) {
        mIsEnabled = YES;

        mChildNodes = [[NSMutableArray array] retain];
        mType = CBNodeTypeUnknown;
        mIsStrong = NO;
        mIsLeaf = NO;
        mIsLoaded = NO;
    }
    return self;
}

- (void)dealloc
{
    [mChildNodes release];
    [mFilteredChildNodes release];
    [mFilteringStr release];
    
    // Properties
    [mTitle release];
    [mURL release];
    [mImage release];
    [mContentHTMLSource release];

    // Finish
    [super dealloc];
}

- (void)addChildNode:(CBNode *)aNode
{
    aNode.parentNode = self;
    [mChildNodes addObject:aNode];
}

- (CBNode *)childNodeAtIndex:(int)index
{
    NSArray *targetNodes = (mFilteredChildNodes? mFilteredChildNodes: mChildNodes);
    return [targetNodes objectAtIndex:index];
}

- (CBNode *)enabledChildNodeAtIndex:(int)index
{
    int count = index + 1;
    for (CBNode *aNode in mChildNodes) {
        if (aNode.enabled) {
            count--;
            if (count == 0) {
                return aNode;
            }
        }
    }
    return nil;
}

- (int)childNodeCount
{
    if (!mIsLoaded) {
        return 0;
    }
    NSArray *targetNodes = (mFilteredChildNodes? mFilteredChildNodes: mChildNodes);
    return [targetNodes count];
}

- (int)enabledChildNodeCount
{
    int ret = 0;
    for (CBNode *aNode in mChildNodes) {
        if (aNode.enabled) {
            ret++;
        }
    }
    return ret;
}

- (CBNode *)childNodeWithTitle:(NSString *)title
{
    if (!title) {
        return nil;
    }
    NSArray *targetNodes = (mFilteredChildNodes? mFilteredChildNodes: mChildNodes);
    CBNode *temp = nil;
    for (CBNode *aChild in targetNodes) {
        // "NSAttributedString Additions" cannot be found if the comparing below is peformed with isEqualToString:.
        if ([aChild.title isEqualToString:title]) {
            return aChild;
        } else if ([aChild.title hasPrefix:title]) {
            temp = aChild;
        }
    }
    return temp;
}

- (CBNode *)childNodeWithContent:(NSString *)str
{
    NSArray *targetNodes = (mFilteredChildNodes? mFilteredChildNodes: mChildNodes);
    for (CBNode *aChild in targetNodes) {
        NSString *source = aChild.contentHTMLSource;
        if (source) {
            NSRange range = [source rangeOfString:str options:NSCaseInsensitiveSearch];
            if (range.location != NSNotFound) {
                return aChild;
            }
        }
    }
    return nil;
}

- (int)indexOfChildNodeWithTitle:(NSString *)title
{
    if (!title) {
        return -1;
    }    
    return [self indexOfChildNodeWithTitle:title allowsAmbiguous:YES];
}

- (int)indexOfChildNodeWithTitle:(NSString *)title allowsAmbiguous:(BOOL)allowsAmbiguous
{
    if (!title) {
        return -1;
    }
    NSArray *targetNodes = (mFilteredChildNodes? mFilteredChildNodes: mChildNodes);
    int temp = -1;
    int ret = 0;
    for (CBNode *aChild in targetNodes) {
        // "NSAttributedString Additions" cannot be found if the comparing below is peformed with isEqualToString:.
        if ([aChild.title isEqualToString:title]) {
            return ret;
        } else if (allowsAmbiguous && [aChild.title hasPrefix:title]) {
            temp = ret;
        }
        ret++;
    }
    return temp;
}

- (int)indexOfChildNode:(CBNode *)aChildNode
{
    NSArray *targetNodes = (mFilteredChildNodes? mFilteredChildNodes: mChildNodes);
    int ret = 0;
    for (CBNode *aChild in targetNodes) {
        if (aChild == aChildNode) {
            return ret;
        }
        ret++;
    }
    return -1;
}

CBNode *_CBNodeWithTitle(NSString *title, NSArray *source)
{
    for (CBNode *aNode in source) {
        if ([aNode.title isEqualToString:title]) {
            return aNode;
        }
    }
    return nil;
}

BOOL _CBMoveNamedNodesIntoNode(CBNode *destNode, NSMutableArray *source, NSArray *names)
{
    BOOL changed = NO;
    for (NSString *aName in names) {
        CBNode *aNode = _CBNodeWithTitle(aName, source);
        if (aNode) {
            [destNode addChildNode:aNode];
            [source removeObject:aNode];
            changed = YES;
        }
    }
    return changed;
}

BOOL _CBMoveNamedNodesIntoArray(NSMutableArray *dest, NSMutableArray *source, NSArray *names)
{
    BOOL changed = NO;
    for (NSString *aName in names) {
        CBNode *aNode = _CBNodeWithTitle(aName, source);
        if (aNode) {
            [dest addObject:aNode];
            [source removeObject:aNode];
            changed = YES;
        }
    }
    return changed;
}

- (NSArray *)childNodes
{
    return [NSArray arrayWithArray:mChildNodes];
}

- (void)sortChildNodes
{
    [mChildNodes sortUsingDescriptors:[NSArray arrayWithObject:
                                     [[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES] autorelease]]];
}

- (NSString *)filteringStr
{
    return mFilteringStr;
}

- (void)setFilteringStr:(NSString *)str
{
    [mFilteredChildNodes release];
    mFilteredChildNodes = nil;
    [mFilteringStr release];
    mFilteringStr = nil;

    if (str) {
        str = [str stringByReplacingOccurrencesOfString:@"\"" withString:@" "];
        str = [str stringByReplacingOccurrencesOfString:@"\'" withString:@" "];
        str = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }

    if (str && [str length] > 0) {
        NSEnumerator *words = [str tokenize:@" "];
        NSArray *theNodes = mChildNodes;
        for (NSString *aWord in words) {
            mFilteringStr = [str retain];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title like[c] %@",
                                      [NSString stringWithFormat:@"*%@*", aWord]];
            theNodes = [theNodes filteredArrayUsingPredicate:predicate];
        }
        if (theNodes != mChildNodes) {
            mFilteredChildNodes = [theNodes retain];
        }
    }
}

- (CBReferenceInfo *)makeReferenceInfo
{
    CBReferenceInfo *ret = [[CBReferenceInfo new] autorelease];
    // Platform
    if (mType == CBNodeTypePlatform) {
        ret.type = CBReferenceTypePlatform;
        ret.platformName = mTitle;
    }
    // Framework Folder
    else if (mType == CBNodeTypeFrameworkFolder) {
        // Just ignore
        ret = nil;
    }
    // Framework Name
    else if (mType == CBNodeTypeFramework) {
        ret.type = CBReferenceTypeFramework;
        ret.platformName = self.parentNode.parentNode.title;
        ret.frameworkName = mTitle;
    }
    // Class List Level
    else if (mType == CBNodeTypeReferences) {
        // Just ignore
        ret = nil;
    }
    // Class Level
    else if (mType == CBNodeTypeClassLevel) {
        NSString *parentTitle = self.parentNode.title;
        if ([parentTitle isEqualToString:@"Class References"]) {
            ret.type = CBReferenceTypeClass;
        } else if ([parentTitle isEqualToString:@"Protocol References"]) {
            ret.type = CBReferenceTypeProtocol;
        } else if ([parentTitle isEqualToString:@"Other References"]) {
            ret = nil;
        }
        if (ret) {
            ret.platformName = self.parentNode.parentNode.parentNode.parentNode.title;
            ret.frameworkName = self.parentNode.parentNode.title;
            ret.className = mTitle;
        }
    }
    // Category Level
    else if (mType == CBNodeTypeCategory) {
        // Just ignore
        ret = nil;
    }
    // Method Level
    else if (mType == CBNodeTypeMethodLevel) {
        NSString *parentTitle = self.parentNode.title;
        if ([parentTitle isEqualToString:@"Class Methods"]) {
            ret.type = CBReferenceTypeClassMethod;
        } else if ([parentTitle isEqualToString:@"Instance Methods"]) {
            ret.type = CBReferenceTypeInstanceMethod;
        } else if ([parentTitle isEqualToString:@"Delegate Methods"]) {
            ret.type = CBReferenceTypeDelegateMethod;
        } else if ([parentTitle isEqualToString:@"Properties"]) {
            ret.type = CBReferenceTypeProperty;
        } else if ([parentTitle isEqualToString:@"Constants"]) {
            ret.type = CBReferenceTypeConstantInClass;
        } else {
            ret = nil;
        }
        if (ret) {
            ret.platformName = self.parentNode.parentNode.parentNode.parentNode.parentNode.parentNode.title;
            ret.frameworkName = self.parentNode.parentNode.parentNode.parentNode.title;
            ret.className = self.parentNode.parentNode.title;
            ret.methodName = mTitle;
        }
    }
    return ret;
}

- (BOOL)isInFrameworkView
{
    return (mType <= CBNodeTypeDocument);
}

- (CBNode *)lastParentNodeInFrameworkView
{
    CBNode *theNode = self;
    while (theNode.type > CBNodeTypeDocument) {
        theNode = theNode.parentNode;
    }
    return theNode;
}

- (NSString *)localizedTitle
{
    if (mType == CBNodeTypeFramework) {
        NSString *ret = self.title;
        NSRange objcRange = [ret rangeOfString:@" Objective-C"];
        if (objcRange.location != NSNotFound) {
            ret = [ret substringWithRange:NSMakeRange(0, objcRange.location)];
        } else if ([ret isEqualToString:@"Quartz"]) {
            return @"Image Kit/PDF/QC";
        } else if ([ret isEqualToString:@"Quartz Core"]) {
            return @"Core Animation";
        }
        return ret;
    }
    return NSLocalizedString(mTitle, nil);
}

- (NSString *)typeNameForType:(CBNodeType)type
{
    switch (type) {
        case CBNodeTypeRoot:                return @"Root";
        case CBNodeTypePlatform:            return @"Platform";
        case CBNodeTypeFrameworkFolder:     return @"Framework Folder";
        case CBNodeTypeFramework:           return @"Framework";
        case CBNodeTypeReferences:          return @"References";
        case CBNodeTypeDocument:            return @"Document";
    }
    return @"**Unknown**";
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"CBNode{title=\"%@\",localized=\"%@\",type=%@(%d), URL=\"%@\"}",
            [self title], [self localizedTitle], [self typeNameForType:self.type], self.type, self.URL];
}

- (void)startLoad
{
    if (sIsLoading) {
        [sLoadingTargets addObject:self];
        return;
    }
    
    sIsLoading = YES;
    
    CBSAXParser *saxParser = [CBSAXParser createParserForNode:self];
    //NSLog(@"SAX Parser: %@", saxParser);
    
    if (!saxParser) {
        NSLog(@"**** Failed to create a parser for the parent Node: %@", self);

        sIsLoading = NO;

        return;
    }
    
    saxParser.delegate = self;
    [saxParser parse];
}

- (void)saxParserStarted:(CBSAXParser *)parser
{
    // Do nothing
}

- (void)saxParserFinished:(CBSAXParser *)parser
{
    [parser release];
    
    sIsLoading = NO;
    
    if (mType == CBNodeTypePlatform || mType == CBNodeTypeFramework) {
        [[CBAppController sharedAppController] updateFrameworkList];
    } else if (mType == CBNodeTypeReferences) {
        [[CBAppController sharedAppController] updateColumn:0];
    } else if (mType == CBNodeTypeClassLevel) {
        [[CBAppController sharedAppController] updateColumn:1];
    }
    [[CBAppController sharedAppController] updateWebView];
}

- (void)saxParserFacedWarning:(NSString *)warning
{
    NSLog(@"SAX Warning: %@", warning);
}

- (void)saxParserFacedError:(NSString *)error
{
    error = [error stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    // 無視するエラー
    if ([error isEqualToString:@"htmlParseEntityRef: expecting ';'"]) {
        // 無視する
    } else if ([error hasPrefix:@"Unexpected end tag"]) {
        // 無視する
    } else if ([error isEqualToString:@"Tag nobr invalid"]) {
        // 無視する
    } else if ([error isEqualToString:@"Tag content invalid"]) {
        // 無視する
    } else {
        NSLog(@"SAX Error: [%@]", error);
    }
}

- (void)saxParserFacedFatalError:(NSString *)error
{
    NSLog(@"SAX Fatal Error: %@", error);
}

@end


