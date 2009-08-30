//
//  CBSAXMacFrameworkTopParser.m
//  Cocoa Browser Air
//
//  Created by numata on 09/03/08.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "CBSAXMacFrameworkParser.h"
#import "CBNode.h"


@implementation CBSAXMacFrameworkParser

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
    mStatus = CBSAXMacFrameworkParsingStatusNone;
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
    
    if (mStatus == CBSAXMacFrameworkParsingStatusNone) {
        if ([tagName isEqualToString:@"h3"]) {
            mStatus = CBSAXMacFrameworkParsingStatusCollectionCheck;
        }
    }
    else if (mStatus == CBSAXMacFrameworkParsingStatusReferences) {
        if ([tagName isEqualToString:@"a"]) {
            mStatus = CBSAXMacFrameworkParsingStatusClassLevelNameCheck;
            mClassLevelName = [[NSMutableString alloc] init];
            
            NSString *hrefStr = [attrs objectForKey:@"href"];
            if (hrefStr) {
                mTargetURL = [[NSURL URLWithString:hrefStr relativeToURL:mParentNode.URL] standardizedURL];
            }
        }
    }
}

- (void)htmlParser:(MIHTMLParser *)parser foundText:(NSString *)text
{
    text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (mStatus == CBSAXMacFrameworkParsingStatusCollectionCheck) {
        if ([text length] > 0) {
            mReferencesNode = [[CBNode new] autorelease];
            mReferencesNode.title = text;
            mReferencesNode.isLoaded = YES;
            mReferencesNode.type = CBNodeTypeReferences;
            [mParentNode addChildNode:mReferencesNode];
            
            mStatus = CBSAXMacFrameworkParsingStatusReferences;
            mLastRefStatus = mStatus;
        }
    }
    else if (mStatus == CBSAXMacFrameworkParsingStatusClassLevelNameCheck) {
        if (text) {
            if ([text hasSuffix:@" Reference"]) {
                text = [text substringToIndex:[text length]-10];
            }
            [mClassLevelName appendString:text];
        }
    }
}

- (void)htmlParser:(MIHTMLParser *)parser endTag:(NSString *)tagName
{
    if (mStatus == CBSAXMacFrameworkParsingStatusCollectionCheck) {
        mStatus = CBSAXMacFrameworkParsingStatusNone;
    }
    else if (mStatus == CBSAXMacFrameworkParsingStatusReferences) {
        if ([tagName isEqualToString:@"table"]) {
            mStatus = CBSAXMacFrameworkParsingStatusCollectionCheck;
        }
    }
    else if (mStatus == CBSAXMacFrameworkParsingStatusClassLevelNameCheck) {
        if ([tagName isEqualToString:@"a"]) {
            if (![mClassLevelName isEqualToString:@"PDF"] && ![mClassLevelName hasPrefix:@"Index"]) {
                CBNode *aClassLevelNode = [[CBNode new] autorelease];
                aClassLevelNode.title = mClassLevelName;
                aClassLevelNode.URL = mTargetURL;
                aClassLevelNode.type = CBNodeTypeClassLevel;
                if ([mClassLevelName isEqualToString:@"Revision History"] || [mClassLevelName isEqualToString:@"RevisionHistory"]) {
                    aClassLevelNode.isLeaf = YES;
                }
                [mReferencesNode addChildNode:aClassLevelNode];
            }

            [mClassLevelName release];
            mClassLevelName = nil;
            mStatus = mLastRefStatus;
        }
    }
}

- (void)htmlParserEnd:(MIHTMLParser *)parser
{
    mParentNode.isLoaded = YES;    
}

@end

