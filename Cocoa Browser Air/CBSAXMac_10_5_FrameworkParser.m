//
//  CBSAXMacFrameworkTopParser.m
//  Cocoa Browser Air
//
//  Created by numata on 09/03/08.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "CBSAXMac_10_5_FrameworkParser.h"
#import "CBNode.h"
#import "NSURL+RelativeAddress.h"


@implementation CBSAXMac_10_5_FrameworkParser

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
#ifdef __DEBUG__
    NSLog(@"CBSAXMacFrameworkParser>> htmlParserStart: parent_node=%@", mParentNode);
#endif
    
    mStatus = CBSAXMacFrameworkParsingStatusNone;
}

- (void)htmlParser:(MIHTMLParser *)parser startTag:(NSString *)tagName attributes:(NSDictionary *)attrs
{
    // Class reference will be redirected to Reference.html from index.html by "Refresh" (except for Message Framework)
    if (mIsBeforeBody) {
        if ([tagName isEqualToString:@"meta"] && [[attrs objectForKey:@"http-equiv"] isEqualToString:@"refresh"]) {
            NSString *content = [attrs objectForKey:@"content"];
            NSRange urlRange = [content rangeOfString:@"URL="];
            if (urlRange.location != NSNotFound) {
                NSString *urlStr = [content substringFromIndex:urlRange.location + 4];
                NSURL *theURL = [NSURL numataURLWithString:urlStr relativeToURL:mParentNode.URL];
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
                mTargetURL = [[NSURL numataURLWithString:hrefStr relativeToURL:mParentNode.URL] standardizedURL];
#ifdef __DEBUG__
                NSLog(@"URL: href=%@, parent_url=%@, url=%@", hrefStr, mParentNode.URL, mTargetURL);
#endif
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
#ifdef __DEBUG__
                NSLog(@"New Class Node: name=%@, url=%@", mClassLevelName, mTargetURL);
#endif
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

