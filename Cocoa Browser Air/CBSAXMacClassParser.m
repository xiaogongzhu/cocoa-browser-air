//
//  CBSAXMacClassTopParser.m
//  Cocoa Browser Air
//
//  Created by numata on 09/03/08.
//  Copyright 2009 Satoshi Numata. All rights reserved.
//

#import "CBSAXMacClassParser.h"
#import "CBNode.h"


@implementation CBSAXMacClassParser

- (id)initWithParentNode:(CBNode *)parentNode
{
    self = [super initWithParentNode:parentNode];
    if (self) {
        mDoJump = NO;
        mIsBeforeBody = YES;
        mANameTags = [[NSMutableString alloc] init];
    }
    return self;
}

- (void)htmlParserStart:(MIHTMLParser *)parser
{
    mStatus = CBSAXMacClassParsingStatusNone;
    mMethodLevelPrefix = nil;
    mIsAName = NO;
}

- (void)htmlParser:(MIHTMLParser *)parser startTag:(NSString *)tagName attributes:(NSDictionary *)attrs
{
    mIsAName = NO;
    if ([tagName isEqualToString:@"a"]) {
        if (![attrs objectForKey:@"href"]) {
            [mANameTags appendString:@"<a"];
            for (NSString *key in attrs) {
                NSString *value = [attrs objectForKey:key];
                [mANameTags appendString:@" "];
                [mANameTags appendString:key];
                [mANameTags appendString:@"=\""];
                if ([tagName isEqualToString:@"a"] && [key isEqualToString:@"href"]) {
                    NSURL *parentURL = (mInnerParser? mInnerURL: mParentNode.URL);
                    NSURL *theURL = [NSURL URLWithString:value relativeToURL:parentURL];
                    [mANameTags appendString:[theURL absoluteString]];
                } else if ([tagName isEqualToString:@"img"] && [key isEqualToString:@"src"]) {
                    NSURL *parentURL = (mInnerParser? mInnerURL: mParentNode.URL);
                    NSURL *theURL = [NSURL URLWithString:value relativeToURL:parentURL];
                    [mANameTags appendString:[theURL absoluteString]];
                } else {
                    [mANameTags appendString:value];
                }
                [mANameTags appendString:@"\""];
            }                
            [mANameTags appendString:@"></a>"];
            mIsAName = YES;
        }
    }
    
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

    // パースのメイン部分
    if (mStatus == CBSAXMacClassParsingStatusNone) {
        if ([tagName isEqualToString:@"h1"]) {
            mTempStr = [[NSMutableString alloc] init];
            
            NSURL *parentURL = (mInnerParser? mInnerURL: mParentNode.URL);
            [mTempStr appendString:@"<!-- source_url=\""];
            [mTempStr appendString:[parentURL absoluteString]];
            [mTempStr appendString:@"\" -->\n"];
            
            [mTempStr appendString:@"<h1>"];
            mStatus = CBSAXMacClassParsingStatusSpecInfo;
        }
    }
    else if (mStatus == CBSAXMacClassParsingStatusSpecInfo) {
        if ([tagName isEqualToString:@"h2"] || [tagName isEqualToString:@"h3"]) {
            if ([tagName isEqualToString:@"h2"]) {
                mParentNode.contentHTMLSource = mTempStr;
                [mTempStr release];
                mTempStr = nil;
                
                mStatus = CBSAXMacClassParsingStatusCategory;
            } else {
                mStatus = CBSAXMacClassParsingStatusMethodLevel;
            }
            
            mTempStr = [[NSMutableString alloc] init];
            if ([mANameTags length] > 0) {
                [mTempStr appendString:mANameTags];
                [mTempStr appendString:@"\n"];
                [mANameTags release];
                mANameTags = [[NSMutableString alloc] init];
            }
            [mTempStr appendString:@"<"];
            [mTempStr appendString:tagName];
            [mTempStr appendString:@">"];
            mTempStr2 = [[NSMutableString alloc] init];
            mIsInHeader = YES;
        } else {
            if (!mIsAName) {
                [mTempStr appendString:@"<"];
                [mTempStr appendString:tagName];
                for (NSString *key in attrs) {
                    NSString *value = [attrs objectForKey:key];
                    [mTempStr appendString:@" "];
                    [mTempStr appendString:key];
                    [mTempStr appendString:@"=\""];
                    if ([tagName isEqualToString:@"a"] && [key isEqualToString:@"href"]) {
                        NSURL *parentURL = (mInnerParser? mInnerURL: mParentNode.URL);
                        NSURL *theURL = [NSURL URLWithString:value relativeToURL:parentURL];
                        [mTempStr appendString:[theURL absoluteString]];
                    } else if ([tagName isEqualToString:@"img"] && [key isEqualToString:@"src"]) {
                        NSURL *parentURL = (mInnerParser? mInnerURL: mParentNode.URL);
                        NSURL *theURL = [NSURL URLWithString:value relativeToURL:parentURL];
                        [mTempStr appendString:[theURL absoluteString]];
                    } else {
                        [mTempStr appendString:value];
                    }
                    [mTempStr appendString:@"\""];
                }
                [mTempStr appendString:@">"];
            }
        }
    }
    else if (mStatus == CBSAXMacClassParsingStatusCategory || mStatus == CBSAXMacClassParsingStatusMethodLevel) {
        if ([tagName isEqualToString:@"h2"] || [tagName isEqualToString:@"h3"] || ([tagName isEqualToString:@"div"] && [[attrs objectForKey:@"class"] isEqualToString:@"mini_nav_text"])) {
            if (mStatus == CBSAXMacClassParsingStatusCategory) {
                CBNode *aCategoryNode = [[CBNode new] autorelease];
                aCategoryNode.title = mTempStr2;
                aCategoryNode.isLoaded = YES;
                aCategoryNode.type = CBNodeTypeCategory;
                if ([tagName isEqualToString:@"div"]) {
                    NSString *source = mTempStr;
                    int loopCount = 100;
                    while (loopCount > 0) {
                        source = [source stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        if ([source hasSuffix:@"<br><br>"]) {
                            source = [source substringToIndex:[source length] - 8];
                        } else if ([source hasSuffix:@"<br/><br/>"]) {
                            source = [source substringToIndex:[source length] - 10];
                        } else {
                            break;
                        }
                        loopCount--;
                    }
                    aCategoryNode.contentHTMLSource = source;
                } else {
                    aCategoryNode.contentHTMLSource = mTempStr;
                }
                if ([mTempStr2 isEqualToString:@"Overview"] || [mTempStr2 isEqualToString:@"Adopted Protocols"] || [mTempStr2 isEqualToString:@"Organization of This Document"] || [mTempStr2 isEqualToString:@"Result Codes"]) {
                    aCategoryNode.isLeaf = YES;
                }
                [mParentNode addChildNode:aCategoryNode];
                
                mLastCategoryNode = aCategoryNode;
                if ([mTempStr2 isEqualToString:@"Class Methods"]) {
                    mMethodLevelPrefix = @"+ ";
                } else if ([mTempStr2 isEqualToString:@"Instance Methods"] || [mTempStr2 isEqualToString:@"Delegate Methods"]) {
                    mMethodLevelPrefix = @"- ";
                } else if ([mTempStr2 isEqualToString:@"Methods"]) {
                    // こうなるのはMessage フレームワークのみで、クラスメソッドしかない。
                    aCategoryNode.title = @"Class Methods";
                    mMethodLevelPrefix = @"+ ";
                } else {
                    mMethodLevelPrefix = nil;
                }
                mIsInConstants = NO;
                if ([mTempStr2 isEqualToString:@"Constants"]) {
                    mIsInConstants = YES;
                }
            } else {
                CBNode *methodLevelNode = [[CBNode new] autorelease];
                if (mMethodLevelPrefix) {
                    methodLevelNode.title = [mMethodLevelPrefix stringByAppendingString:mTempStr2];
                } else {
                    methodLevelNode.title = mTempStr2;
                }
                methodLevelNode.isLeaf = YES;
                methodLevelNode.isLoaded = YES;
                methodLevelNode.type = CBNodeTypeMethodLevel;
                if ([tagName isEqualToString:@"div"]) {
                    NSString *source = mTempStr;
                    int loopCount = 100;
                    while (loopCount > 0) {
                        source = [source stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        if ([source hasSuffix:@"<br><br>"]) {
                            source = [source substringToIndex:[source length] - 8];
                        } else if ([source hasSuffix:@"<br/><br/>"]) {
                            source = [source substringToIndex:[source length] - 10];
                        } else {
                            break;
                        }
                        loopCount--;
                    }
                    methodLevelNode.contentHTMLSource = source;
                } else {
                    methodLevelNode.contentHTMLSource = mTempStr;
                }
                if (mLastCategoryNode) {
                    [mLastCategoryNode addChildNode:methodLevelNode];
                } else {
                    [mParentNode addChildNode:methodLevelNode];
                }
            }
            
            [mTempStr release];
            mTempStr = nil;

            [mTempStr2 release];
            mTempStr2 = nil;
            
            mTempStr = [[NSMutableString alloc] init];
            mTempStr2 = [[NSMutableString alloc] init];
            mIsInHeader = YES;

            NSURL *parentURL = (mInnerParser? mInnerURL: mParentNode.URL);
            [mTempStr appendString:@"<!-- source_url=\""];
            [mTempStr appendString:[parentURL absoluteString]];
            [mTempStr appendString:@"\" -->\n"];

            if ([mANameTags length] > 0) {
                [mTempStr appendString:mANameTags];
                [mTempStr appendString:@"\n"];
                [mANameTags release];
                mANameTags = [[NSMutableString alloc] init];
            }
            
            if ([tagName isEqualToString:@"h2"]) {
                [mTempStr appendString:@"<h2>"];
                mStatus = CBSAXMacClassParsingStatusCategory;
            } else if ([tagName isEqualToString:@"h3"]) {
                [mTempStr appendString:@"<h3>"];
                mStatus = CBSAXMacClassParsingStatusMethodLevel;
            } else {
                mStatus = CBSAXMacClassParsingStatusFinished;
            }
        } else {
            if (!mIsAName) {
                if (![tagName isEqualToString:@"a"]) {
                    [mTempStr appendString:mANameTags];
                    [mTempStr appendString:@"\n"];
                    [mANameTags release];
                    mANameTags = [[NSMutableString alloc] init];
                }
                
                [mTempStr appendString:@"<"];
                [mTempStr appendString:tagName];
                for (NSString *key in attrs) {
                    NSString *value = [attrs objectForKey:key];
                    [mTempStr appendString:@" "];
                    [mTempStr appendString:key];
                    [mTempStr appendString:@"=\""];
                    if ([tagName isEqualToString:@"a"] && [key isEqualToString:@"href"]) {
                        NSURL *parentURL = (mInnerParser? mInnerURL: mParentNode.URL);
                        NSURL *theURL = [NSURL URLWithString:value relativeToURL:parentURL];
                        [mTempStr appendString:[theURL absoluteString]];
                    } else if ([tagName isEqualToString:@"img"] && [key isEqualToString:@"src"]) {
                        NSURL *parentURL = (mInnerParser? mInnerURL: mParentNode.URL);
                        NSURL *theURL = [NSURL URLWithString:value relativeToURL:parentURL];
                        [mTempStr appendString:[theURL absoluteString]];
                    } else {
                        [mTempStr appendString:value];
                    }
                    [mTempStr appendString:@"\""];
                }
                [mTempStr appendString:@">"];
            }
        }
    }
}

- (void)htmlParser:(MIHTMLParser *)parser foundText:(NSString *)text
{
    if (mStatus == CBSAXMacClassParsingStatusSpecInfo) {
        [mTempStr appendString:text];
    }
    else if (mStatus == CBSAXMacClassParsingStatusCategory || mStatus == CBSAXMacClassParsingStatusMethodLevel) {
        [mTempStr appendString:text];
        if (mIsInHeader) {
            [mTempStr2 appendString:text];
        }
    }
}

- (void)htmlParser:(MIHTMLParser *)parser endTag:(NSString *)tagName
{
    if (mStatus == CBSAXMacClassParsingStatusSpecInfo) {
        if (![tagName isEqualToString:@"br"] && (![tagName isEqualToString:@"a"] || !mIsAName)) {
            [mTempStr appendFormat:@"</%@>", tagName];
        }
    }
    else if (mStatus == CBSAXMacClassParsingStatusCategory || mStatus == CBSAXMacClassParsingStatusMethodLevel) {
        if (![tagName isEqualToString:@"br"] && (![tagName isEqualToString:@"a"] || !mIsAName)) {
            [mTempStr appendFormat:@"</%@>", tagName];
        }
        if ([tagName isEqualToString:@"h2"] || [tagName isEqualToString:@"h3"]) {
            mIsInHeader = NO;
        }
    }
}

- (void)htmlParserEnd:(MIHTMLParser *)parser
{
    if (mTempStr) {
        [mTempStr release];
        mTempStr = nil;
    }
    if (mTempStr2) {
        [mTempStr2 release];
        mTempStr2 = nil;
    }
    if (mANameTags) {
        [mANameTags release];
        mANameTags = nil;
    }

    mParentNode.isLoaded = YES;    
}

@end

