//
//  CBSAXMacFrameworkParserForWSCFramework.m
//  Cocoa Browser Air
//
//  Created by numata on 09/03/28.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "CBSAXMacFrameworkParserForWSCFramework.h"
#import "CBNode.h"


@implementation CBSAXMacFrameworkParserForWSCFramework

- (id)initWithParentNode:(CBNode *)parentNode
{
    self = [super initWithParentNode:parentNode];
    if (self) {
        mIsBeforeBody = YES;
    }
    return self;
}

- (void)htmlParserStart:(MIHTMLParser *)parser
{
    if (!mReferencesNode) {
        mStatus = CBSAXMacFrameworkParserForWSCParsingStatusNone;

        mReferencesNode = [[CBNode new] autorelease];
        mReferencesNode.title = @"Other References";
        mReferencesNode.isLoaded = YES;
        mReferencesNode.type = CBNodeTypeReferences;
        
        [mParentNode addChildNode:mReferencesNode];
    }
}

- (void)htmlParser:(MIHTMLParser *)parser startTag:(NSString *)tagName attributes:(NSDictionary *)attrs
{
    // クラスのリファレンスは1回 Refresh で index.html から Reference.html に飛ばされる（Message フレームワークを除く）。
    if (mIsBeforeBody) {
        if ([tagName isEqualToString:@"meta"] && [[attrs objectForKey:@"http-equiv"] isEqualToString:@"refresh"]) {
            NSString *content = [attrs objectForKey:@"content"];
            NSRange urlRange = [content rangeOfString:@"URL="];
            if (urlRange.location != NSNotFound) {
                NSString *urlStr = [content substringFromIndex:urlRange.location + 4];
                NSURL *theURL = [NSURL URLWithString:urlStr relativeToURL:mParentNode.URL];
                mInnerURL = theURL;
                
                mDoJump = YES;
                
                mInnerParser = [[MIHTMLParser alloc] init];
                mInnerParser.delegate = self;
                NSData *innerData = [[NSData alloc] initWithContentsOfURL:theURL];
                [mInnerParser parseHTMLData:innerData];
                [innerData release];
                [mInnerParser release];
                mInnerParser = nil;
            }
        }
        if (mIsBeforeBody && [tagName isEqualToString:@"body"]) {
            mIsBeforeBody = NO;
        }
        return;
    }
    
    if ([tagName isEqualToString:@"iframe"]) {
        mInnerURL2 = [NSURL URLWithString:[attrs objectForKey:@"src"] relativeToURL:mInnerURL];
        
        mInnerParser2 = [[MIHTMLParser alloc] init];
        mInnerParser2.delegate = self;
        NSData *innerData2 = [[NSData alloc] initWithContentsOfURL:mInnerURL2];
        [mInnerParser2 parseHTMLData:innerData2];
        [innerData2 release];
        [mInnerParser2 release];
        mInnerParser2 = nil;
    }
    
    if (parser != mInnerParser2) {
        return;
    }
    
    if (mStatus == CBSAXMacFrameworkParserForWSCParsingStatusNone) {
        if ([tagName isEqualToString:@"a"]) {
            NSString *urlStr = [attrs objectForKey:@"href"];
            if (urlStr) {
                mLinkURL = [NSURL URLWithString:[attrs objectForKey:@"href"] relativeToURL:mInnerURL2];
                mLinkName = [[NSMutableString alloc] init];
                mStatus = CBSAXMacFrameworkParserForWSCParsingStatusLink;
            }
        }
    }
}

- (void)htmlParser:(MIHTMLParser *)parser foundText:(NSString *)text
{
    if (parser != mInnerParser2) {
        return;
    }
    
    if (mStatus == CBSAXMacFrameworkParserForWSCParsingStatusLink) {
        [mLinkName appendString:text];
    }
}

- (void)htmlParser:(MIHTMLParser *)parser endTag:(NSString *)tagName
{
    if (parser != mInnerParser2) {
        return;
    }
    
    if (mStatus == CBSAXMacFrameworkParserForWSCParsingStatusLink) {
        if ([tagName isEqualToString:@"a"]) {
            CBNode *aClassLevelNode = [[CBNode new] autorelease];
            aClassLevelNode.title = mLinkName;
            aClassLevelNode.type = CBNodeTypeClassLevel;
            aClassLevelNode.URL = mLinkURL;
            if ([mLinkName isEqualToString:@"Revision History"] || [mLinkName isEqualToString:@"Result Codes"]) {
                aClassLevelNode.isLeaf = YES;
            }
            [mReferencesNode addChildNode:aClassLevelNode];

            [mLinkName release];
            mLinkName = nil;

            mStatus = CBSAXMacFrameworkParserForWSCParsingStatusNone;
        }
    }
}

- (void)htmlParserEnd:(MIHTMLParser *)parser
{
    if (parser != mInnerParser2) {
        return;
    }
    
    if (mLinkName) {
        [mLinkName release];
        mLinkName = nil;
    }
    
    mParentNode.isLoaded = YES;
}

@end

