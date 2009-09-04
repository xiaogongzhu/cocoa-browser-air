//
//  CBSAXParser.m
//  Cocoa Browser Air
//
//  Created by numata on 09/03/08.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "CBSAXParser.h"
#import "CBNode.h"

#import "CBSAXMac_10_5_PlatformParser.h"
#import "CBSAXMac_10_5_FrameworkParser.h"
#import "CBSAXMac_10_5_ClassParser.h"
#import "CBSAXMac_10_6_PlatformParser.h"
#import "CBSAXMacRevisionParser.h"

#import "CBSAXMacFrameworkParserForMessageFramework.h"
#import "CBSAXMacFrameworkParserForObjC_2_0.h"
#import "CBSAXMacFrameworkParserForWSCFramework.h"

#import "CBSAXIPhonePlatformParser.h"


@implementation CBSAXParser

@synthesize delegate = mDelegate;

+ (Class)parserClassForPlatformNode:(CBNode *)aNode
{
    Class parserClass = NULL;

    if ([aNode.title isEqualToString:@"Mac OS X 10.5"]) {
        parserClass = [CBSAXMac_10_5_PlatformParser class];
    } else if ([aNode.title isEqualToString:@"Mac OS X 10.6"]) {
        parserClass = [CBSAXMac_10_6_PlatformParser class];
    } else if ([aNode.title hasPrefix:@"iPhone"]) {
        parserClass = [CBSAXIPhonePlatformParser class];
    }
    
    return parserClass;
}

+ (Class)parserClassForFrameworkNode:(CBNode *)aNode
{
    if ([aNode.title isEqualToString:@"Objective-C 2.0"]) {
        return [CBSAXMacFrameworkParserForObjC_2_0 class];
    }
    
    Class parserClass = NULL;

    NSString *platformName = aNode.parentNode.parentNode.title;
    if ([platformName isEqualToString:@"Mac OS X 10.5"]) {
        if ([aNode.title isEqualToString:@"Message"]) {
            parserClass = [CBSAXMacFrameworkParserForMessageFramework class];
        } else if ([aNode.title isEqualToString:@"Web Services Core"]) {
            parserClass = [CBSAXMacFrameworkParserForWSCFramework class];
        } else {
            parserClass = [CBSAXMac_10_5_FrameworkParser class];
        }
    } else if ([platformName hasPrefix:@"iPhone"]) {
        parserClass = [CBSAXMac_10_5_FrameworkParser class];
    }    

    return parserClass;
}

+ (Class)parserClassForClassLevelNode:(CBNode *)aNode
{
    Class parserClass = NULL;
    
#ifdef __DEBUG__
    NSLog(@"parserClassForClassLevelNode: %@", aNode);
#endif
    if ([aNode.title isEqualToString:@"RevisionHistory"] || [aNode.title isEqualToString:@"Revision History"] || [aNode.title isEqualToString:@"Result Codes"]) {
        parserClass = [CBSAXMacRevisionParser class];
    } else {
        parserClass = [CBSAXMac_10_5_ClassParser class];
    }
    
    return parserClass;
}

+ (Class)parserClassForDocumentNode:(CBNode *)aNode
{
    Class parserClass = NULL;
    
    //parserClass = [CBDocCategoryListParser class];

    return parserClass;    
}

+ (Class)parserClassForCategoryNode:(CBNode *)aNode
{
    Class parserClass = NULL;
    
    //parserClass = [CBDocTitleListParser class];
    
    return parserClass;    
}

+ (Class)parserClassForTitleNode:(CBNode *)aNode
{
    Class parserClass = NULL;
    
    NSString *docTypeName = aNode.parentNode.parentNode.title;
    if ([docTypeName isEqualToString:@"Cocoa Articles"]) {
        //parserClass = [CBDocArticlesChapteredPageParser class];
    } else {
        //parserClass = [CBDocChapteredPageParser class];
    }
    
    return parserClass;    
}

+ (Class)parserClassForChapterNode:(CBNode *)aNode
{
    Class parserClass = NULL;
    
    //parserClass = [CBDocGuideLeafParser class];
    
    return parserClass;    
}

+ (CBSAXParser *)createParserForNode:(CBNode *)aNode
{
#ifdef __DEBUG__
    NSLog(@"createParserForNode: %@", aNode);
#endif
    Class parserClass = NULL;
    
    switch (aNode.type) {
        case CBNodeTypePlatform:
            parserClass = [self parserClassForPlatformNode:aNode];
            break;
        case CBNodeTypeFramework:
            parserClass = [self parserClassForFrameworkNode:aNode];
            break;
        case CBNodeTypeClassLevel:
        case CBNodeTypeReferences:
            parserClass = [self parserClassForClassLevelNode:aNode];
            break;
        case CBNodeTypeDocument:
            parserClass = [self parserClassForDocumentNode:aNode];
            break;
        case CBNodeTypeDocumentCategory:
            parserClass = [self parserClassForCategoryNode:aNode];
            break;
        case CBNodeTypeDocumentTitle:
            parserClass = [self parserClassForTitleNode:aNode];
            break;
        case CBNodeTypeDocumentChapter:
            parserClass = [self parserClassForChapterNode:aNode];
            break;
        default:
            break;
    }
    
    if (parserClass == NULL) {
        return nil;
    }
    
    return [[parserClass alloc] initWithParentNode:aNode];
}

- (id)initWithParentNode:(CBNode *)parentNode
{
    self = [super init];
    if (self) {
        mParentNode = parentNode;
    }
    return self;
}

- (BOOL)parse
{
    return NO;
}

@end

