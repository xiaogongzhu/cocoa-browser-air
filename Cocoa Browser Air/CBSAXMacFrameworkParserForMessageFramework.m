//
//  CBSAXMacFrameworkTopParserForMessageFramework.m
//  Cocoa Browser Air
//
//  Created by numata on 09/03/08.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "CBSAXMacFrameworkParserForMessageFramework.h"
#import "CBNode.h"


@implementation CBSAXMacFrameworkParserForMessageFramework

- (void)htmlParserStart:(MIHTMLParser *)parser
{
    mStatus = CBSAXMacFrameworkTopParserForMessageFrameworkStatusNone;
}

- (void)htmlParser:(MIHTMLParser *)parser startTag:(NSString *)tagName attributes:(NSDictionary *)attrs
{
    if (mStatus == CBSAXMacFrameworkTopParserForMessageFrameworkStatusNone) {
        if ([tagName isEqualToString:@"h3"]) {
            mStatus = CBSAXMacFrameworkTopParserForMessageFrameworkStatusH3;
        } else if ([tagName isEqualToString:@"blockquote"]) {
            mStatus = CBSAXMacFrameworkTopParserForMessageFrameworkStatusBlockquote;
        }
    }
    else if (mStatus == CBSAXMacFrameworkTopParserForMessageFrameworkStatusBlockquote) {
        if ([tagName isEqualToString:@"a"]) {
            NSString *hrefStr = [attrs objectForKey:@"href"];
            if ([hrefStr hasSuffix:@"/index.html"]) {
                hrefStr = [[hrefStr stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"CompositePage.html"];
            }
            mClassLevelURL = [[NSURL alloc] initWithString:hrefStr relativeToURL:mParentNode.URL];
            mStatus = CBSAXMacFrameworkTopParserForMessageFrameworkStatusA;
        }
    }
}

- (void)htmlParser:(MIHTMLParser *)parser foundText:(NSString *)text
{
    if (mStatus == CBSAXMacFrameworkTopParserForMessageFrameworkStatusH3) {
        mReferencesNode = [[CBNode new] autorelease];
        mReferencesNode.title = text;
        mReferencesNode.isLoaded = YES;
        mReferencesNode.type = CBNodeTypeReferences;
        if ([text isEqualToString:@"Classes"]) {
            [mParentNode addChildNode:mReferencesNode];
        }
    }
    else if (mStatus == CBSAXMacFrameworkTopParserForMessageFrameworkStatusA) {
        mClassLevelName = [text copy];
    }
}

- (void)htmlParser:(MIHTMLParser *)parser endTag:(NSString *)tagName
{
    if (mStatus == CBSAXMacFrameworkTopParserForMessageFrameworkStatusH3) {
        if ([tagName isEqualToString:@"h3"]) {
            mStatus = CBSAXMacFrameworkTopParserForMessageFrameworkStatusNone;
        }
    }
    else if (mStatus == CBSAXMacFrameworkTopParserForMessageFrameworkStatusBlockquote) {
        if ([tagName isEqualToString:@"blockquote"]) {
            mStatus = CBSAXMacFrameworkTopParserForMessageFrameworkStatusNone;
        }
    }
    else if (mStatus == CBSAXMacFrameworkTopParserForMessageFrameworkStatusA) {
        if ([tagName isEqualToString:@"a"]) {
            CBNode *aClassLevelNode = [[CBNode new] autorelease];
            aClassLevelNode.title = mClassLevelName;
            aClassLevelNode.URL = mClassLevelURL;
            aClassLevelNode.type = CBNodeTypeClassLevel;
            [mReferencesNode addChildNode:aClassLevelNode];
            
            [mClassLevelName release];
            mClassLevelName = nil;
            [mClassLevelURL release];
            mClassLevelURL = nil;
            mStatus = CBSAXMacFrameworkTopParserForMessageFrameworkStatusBlockquote;
        }
    }
}

- (void)htmlParserEnd:(MIHTMLParser *)parser
{
    if (mClassLevelURL) {
        [mClassLevelURL release];
        mClassLevelURL = nil;
    }
    if (mClassLevelName) {
        [mClassLevelName release];
        mClassLevelName = nil;
    }
    mParentNode.isLoaded = YES;
}

@end

